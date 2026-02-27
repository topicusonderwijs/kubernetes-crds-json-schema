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

## More info
- [Kubernetes JSON Schemas](https://github.com/yannh/kubernetes-json-schema)
- [Kubeconform](https://github.com/yannh/kubeconform)
