#!/usr/bin/env bash

set -e

  helm upgrade --install --wait --timeout 35m --atomic --namespace minio --create-namespace \
    --repo https://operator.min.io minio-op operator --values - <<EOF
EOF

# Deploy object store
  helm upgrade --install --wait --timeout 35m --atomic --namespace minio \
    --repo https://operator.min.io minio-op tenant --values - <<EOF
tenant:
  # Pools (storage configuration)
  pools:
  - name: pool-0
    servers: 4
    volumesPerServer: 4
    volumeClaimTemplate:
      metadata:
        name: data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 3Gi
        storageClassName: standart
  metrics:
    enabled: true
  certificate:
    requestAutoCert: false
  buckets:
    - name: texts
  prometheusOperator: true
  serviceMetadata:
    minioServiceAnnotations:
      prometheus.io/scrape: "true"
      prometheus.io/path: "/minio/v2/metrics/cluster"
      prometheus.io/port: "9000"
EOF
