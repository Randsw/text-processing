#!/usr/bin/env bash

set -e

helm upgrade --install --wait --timeout 35m --atomic --namespace victoria-logs --create-namespace  \
  --repo https://victoriametrics.github.io/helm-charts vls victoria-logs-single --values - <<EOF
server:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - name: vl.kind.cluster
        path:
          - /
        port: http
  vmServiceScrape:
    enabled: true
vector:
  enabled: true
  tolerations:
    - key: node-role.kubernetes.io/control-plane
      operator: "Exists"
      effect: "NoSchedule"
dashboards:
  enabled: true
  labels:
    grafana_dashboard: "1"
EOF