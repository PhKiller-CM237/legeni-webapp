#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
target=${1:-staging}
case "$target" in staging|prod) ;; *) echo "Use staging or prod" >&2; exit 2;; esac
version=$(cat VERSION)
image="legeni-webapp:${version}-local"
state="$HOME/.local/state/legeni"
test -f "$state/vault-pass"
docker build --target test -t legeni-webapp:test .
docker build --build-arg APP_VERSION="$version" -t "$image" .
minikube image load "$image"
docker cp ./. jenkins:/tmp/legeni-work/
docker cp "$state/vault-pass" jenkins:/tmp/legeni-vault-pass
docker cp "$state/kubeconfig-jenkins.json" jenkins:/tmp/legeni-kubeconfig.json
docker exec -e KUBECONFIG=/tmp/legeni-kubeconfig.json -w /tmp/legeni-work/ansible jenkins  ansible-playbook deploy.yml --vault-password-file /tmp/legeni-vault-pass  -e "target_env=$target" -e "image_ref=$image" -e "app_version=$version"
