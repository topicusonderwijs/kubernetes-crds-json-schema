package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

const yamlFactoryURL = "https://raw.githubusercontent.com/NetApp/trident/%s/cli/k8s_client/yaml_factory.go"

// requiredKinds lists the CRD spec.names.kind values that must be present.
// TridentOrchestrator and TridentConfigurator are excluded — fetched separately as YAML from
// helm/trident-operator/crds/ in build.sh.
var requiredKinds = []string{
	"TridentVersion",
	"TridentBackend",
	"TridentBackendConfig",
	"TridentStorageClass",
	"TridentVolume",
	"TridentVolumePublication",
	"TridentVolumeReference",
	"TridentNode",
	"TridentTransaction",
	"TridentSnapshot",
	"TridentGroupSnapshot",
	"TridentSnapshotInfo",
	"TridentMirrorRelationship",
	"TridentActionMirrorUpdate",
	"TridentActionSnapshotRestore",
	"TridentNodeRemediation",
	"TridentNodeRemediationTemplate",
	"TridentAutogrowPolicy",
	"TridentAutogrowRequestInternal",
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "usage: %s <tag> <output-dir>\n", os.Args[0])
		os.Exit(1)
	}
	tag, outDir := os.Args[1], os.Args[2]

	if err := os.MkdirAll(outDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "mkdir %s: %v\n", outDir, err)
		os.Exit(1)
	}

	src, err := fetchSource(tag)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	crds, err := extractCRDs(src)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	foundKinds := map[string]bool{}
	for name, entry := range crds {
		path := filepath.Join(outDir, name+".yaml")
		if err := os.WriteFile(path, []byte(entry.content), 0644); err != nil {
			fmt.Fprintf(os.Stderr, "write %s: %v\n", path, err)
			os.Exit(1)
		}
		foundKinds[entry.kind] = true
		fmt.Printf("extracted %s (%s)\n", name, entry.kind)
	}

	var missing []string
	for _, k := range requiredKinds {
		if !foundKinds[k] {
			missing = append(missing, k)
		}
	}
	if len(missing) > 0 {
		fmt.Fprintf(os.Stderr, "missing expected CRD kinds: %s\n", strings.Join(missing, ", "))
		os.Exit(1)
	}
	fmt.Printf("done: %d CRDs extracted\n", len(crds))
}

type crdEntry struct {
	content string
	kind    string
}

func fetchSource(tag string) ([]byte, error) {
	url := fmt.Sprintf(yamlFactoryURL, tag)
	resp, err := http.Get(url) //nolint:gosec
	if err != nil {
		return nil, fmt.Errorf("fetch %s: %w", url, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("fetch %s: HTTP %d", url, resp.StatusCode)
	}
	return io.ReadAll(resp.Body)
}

func extractCRDs(src []byte) (map[string]crdEntry, error) {
	fset := token.NewFileSet()
	f, err := parser.ParseFile(fset, "yaml_factory.go", src, 0)
	if err != nil {
		return nil, fmt.Errorf("parse Go source: %w", err)
	}

	crds := map[string]crdEntry{}
	ast.Inspect(f, func(n ast.Node) bool {
		lit, ok := n.(*ast.BasicLit)
		if !ok || lit.Kind != token.STRING || !strings.HasPrefix(lit.Value, "`") {
			return true
		}
		content := lit.Value[1 : len(lit.Value)-1]
		if !strings.Contains(content, "kind: CustomResourceDefinition") {
			return true
		}
		name := metadataName(content)
		if name == "" {
			fmt.Fprintf(os.Stderr, "warning: CRD with no metadata.name, skipping\n")
			return true
		}
		crds[name] = crdEntry{content: content, kind: specNamesKind(content)}
		return true
	})
	return crds, nil
}

func metadataName(yaml string) string {
	inMetadata := false
	for _, line := range strings.Split(yaml, "\n") {
		if line == "metadata:" {
			inMetadata = true
			continue
		}
		if inMetadata {
			if v, ok := strings.CutPrefix(line, "  name:"); ok {
				return strings.TrimSpace(v)
			}
			if line != "" && !strings.HasPrefix(line, " ") {
				break
			}
		}
	}
	return ""
}

func specNamesKind(yaml string) string {
	inNames := false
	for _, line := range strings.Split(yaml, "\n") {
		if line == "  names:" {
			inNames = true
			continue
		}
		if inNames {
			if strings.HasPrefix(line, "    kind: ") {
				return strings.TrimPrefix(line, "    kind: ")
			}
			if line != "" && !strings.HasPrefix(line, "    ") {
				break
			}
		}
	}
	return ""
}
