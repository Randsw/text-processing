#!/usr/bin/env bash

set -e

cat << 'EOF' | kubectl apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: connect-metrics-s3
  namespace: kafka
  labels:
    app: strimzi
data:
  metrics-config.yml: |
    # Inspired by kafka-connect rules
    # https://github.com/prometheus/jmx_exporter/blob/master/example_configs/kafka-connect.yml
    # See https://github.com/prometheus/jmx_exporter for more info about JMX Prometheus Exporter metrics
    lowercaseOutputName: true
    lowercaseOutputLabelNames: true
    rules:
    #kafka.connect:type=app-info,client-id="{clientid}"
    #kafka.consumer:type=app-info,client-id="{clientid}"
    #kafka.producer:type=app-info,client-id="{clientid}"
    - pattern: 'kafka.(.+)<type=app-info, client-id=(.+)><>start-time-ms'
      name: kafka_$1_start_time_seconds
      labels:
        clientId: "$2"
      help: "Kafka $1 JMX metric start time seconds"
      type: GAUGE
      valueFactor: 0.001
    - pattern: 'kafka.(.+)<type=app-info, client-id=(.+)><>(commit-id|version): (.+)'
      name: kafka_$1_$3_info
      value: 1
      labels:
        clientId: "$2"
        $3: "$4"
      help: "Kafka $1 JMX metric info version and commit-id"
      type: UNTYPED

    #kafka.consumer:type=consumer-fetch-manager-metrics,client-id="{clientid}",topic="{topic}"", partition="{partition}"
    - pattern: kafka.consumer<type=consumer-fetch-manager-metrics, client-id=(.+), topic=(.+), partition=(.+)><>(.+-total)
      name: kafka_consumer_fetch_manager_$4
      labels:
        clientId: "$1"
        topic: "$2"
        partition: "$3"
      help: "Kafka Consumer JMX metric type consumer-fetch-manager-metrics"
      type: COUNTER
    - pattern: kafka.consumer<type=consumer-fetch-manager-metrics, client-id=(.+), topic=(.+), partition=(.+)><>(compression-rate|.+-avg|.+-replica|.+-lag|.+-lead)
      name: kafka_consumer_fetch_manager_$4
      labels:
        clientId: "$1"
        topic: "$2"
        partition: "$3"
      help: "Kafka Consumer JMX metric type consumer-fetch-manager-metrics"
      type: GAUGE

    #kafka.producer:type=producer-topic-metrics,client-id="{clientid}",topic="{topic}"
    - pattern: kafka.producer<type=producer-topic-metrics, client-id=(.+), topic=(.+)><>(.+-total)
      name: kafka_producer_topic_$3
      labels:
        clientId: "$1"
        topic: "$2"
      help: "Kafka Producer JMX metric type producer-topic-metrics"
      type: COUNTER
    - pattern: kafka.producer<type=producer-topic-metrics, client-id=(.+), topic=(.+)><>(compression-rate|.+-avg|.+rate)
      name: kafka_producer_topic_$3
      labels:
        clientId: "$1"
        topic: "$2"
      help: "Kafka Producer JMX metric type producer-topic-metrics"
      type: GAUGE

    #kafka.connect:type=connect-node-metrics,client-id="{clientid}",node-id="{nodeid}"
    #kafka.consumer:type=consumer-node-metrics,client-id=consumer-1,node-id="{nodeid}"
    - pattern: kafka.(.+)<type=(.+)-metrics, client-id=(.+), node-id=(.+)><>(.+-total)
      name: kafka_$2_$5
      labels:
        clientId: "$3"
        nodeId: "$4"
      help: "Kafka $1 JMX metric type $2"
      type: COUNTER
    - pattern: kafka.(.+)<type=(.+)-metrics, client-id=(.+), node-id=(.+)><>(.+-avg|.+-rate)
      name: kafka_$2_$5
      labels:
        clientId: "$3"
        nodeId: "$4"
      help: "Kafka $1 JMX metric type $2"
      type: GAUGE

    #kafka.connect:type=kafka-metrics-count,client-id="{clientid}"
    #kafka.consumer:type=consumer-fetch-manager-metrics,client-id="{clientid}"
    #kafka.consumer:type=consumer-coordinator-metrics,client-id="{clientid}"
    #kafka.consumer:type=consumer-metrics,client-id="{clientid}"
    - pattern: kafka.(.+)<type=(.+)-metrics, client-id=(.*)><>(.+-total)
      name: kafka_$2_$4
      labels:
        clientId: "$3"
      help: "Kafka $1 JMX metric type $2"
      type: COUNTER
    - pattern: kafka.(.+)<type=(.+)-metrics, client-id=(.*)><>(.+-avg|.+-bytes|.+-count|.+-ratio|.+-age|.+-flight|.+-threads|.+-connectors|.+-tasks|.+-ago)
      name: kafka_$2_$4
      labels:
        clientId: "$3"
      help: "Kafka $1 JMX metric type $2"
      type: GAUGE

    #kafka.connect:type=connector-metrics,connector="{connector}"
    - pattern: 'kafka.connect<type=connector-metrics, connector=(.+)><>(connector-class|connector-type|connector-version|status): (.+)'
      name: kafka_connect_connector_$2
      value: 1
      labels:
        connector: "$1"
        $2: "$3"
      help: "Kafka Connect $2 JMX metric type connector"
      type: GAUGE

    #kafka.connect:type=connector-task-metrics,connector="{connector}",task="{task}<> status"
    - pattern: 'kafka.connect<type=connector-task-metrics, connector=(.+), task=(.+)><>status: ([a-z-]+)'
      name: kafka_connect_connector_task_status
      value: 1
      labels:
        connector: "$1"
        task: "$2"
        status: "$3"
      help: "Kafka Connect JMX Connector task status"
      type: GAUGE

    #kafka.connect:type=task-error-metrics,connector="{connector}",task="{task}"
    #kafka.connect:type=source-task-metrics,connector="{connector}",task="{task}"
    #kafka.connect:type=sink-task-metrics,connector="{connector}",task="{task}"
    #kafka.connect:type=connector-task-metrics,connector="{connector}",task="{task}"
    - pattern: kafka.connect<type=(.+)-metrics, connector=(.+), task=(.+)><>(.+-total)
      name: kafka_connect_$1_$4
      labels:
        connector: "$2"
        task: "$3"
      help: "Kafka Connect JMX metric type $1"
      type: COUNTER
    - pattern: kafka.connect<type=(.+)-metrics, connector=(.+), task=(.+)><>(.+-count|.+-ms|.+-ratio|.+-seq-no|.+-rate|.+-max|.+-avg|.+-failures|.+-requests|.+-timestamp|.+-logged|.+-errors|.+-retries|.+-skipped)
      name: kafka_connect_$1_$4
      labels:
        connector: "$2"
        task: "$3"
      help: "Kafka Connect JMX metric type $1"
      type: GAUGE

    #kafka.connect:type=connect-worker-metrics,connector="{connector}"
    - pattern: kafka.connect<type=connect-worker-metrics, connector=(.+)><>([a-z-]+)
      name: kafka_connect_worker_$2
      labels:
        connector: "$1"
      help: "Kafka Connect JMX metric $1"
      type: GAUGE

    #kafka.connect:type=connect-worker-metrics
    - pattern: kafka.connect<type=connect-worker-metrics><>([a-z-]+-total)
      name: kafka_connect_worker_$1
      help: "Kafka Connect JMX metric worker"
      type: COUNTER
    - pattern: kafka.connect<type=connect-worker-metrics><>([a-z-]+)
      name: kafka_connect_worker_$1
      help: "Kafka Connect JMX metric worker"
      type: GAUGE

    #kafka.connect:type=connect-worker-rebalance-metrics,leader-name|connect-protocol
    - pattern: 'kafka.connect<type=connect-worker-rebalance-metrics><>(leader-name|connect-protocol): (.+)'
      name: kafka_connect_worker_rebalance_$1
      value: 1
      labels:
          $1: "$2"
      help: "Kafka Connect $2 JMX metric type worker rebalance"
      type: UNTYPED

    #kafka.connect:type=connect-worker-rebalance-metrics
    - pattern: kafka.connect<type=connect-worker-rebalance-metrics><>([a-z-]+-total)
      name: kafka_connect_worker_rebalance_$1
      help: "Kafka Connect JMX metric rebalance information"
      type: COUNTER
    - pattern: kafka.connect<type=connect-worker-rebalance-metrics><>([a-z-]+)
      name: kafka_connect_worker_rebalance_$1
      help: "Kafka Connect JMX metric rebalance information"
      type: GAUGE

    #kafka.connect:type=connect-coordinator-metrics
    - pattern: kafka.connect<type=connect-coordinator-metrics><>(assigned-connectors|assigned-tasks)
      name: kafka_connect_coordinator_$1
      help: "Kafka Connect JMX metric assignment information"
      type: GAUGE
EOF

cat << EOF | kubectl apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: extract-topic
  namespace: kafka
  labels:
    strimzi.io/cluster: kafka-cluster
spec:
  partitions: 3
  replicas: 3
  config:
    # http://kafka.apache.org/documentation/#topicconfigs
    cleanup.policy: delete
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: from-s3-user
  namespace: kafka
  labels:
    strimzi.io/cluster: kafka-cluster
spec:
  authentication:
    type: tls
  authorization:
    # Official docs on authorizations required for the Schema Registry:
    # https://docs.confluent.io/current/schema-registry/security/index.html#authorizing-access-to-the-schemas-topic
    type: simple
    acls:
    - resource:
        type: group
        name: s3-connect-cluster
      operations:
        - Read
        - Describe
        - Write
        - Create
    - resource:
        type: group
        name: connect-s3-source-connector
      operations:
        - Read
        - Describe
        - Write
        - Create
    - resource:
        type: topic
        name: s3-connect-cluster-configs
      operations:
        - Read
        - Describe
        - Write
        - Create
    - resource:
        type: topic
        name: s3-connect-cluster-status
      operations:
        - Read
        - Describe
        - Write
        - Create
    - resource:
        type: topic
        name: s3-connect-cluster-offsets
      operations:
        - Read
        - Describe
        - Write
        - Create
    - resource:
        type: topic
        name: extract-topic
      operations:
        - Write
        - Describe
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnect
metadata:
  name: connect-s3
  namespace: kafka
  labels:
    strimzi.io/cluster: kafka-cluster
  annotations:
    strimzi.io/use-connector-resources: "true"
spec:
  version: 4.1.0
  replicas: 1
  bootstrapServers: kafka-cluster-kafka-bootstrap:9093
  image: ttl.sh/randsw-strimzi-connect-example-4.1.1-s3:24h
  template:
    pod:
      volumes:
        - name: tls
          secret:
            defaultMode: 420
            secretName: confluent-schema-registry-jks
    connectContainer:
      volumeMounts:
      - mountPath: /mnt/schemaregistry
        name: tls
        readOnly: true
  tls:
    trustedCertificates:
      - secretName: kafka-cluster-cluster-ca-cert
        pattern: "*.crt"
  authentication:
    type: tls
    certificateAndKey:
      secretName: from-s3-user
      certificate: user.crt
      key: user.key
  config:
    group.id: s3-connect-cluster
    offset.storage.topic: s3-connect-cluster-offsets
    config.storage.topic: s3-connect-cluster-configs
    status.storage.topic: s3-connect-cluster-status
    config.storage.replication.factor: 3
    offset.storage.replication.factor: 3
    status.storage.replication.factor: 3
    value.converter: io.confluent.connect.json.JsonSchemaConverter
    value.converter.schema.registry.url: "https://confluent-schema-registry"
    value.converter.schema.registry.ssl.truststore.location: /mnt/schemaregistry/truststore.jks
    value.converter.schema.registry.ssl.truststore.password: "JTU6rHCgVP3Ply63dsxRcpGs"
  metricsConfig:
    type: jmxPrometheusExporter
    valueFrom:
      configMapKeyRef:
        name: connect-metrics-s3
        key: metrics-config.yml
EOF

cat << 'EOF' | kubectl apply -f -
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnector
metadata:
  name: s3-source-connector
  namespace: kafka
  labels:
    strimzi.io/cluster: connect-s3
spec:
  class: io.lenses.streamreactor.connect.aws.s3.source.S3SourceConnector
  tasksMax: 1
  # https://docs.confluent.io/kafka-connect-elasticsearch/current/configuration_options.html
  config:
    connect.s3.kcql: |
      INSERT INTO extract-topic
      SELECT * 
      FROM texts:kafka
      STOREAS `JSON`
    name: s3-source
    errors.log.enable: true
    connect.s3.custom.endpoint: http://minio.minio.svc.cluster.local
    connect.s3.aws.region: us-east-1
    connect.s3.aws.secret.key: minio123
    connect.s3.aws.access.key: minio
    connect.s3.aws.auth.mode: Credentials
    connect.s3.ordering.type: LastModified
    connect.s3.source.partition.extractor.regex: none
    # Important: Force path-style access and handle bucket naming
    connect.s3.vhost.bucket: "true"
EOF