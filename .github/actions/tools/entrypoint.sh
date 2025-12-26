#!/bin/bash

set -eu

YQ_VERSION="${YQ_VERSION:-"3.4.1"}"
KUSTOMIZE_VERSION="3.9.2"
KUBEVAL_VERSION="0.15.0"

INSTALL_DIR="$GITHUB_WORKSPACE/bin"
mkdir -p "$INSTALL_DIR"

curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o "$INSTALL_DIR/yq"
chmod +x "$INSTALL_DIR/yq"

kustomize_url="https://github.com/kubernetes-sigs/kustomize/releases/download"
curl -sL "${kustomize_url}/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | \
  tar xz -C "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/kustomize"

curl -sL "https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" | \
  tar xz -C "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/kubeval"

echo "$INSTALL_DIR" >> "$GITHUB_PATH"
echo "$RUNNER_WORKSPACE/$(basename $GITHUB_REPOSITORY)/bin" >> "$GITHUB_PATH"
