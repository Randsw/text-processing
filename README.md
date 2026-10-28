# Kubernetes Data Pipeline Setup Guide

This guide helps you set up a complete data pipeline using Kubernetes with various monitoring, logging, and data processing components.

## Architecture Overview

* **Data Ingestion**
  * **Source:** Raw text files are stored in an **MinIO** (S3-compatible) bucket.
  * **Ingestion Tool:** The **Lenses S3 Source Connector** for Kafka Connect reads the files and streams them into a Kafka topic.

* **Stream Processing**
  * **Tool:** A custom application or consumer.
  * **Function:** Consumes the raw text data, simulates text processing (e.g., NLP, sentiment analysis, data enrichment), and produces the refined results to a new Kafka topic.

* **Data Sinking & Indexing**
  * **Destination:** Processed data is persisted in **Elasticsearch** for powerful search and analytics.
  * **Ingestion Tool:** The **Confluent Elasticsearch Sink Connector** for Kafka Connect streams the data from Kafka into Elasticsearch indices.

* **Observability & Monitoring**
  * **Metrics:** System, JVM, and custom application metrics are collected and visualized using **VictoriaMetrics**.
  * **Logging:** All application and infrastructure logs are centralized, stored, and analyzed using **VictoriaLogs**.

MinIO S3 → Kafka Connect S3 Source → Kafka → Microservice → Kafka Connect ElasticSearch Sink → ElasticSearch/Kibana
│
└── VictoriaMetrics (Monitoring) + VictoriaLogs (Logging) + Grafana (Visualization)

![text-processing overview](images/text-processing.png)

## Requirements

* docker
* kubectl
* kind cli
* helm

## Setup real-time pipeline

### 1. Kubernetes Cluster Setup

Run the following command to create a Kubernetes cluster with 1 control-plane node and 3 worker nodes:

```bash
./cluster-setup.sh
```

Components deployed:

* Ingress-nginx

* MetalLB

* 4 proxy image repositories in Docker containers

### 2. Deploy VictoriaMetrics kubernetes stack with Grafana and VictoriaLogs Datasource

Run `./setup-vm.sh`

Grafana Access:

* Login: admin

* Get Password: `kubectl get secret --namespace victoria-metrics vm-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

### 3. Ingress Nginx Setup

Run `setup-nginx.sh`

Recommended Dashboard:

* [Kubernetes Nginx Ingress Controller Dashboard (ID: 14314)](https://grafana.com/grafana/dashboards/14314-kubernetes-nginx-ingress-controller-nextgen-devops-nirvana/)

### 4. VictoriaLogs with Vector

Run `./setup-vl.sh`

### 5. MinIO Storage Setup

Run `./setup-minio.sh`

MinIO Console Access:

* URL: <http://minio-console.kind.cluster>

* Login: minio

* Password: minio123

Recommended Dashboards:

* [MinIO Bucket Dashboard (ID: 19237)](https://grafana.com/grafana/dashboards/19237-minio-bucket-dashboard/)

* [MinIO Cluster Dashboard (ID: 13502)](https://grafana.com/grafana/dashboards/13502-minio-dashboard/)

### 6. ElasticSearch and Kibana

Run `./setup-elastic.sh`

Kibana Access:

* URL: <http://kibana.kind.cluster>

* Login: elastic

* Get Password: `kubectl get secret elasticsearch-es-elastic-user -n elastic -o go-template='{{.data.elastic | base64decode }}'`

Recommended Dashboards:

* [ElasticSearch Overview (ID: 14191)](https://grafana.com/grafana/dashboards/14191-elasticsearch-overview/)

* [Kibana Monitoring (ID: 21420)](https://grafana.com/grafana/dashboards/21420-kibana-monitoring/)

## Kafka Ecosystem Setup

### 7. Kafka Cluster and Schema Registry

Deploy 3 Kafka brokers, 3 Kafka KRaft control nodes, and Schema Registry:

Run `./setup-strimzi.sh`

Components Deployed:

* Kafka Cluster in `kafka` namespace

* Schema Registry (accessible at `https://schema.kind.cluster`)

* KafkaUser: `confluent-schema-registry`

* KafkaTopic: `registry-schemas`

* **Warning** Schema Registry uses HTTP/2

The Schema Registry is deployed using the [`StrimziSchemaRegistry`](https://github.com/Randsw/schema-registry-operator-strimzi) custom resource (group `strimziregistryoperator.randsw.code/v1alpha1`). Its main `spec` fields are:

| Field | Description | Default |
|-------|-------------|---------|
| `listener` | Kafka listener name used to connect to the brokers | `tls` |
| `securityprotocol` | Kafka security protocol: `SSL`, `SASL_SSL`, `PLAINTEXT`, `SASL_PLAINTEXT` | `SSL` |
| `compatibilitylevel` | Schema compatibility level: `none`, `backward`, `backward_transitive`, `forward`, `forward_transitive`, `full`, `full_transitive` | `forward` |
| `securehttp` | Enable TLS on the Schema Registry REST API (required) | — |
| `clientauth` | Enable mutual TLS (mTLS) on the REST API; only valid when `securehttp` is `true` | `false` |
| `tlssecretname` | Name of a JKS-format secret holding the REST API TLS key/cert. Empty means the operator generates one signed by the Kafka cluster CA | `""` |
| `heapopts` | JVM heap options | `-Xms512M -Xmx512M` |
| `kafkastoretopic` | Name of the Kafka topic used to store schemas (must match the deployed `KafkaTopic`) | `registry-schemas` |
| `kafkastoretopicreplicationfactor` | Replication factor used when Schema Registry auto-creates the storage topic; unset keeps Confluent's built-in default | `3` (Confluent default) |
| `schemaregistrygroupid` | Kafka consumer group id used by Schema Registry (must match the `KafkaUser` ACL group prefix) | `schema-registry` |
| `mastereligibility` | Whether this instance is eligible to be elected Schema Registry master | `true` |
| `configuration` | Map of arbitrary Confluent Schema Registry properties in dotted form (e.g. `kafkastore.timeout.ms`); each key becomes a `SCHEMA_REGISTRY_*` env variable; operator-managed keys are ignored | — |
| `service` | Managed Service tuning: `type` (`ClusterIP`, `NodePort`, `LoadBalancer`), `port`, `nodeport`, `annotations`, `labels` | `ClusterIP`, port `80` (HTTP) / `443` (TLS) |
| `networkpolicy` | NetworkPolicy for Schema Registry pods: `enabled`, `allowcrossnamespaceingress` | `enabled: false` |
| `template` | Standard Kubernetes pod template (required) | — |

* `SSL` requires a `KafkaUser` named after the CR with `authentication.type: tls` (used by this setup).
* `SASL_SSL` and `SASL_PLAINTEXT` require a `KafkaUser` named after the CR with `authentication.type: scram-sha-512`.
* `PLAINTEXT` requires no user secret.

Example of the optional `configuration` and `service` fields:

```yaml
spec:
  # ...
  configuration:
    kafkastore.timeout.ms: "30000"
  service:
    type: ClusterIP
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "8085"
  networkpolicy:
    enabled: false
```

### 8. Kafka Connectors

#### S3 Source Connector

##### Build S3 Connector Image

* Build Docker image: `docker build -t <your-repo>/<your-image-name>:<your-tag> -f kafka-s3-source-connector/Dockerfile .`

For example: `docker build -t ttl.sh/randsw-strimzi-connect-s3-4.1.0:24h -f kafka-s3-source-connector/Dockerfile .`

* Push to your docker registry

##### Configure S3 Connector

1. Set your connector image in KafkaConnect spec

##### Deploy S3 Connector

```bash
./setup-kafka-connect-s3.sh
```

#### ElasticSearch Sink Connector

##### Build ElasticSearch Connector Image

* Build Docker image: `docker build -t <your-repo>/<your-image-name>:<your-tag> -f kafka-elasticsearch-sink-connector/Dockerfile .`

For example: `docker build -t ttl.sh/randsw-strimzi-connect-elastic-4.1.0:24h -f kafka-elasticsearch-sink-connectorDockerfile .`

* Push to your docker registry

##### Configure ElasticSearch Connector

1. Set your connector image in KafkaConnect spec

##### Deploy ElasticSearch Connector

```bash
./setup-kafka-connect-elastic.sh
```

#### 9. Example Microservice

Deploy a real-time data processing microservice that:

* Consumes raw data from Kafka topics

* Validates, enriches, filters, and transforms data

* Produces processed data to downstream topics

```bash
# Create Kafka user for microservice
kubectl apply -f consumer-producer/manifests/kafka-user.yaml

# Deploy microservice
kubectl apply -f consumer-producer/manifests/deployment.yaml
```

## Pipeline Testing

Generate test data to validate the entire pipeline:

```bash
cd minio-json-generator && go run main.go
```

Verify data appears in ElasticSearch indices.
![alt text](images/image.png)

| Component | Purpose | Access URL |
|-----------|---------|------------|
| Grafana | Monitoring & Visualization | <http://grafana.kind.cluster> |
| Kibana | ElasticSearch UI & Analytics | <http://kibana.kind.cluster> |
| MinIO Console | S3 Storage Management | <http://minio-console.kind.cluster> |
| Schema Registry | Kafka Schema Management | <https://schema.kind.cluster> |

## Security Notes

* All passwords are retrieved from Kubernetes secrets

* Schema Registry uses SSL/TLS with truststore authentication

* Kafka users are managed via Strimzi KafkaUser CRD

* Ingress controllers provide external access with proper routing

## Troubleshooting

* Verify all pods are running: kubectl get pods -A

* Check ingress routes: kubectl get ingress -A

* View logs for specific components using kubectl logs

* Validate Kafka connectivity and topic creation

* Confirm MinIO bucket creation and file uploads

This setup creates a scalable and resilient data processing system with comprehensive monitoring and logging capabilities.
