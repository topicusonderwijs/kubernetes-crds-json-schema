#!/bin/bash -xe

tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

OPENAPI2JSONSCHEMABIN="docker run -i -u $(id -u ${USER}):$(id -g ${USER}) -v ${tmp_dir}:/crds -v ${PWD}/standalone:/out/schemas openapi2jsonschema:latest"

# Upstreams sometimes tag a pre-release (e.g. v1.19.2-rc.2) without marking it as such, or even mark it as
# 'latest'. Treat tags with a pre-release suffix as pre-releases regardless of the GitHub flags.
PRERELEASE_TAG_RE='-(rc|alpha|beta|pre|preview|dev|snapshot)([.-]?[0-9]+)*$'

get_latest_release() {
  if [[ "$2" != "" ]]; then
    echo $(gh release list -R $1 --exclude-drafts --exclude-pre-releases --jq '.[]|select(.name|startswith("'$2'"))|select(.tagName|test("'$PRERELEASE_TAG_RE'";"i")|not)' --json name,tagName -L 100 | jq -rn '. |= [inputs] | first | .tagName')
    return
  fi
  # Prefer the release marked 'latest', unless it is a pre-release; then take the newest stable release.
  gh release list -R $1 --exclude-drafts --exclude-pre-releases --jq '.[]|select(.tagName|test("'$PRERELEASE_TAG_RE'";"i")|not)' --json name,tagName,isLatest -L 100 \
    | jq -rn '[inputs] | (map(select(.isLatest)) + .) | first | .tagName'
}

function get_crds_from_latest_release() {
  # Fetch 'latest' release
  tag=$(gh release list -R $1 --exclude-drafts --exclude-pre-releases --jq '.[]|select(.name|startswith("helm-chart")|not)|select(.tagName|test("'$PRERELEASE_TAG_RE'";"i")|not)' --json name,tagName -L 100 | jq -rn '. |= [inputs] | first | .tagName')
  version=${tag#v}
  # The asset pattern may be a glob (e.g. 'kyverno.io_*.yaml') matching multiple assets
  pattern=${2/__version__/$version}
  gh release download $tag -R $1 -p "$pattern" -D "$tmp_dir/$1"
  for f in "$tmp_dir/$1/"$pattern; do
    schemas+=( "/crds/$1/$(basename "$f")" )
  done
}

declare -a schemas

# Add CRDs from latest GitHub release, including private repos
get_crds_from_latest_release "argoproj/argo-events" "install.yaml"
get_crds_from_latest_release "argoproj/argo-workflows" "install.yaml"
get_crds_from_latest_release "cloudnative-pg/cloudnative-pg" "cnpg-__version__.yaml"
get_crds_from_latest_release "external-secrets/external-secrets" "external-secrets.yaml"
get_crds_from_latest_release "jetstack/cert-manager" "cert-manager.crds.yaml"
get_crds_from_latest_release "kyverno/kyverno" "kyverno.io_*.yaml"
get_crds_from_latest_release "kyverno/kyverno" "policies.kyverno.io_*.yaml"
get_crds_from_latest_release "kyverno/kyverno" "reports.kyverno.io_*.yaml"
get_crds_from_latest_release "kyverno/kyverno" "wgpolicyk8s.io_*.yaml"
get_crds_from_latest_release "strimzi/strimzi-kafka-operator" "strimzi-crds-__version__.yaml"
get_crds_from_latest_release "topicusonderwijs/nats-account-operator" "crds.yaml"
get_crds_from_latest_release "topicusonderwijs/nats-jetstream-operator" "crds.yaml"

# Add CRDs from GitHub tag
schemas+=( "https://raw.githubusercontent.com/grafana/alloy/$(get_latest_release "grafana/alloy")/operations/helm/charts/alloy/charts/crds/crds/monitoring.grafana.com_podlogs.yaml" )
schemas+=( "https://raw.githubusercontent.com/prometheus-community/helm-charts/$(get_latest_release "prometheus-community/helm-charts" "kube-prometheus-stack")/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml" )
schemas+=( "https://raw.githubusercontent.com/prometheus-community/helm-charts/$(get_latest_release "prometheus-community/helm-charts" "kube-prometheus-stack")/charts/kube-prometheus-stack/charts/crds/crds/crd-probes.yaml" )
schemas+=( "https://raw.githubusercontent.com/prometheus-community/helm-charts/$(get_latest_release "prometheus-community/helm-charts" "kube-prometheus-stack")/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml" )
schemas+=( "https://raw.githubusercontent.com/OT-CONTAINER-KIT/redis-operator/$(get_latest_release "OT-CONTAINER-KIT/redis-operator")/charts/redis-operator/crds/crds.yaml" )
schemas+=( "https://raw.githubusercontent.com/traefik/traefik/$(get_latest_release "traefik/traefik")/integration/fixtures/k8s/01-traefik-crd.yml" )
trident_tag=$(get_latest_release "NetApp/trident")
schemas+=( "https://raw.githubusercontent.com/NetApp/trident/$trident_tag/helm/trident-operator/crds/tridentorchestrators.yaml" )
schemas+=( "https://raw.githubusercontent.com/NetApp/trident/$trident_tag/helm/trident-operator/crds/tridentconfigurators.yaml" )
trident_resource_dir="$tmp_dir/NetApp/trident/resource-crds"
(cd ./scripts && go run . "$trident_tag" "$trident_resource_dir")
for f in "$trident_resource_dir/"*.yaml; do
  schemas+=( "/crds/NetApp/trident/resource-crds/$(basename "$f")" )
done

$OPENAPI2JSONSCHEMABIN ${schemas[@]}
