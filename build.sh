#!/bin/bash -xe

OPENAPI2JSONSCHEMABIN="docker run -i -u $(id -u ${USER}):$(id -g ${USER}) -v ${PWD}/standalone:/out/schemas openapi2jsonschema:latest"

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

CERTMANAGER_VERSION=$(get_latest_release "jetstack/cert-manager")
TRAEFIK_VERSION=$(get_latest_release "traefik/traefik")

SCHEMAS=(
  https://github.com/jetstack/cert-manager/releases/download/${CERTMANAGER_VERSION}/cert-manager.crds.yaml
  https://raw.githubusercontent.com/traefik/traefik/${TRAEFIK_VERSION}/integration/fixtures/k8s/01-traefik-crd.yml
)

$OPENAPI2JSONSCHEMABIN ${SCHEMAS[@]}
