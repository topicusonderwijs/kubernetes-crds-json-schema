#!/bin/bash -xe

tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

OPENAPI2JSONSCHEMABIN="docker run -i -u $(id -u ${USER}):$(id -g ${USER}) -v ${tmp_dir}:/crds -v ${PWD}/standalone:/out/schemas openapi2jsonschema:latest"

get_latest_release() {
  curl -s "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

function get_crds_from_latest_release() {
  gh release download -R $1 -p $2 -D "$tmp_dir/$1"
  schemas+=( "/crds/$1/$2" )
}

declare -a schemas

# Add CRDs from latest GitHub release, including private repos
get_crds_from_latest_release "external-secrets/external-secrets" "external-secrets.yaml"
get_crds_from_latest_release "jetstack/cert-manager" "cert-manager.crds.yaml"
get_crds_from_latest_release "kyverno/kyverno" "kyverno.io_clusterpolicies.yaml"
get_crds_from_latest_release "kyverno/kyverno" "kyverno.io_policies.yaml"
get_crds_from_latest_release "topicuskeyhub/keyhub-vault-operator" "crds.yaml"

# Add CRDs from GitHub tag
schemas+=( "https://raw.githubusercontent.com/traefik/traefik/$(get_latest_release "traefik/traefik")/integration/fixtures/k8s/01-traefik-crd.yml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.coreos.com_podmonitors.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.coreos.com_probes.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.coreos.com_servicemonitors.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.grafana.com_grafanaagents.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.grafana.com_logsinstances.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.grafana.com_metricsinstances.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/agent/$(get_latest_release "grafana/agent")/operations/agent-static-operator/crds/monitoring.grafana.com_podlogs.yaml" )


$OPENAPI2JSONSCHEMABIN ${schemas[@]}
