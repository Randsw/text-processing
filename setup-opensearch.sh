#!/usr/bin/env bash

set -e

# Deploy OpenSearch CLuster

  helm upgrade --install --wait --timeout 35m --atomic --namespace opensearch --create-namespace \
    --repo https://opensearch-project.github.io/helm-charts/ opensearch opensearch --values - <<EOF
extraEnvs:
  - name: OPENSEARCH_INITIAL_ADMIN_PASSWORD
    value: password
EOF