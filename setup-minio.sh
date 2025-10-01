#!/usr/bin/env bash

set -e

  helm upgrade --install --wait --timeout 35m --atomic --namespace minio --create-namespace \
    --repo https://operator.min.io minio-op operator --values - <<EOF
EOF

# Deploy object store
  helm upgrade --install --wait --timeout 35m --atomic --namespace minio \
    --repo https://operator.min.io minio tenant --values - <<EOF
tenant:
  # Pools (storage configuration)
  pools:
  - name: pool-0
    servers: 4
    labels:
      v1.min.io/tenant: myminio
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
      objectLock: false
    - name: results
      objectLock: false
  prometheusOperator: false
  env:
    - name: MINIO_PROMETHEUS_AUTH_TYPE
      value: public
  serviceMetadata:
    minioServiceAnnotations:
      prometheus.io/scrape: "true"
      prometheus.io/path: "/minio/v2/metrics/cluster"
      prometheus.io/port: "9000"
ingress:
  api:
    enabled: true
    ingressClassName: nginx
    host: minio.kind.cluster
    path: /
    pathType: Prefix
  console:
    enabled: true
    ingressClassName: nginx
    host: minio-console.kind.cluster
    path: /
    pathType: Prefix
extraResources:
  - |
    apiVersion: operator.victoriametrics.com/v1beta1
    kind: VMPodScrape
    metadata:
      name: minio-tenant
      namespace: minio
      labels:
        app.kubernetes.io/name: minio-tenant
    spec:
      namespaceSelector:
        matchNames:
          - minio
      selector:
        matchLabels:
          v1.min.io/tenant: myminio  # Adjust to your tenant name
      podMetricsEndpoints:
      - port: minio-port
        path: /minio/v2/metrics/cluster
        interval: 30s
        scheme: http
  - |
    apiVersion: operator.victoriametrics.com/v1beta1
    kind: VMPodScrape
    metadata:
      name: minio-resource
      namespace: minio
      labels:
        app.kubernetes.io/name: minio-tenant
    spec:
      namespaceSelector:
        matchNames:
          - minio
      selector:
        matchLabels:
          v1.min.io/tenant: myminio
      podMetricsEndpoints:
      - port: minio-port
        path: /minio/v2/metrics/resource
        interval: 30s
        scheme: http
  - |
    apiVersion: operator.victoriametrics.com/v1beta1
    kind: VMPodScrape
    metadata:
      name: minio-buckets
      namespace: minio
      labels:
        app.kubernetes.io/name: minio-tenant
    spec:
      namespaceSelector:
        matchNames:
          - minio
      selector:
        matchLabels:
          v1.min.io/tenant: myminio
      podMetricsEndpoints:
      - port: minio-port
        path: /minio/v2/metrics/bucket
        interval: 30s
        scheme: http
  - |
    apiVersion: operator.victoriametrics.com/v1beta1
    kind: VMPodScrape
    metadata:
      name: minio-nodes
      namespace: minio
      labels:
        app.kubernetes.io/name: minio-tenant
    spec:
      namespaceSelector:
        matchNames:
          - minio
      selector:
        matchLabels:
          v1.min.io/tenant: myminio
      podMetricsEndpoints:
      - port: minio-port
        path: /minio/v2/metrics/node
        interval: 30s
        scheme: http
EOF
