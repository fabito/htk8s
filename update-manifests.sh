#!/bin/sh -x

SRCROOT="$( CDPATH='' cd -- "$(dirname "$0")" && pwd -P )"
AUTOGENMSG="# This is an auto-generated file. DO NOT EDIT"

echo "${AUTOGENMSG}" > "${SRCROOT}/install_x86_64.yaml"
kustomize build "${SRCROOT}/overlays/x86" >> "${SRCROOT}/install_x86_64.yaml"

echo "${AUTOGENMSG}" > "${SRCROOT}/install_armhf.yaml"
kustomize build "${SRCROOT}/overlays/armhf" >> "${SRCROOT}/install_armhf.yaml"

echo "${AUTOGENMSG}" > "${SRCROOT}/install_argocd.yaml"
kustomize build "${SRCROOT}/argocd" >> "${SRCROOT}/install_argocd.yaml"
