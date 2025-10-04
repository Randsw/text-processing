#!/usr/bin/env bash

set -e

# Deploy ElasticSearch CLuster

  helm upgrade --install --wait --timeout 35m --atomic --namespace elastic --create-namespace \
    --repo https://helm.elastic.co eck-operator eck-operator --values - <<EOF
replicaCount: 2
config:
   metrics:
     port: "9200"
podMonitor:
  enabled: true
EOF

  helm upgrade --install --wait --timeout 35m --atomic --namespace elastic --create-namespace \
    --repo https://helm.elastic.co eck-stack eck-stack --values - <<EOF
eck-elasticsearch:
  enabled: true
  ingress:
    enabled: true
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - host: elastic.kind.cluster
        path: /
eck-kibana:
  enabled: true
  ingress:
    enabled: true
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - host: kibana.kind.cluster
EOF