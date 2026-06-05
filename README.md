# JSON Schemas for Kubernetes Custom Resources

## Supported CRDs
- Argo Events
- Argo Workflows
- cert-manager
- CloudNativePG
- External Secrets Operator
- Grafana Alloy
- Kafka Operator (by Strimzi)
- Kyverno (ClusterPolicy/Policy)
- Prometheus Operator (PodMonitor/ServiceMonitor)
- Redis Operator (by Opstree Solutions)
- Traefik

## Usage with Kubeconform
```
kubeconform -schema-location default -schema-location "https://raw.githubusercontent.com/topicusonderwijs/kubernetes-crds-json-schema/main/standalone/{{ .ResourceKind }}{{ .KindSuffix }}.json"
```

## Local Development

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) — runs the `openapi2jsonschema` converter
- [Go](https://go.dev/dl/) — used by scripts to fetch Trident resource CRDs
- [GitHub CLI (`gh`)](https://cli.github.com/) — fetches CRD assets from GitHub releases (must be authenticated)
- `make`, `bash`

### Build and run

Build the Docker image used by the schema generation:

```sh
docker build . --file Dockerfile --tag openapi2jsonschema:latest
```

Then generate the schemas:

```sh
make gen
```

This runs `build.sh`, which uses `gh` to download CRD manifests from the latest GitHub releases, `go` to fetch Trident resource CRDs, and the Docker image to convert everything to JSON Schema under `standalone/`.

## More info
- [Kubernetes JSON Schemas](https://github.com/yannh/kubernetes-json-schema)
- [Kubeconform](https://github.com/yannh/kubeconform)
