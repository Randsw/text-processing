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
    --repo https://helm.elastic.co eck-stack eck-stack --values - <<'EOF'
eck-elasticsearch:
  enabled: true
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
      xpack.security.authc:
        anonymous:
          username: anonymous_user
          roles: remote_monitoring_collector
          authz_exception: true
    podTemplate:
      spec:
        containers:
        - name: elasticsearch-exporter
          image: quay.io/prometheuscommunity/elasticsearch-exporter:v1.9.0
          ports:
          - containerPort: 9114
            name: metrics
          env:
          - name: ES_URI
            value: "http://elasticsearch-es-http:9200"
          - name: ES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: elasticsearch-es-elastic-user
                key: elastic
          - name: ES_USERNAME
            value: "elastic"
          args:
          - --es.uri=$(ES_URI)
          - --es.all
          - --web.listen-address=:9114
          - --web.telemetry-path=/metrics
          - --es.ssl-skip-verify
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
          securityContext:
            runAsUser: 1000  # Match Elasticsearch user ID
            runAsGroup: 1000
            allowPrivilegeEscalation: false
  version: 8.12.0
  monitoring:
    metrics:
      elasticsearchRefs:
        - name: elasticsearch
          namespace: elastic
  http:
    tls:
      selfSignedCertificate:
        disabled: true
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
  config:
    monitoring.kibana.collection.enabled: true
    monitoring.ui.enabled: true
    status.allowAnonymous: true
  podTemplate:
    spec:
      containers:
        - name: kibana-prometheus-exporter
          image: chamilad/kibana-prometheus-exporter:v8.7.x.2
          args:
          - -kibana.uri=https://localhost:5601
          - -kibana.skip-tls=true
          - -wait=true
          securityContext:
            privileged: false
            allowPrivilegeEscalation: false
          resources:
            limits:
              memory: 100Mi
              cpu: 100m
            requests:
              cpu: 10m
              memory: 50Mi
          ports:
            - containerPort: 9684
              name: metrics
          livenessProbe:
            httpGet:
              path: /healthz
              port: 9684
            initialDelaySeconds: 10
            periodSeconds: 10
  version: 8.12.0
  monitoring:
    metrics:
      elasticsearchRefs:
        - name: elasticsearch
          namespace: elastic
  ingress:
    enabled: true
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - host: kibana.kind.cluster
EOF

cat << EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: elasticsearch-metrics
  namespace: elastic
spec:
  selector:
    matchLabels:
      elasticsearch.k8s.elastic.co/cluster-name: elasticsearch # Directly select ES pods
  podMetricsEndpoints:
  - port: metrics # The name of the port exposed by the ES pod (ECK sets this automatically)
    path: /metrics
    interval: 30s
  namespaceSelector:
    matchNames:
    - elastic
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: kibana-metrics
  namespace: elastic
spec:
  selector:
    matchLabels:
      kibana.k8s.elastic.co/name: eck-stack-eck-kibana
  podMetricsEndpoints:
  - port: metrics
    path: /metrics
    interval: 30s
  namespaceSelector:
    matchNames:
    - elastic
EOF