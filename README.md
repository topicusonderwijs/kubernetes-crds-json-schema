# JSON Schemas for Kubernetes Custom Resources

## Supported CRDs
- cert-manager
- keyhub-vault-operator (tool not publicly available)
- Operator Lifecycle Manager (OLM)
- traefik

## Usage with Kubeconform
```
kubeconform -schema-location default -schema-location "https://raw.githubusercontent.com/topicusonderwijs/kubernetes-crds-json-schema/main/standalone/{{ .ResourceKind }}{{ .KindSuffix }}.json"
```

## More info
- [Kubernetes JSON Schemas](https://github.com/yannh/kubernetes-json-schema)
- [Kubeconform](https://github.com/yannh/kubeconform)
