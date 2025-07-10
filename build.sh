#!/bin/bash -xe

tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

OPENAPI2JSONSCHEMABIN="docker run -i -u $(id -u ${USER}):$(id -g ${USER}) -v ${tmp_dir}:/crds -v ${PWD}/standalone:/out/schemas openapi2jsonschema:latest"

get_latest_release() {
  if [[ "$2" != "" ]]; then
    echo $(gh release list -R $1 --exclude-drafts --exclude-pre-releases --jq '.[]|select(.name|startswith("'$2'"))' --json name,tagName -L 100 | jq -rn '. |= [inputs] | first | .tagName')
    return
  fi
  gh release list -R $1 --exclude-drafts --exclude-pre-releases --jq '.[] | select(.isLatest)|.tagName' --json name,tagName,isLatest
}

function get_crds_from_latest_release() {
  # Fetch 'latest' release
  tag=$(gh release list -R $1 --jq '.[]|select(.name|startswith("helm-chart")|not)' --json name,tagName | jq -rn '. |= [inputs] | first | .tagName')
  gh release download $tag -R $1 -p $2 -D "$tmp_dir/$1"
  schemas+=( "/crds/$1/$2" )
}

declare -a schemas

# Add CRDs from latest GitHub release, including private repos
get_crds_from_latest_release "external-secrets/external-secrets" "external-secrets.yaml"
get_crds_from_latest_release "jetstack/cert-manager" "cert-manager.crds.yaml"
get_crds_from_latest_release "kyverno/kyverno" "kyverno.io_clusterpolicies.yaml"
get_crds_from_latest_release "kyverno/kyverno" "kyverno.io_policies.yaml"
get_crds_from_latest_release "prometheus-operator/prometheus-operator" "stripped-down-crds.yaml"
get_crds_from_latest_release "topicusonderwijs/nats-account-operator" "crds.yaml"
get_crds_from_latest_release "topicusonderwijs/nats-jetstream-operator" "crds.yaml"

# Add CRDs from GitHub tag
schemas+=( "https://raw.githubusercontent.com/traefik/traefik/$(get_latest_release "traefik/traefik")/integration/fixtures/k8s/01-traefik-crd.yml" )
schemas+=( "https://raw.githubusercontent.com/prometheus-community/helm-charts/$(get_latest_release "prometheus-community/helm-charts" "kube-prometheus-stack")/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml" )
schemas+=( "https://raw.githubusercontent.com/grafana/alloy/$(get_latest_release "grafana/alloy")/operations/helm/charts/alloy/charts/crds/crds/monitoring.grafana.com_podlogs.yaml" )

$OPENAPI2JSONSCHEMABIN ${schemas[@]}
