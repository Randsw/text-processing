# Real-Time Text Processing Pipeline

This project demonstrates a real-time data pipeline for processing text documents, built with a Kafka-centric architecture and full observability.

## Architecture Overview

* **Data Ingestion**
  * **Source:** Raw text files are stored in an **MinIO** (S3-compatible) bucket.
  * **Ingestion Tool:** The **Lenses S3 Source Connector** for Kafka Connect reads the files and streams them into a Kafka topic.

* **Stream Processing**
  * **Tool:** A custom Kafka Streams application or consumer.
  * **Function:** Consumes the raw text data, simulates text processing (e.g., NLP, sentiment analysis, data enrichment), and produces the refined results to a new Kafka topic.

* **Data Sinking & Indexing**
  * **Destination:** Processed data is persisted in **Elasticsearch** for powerful search and analytics.
  * **Ingestion Tool:** The **Confluent Elasticsearch Sink Connector** for Kafka Connect streams the data from Kafka into Elasticsearch indices.

* **Observability & Monitoring**
  * **Metrics:** System, JVM, and custom application metrics are collected and visualized using **VictoriaMetrics**.
  * **Logging:** All application and infrastructure logs are centralized, stored, and analyzed using **VictoriaLogs**.

## Requirements

* docker
* kubectl
* kind cli
* helm

## Setup kubernetes cluster

Run `./cluster-setup.sh` and you got 1 control-plane nodes and 3 worker nodes kubernetes cluster with installed ingress-nginx, metallb and 4 proxy image repository in docker containers in one network

## Deploy VictoriaMetrics kubernetes stack with Grafana and VictoriaLogs Datasource

Run `./setup-vm.sh`

## Get grafana password

Login - admin

Password:

`kubectl get secret --namespace victoria-metrics vm-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

## Setup Ingress Nginx

Run `setup-nginx.sh`

### Deploy ingress dashboard

<https://grafana.com/grafana/dashboards/14314-kubernetes-nginx-ingress-controller-nextgen-devops-nirvana/> - for Ingress Metrics

## Deploy VictoriaLogs with Vector

Run `./setup-vl.sh`

## Deploy minio and minio tenant with 4 node pool

Run `./setup-minio.sh`

### Deploy Minio dashboards

<https://grafana.com/grafana/dashboards/19237-minio-bucket-dashboard/> - for MinIo buckets metrics

<https://grafana.com/grafana/dashboards/13502-minio-dashboard/> - for MinIo cluster metrics

## Access minio UI and create bucket

Go to `http://minio-console.kind.cluster`

Login - minio

Password - minio123

## Deploy ElasticSearch and Kibana

Run `./setup-elastic.sh`

## Get kibana password

Login - elastic

Password:

`kubectl get secret elasticsearch-es-elastic-user -n elastic -o go-template='{{.data.elastic | base64decode }}'`

## Access kibana UI

Go to `http://kibana.kind.cluster`

### Deploy ElasticSearch and Kibana dashboards

<https://grafana.com/grafana/dashboards/14191-elasticsearch-overview/> - for ElasticSearch metrics

<https://grafana.com/grafana/dashboards/21420-kibana-monitoring/> - for Kibana metrics

## Deploy Kafka Cluster and Schema Registry

Run `./kafka-cluster.sh` to deploy 3 Kafka brocker and 3 Kafka KRaft control node and Schema Registry. Schema-registry required special user and topic to storage his data in Kafka so we deploy them too.

Schema-Registry deployed using [ssr-operator.](https://github.com/Randsw/schema-registry-operator-strimzi)

User deployed usind `KafkaUser` CR and named `confluent-schema-registry`.
Topic deployed usind `KafkaTopic` CR and named `registry-schemas`.

Mow we have running Kafka Cluser with Schema Registry inside our `kafka` namespace.

You can access Schema registry at `http://schema.kind.cluster` :warning: Schema registry used HTTP/2

## Deploy Kafka Connects

### Deploy s3 source connector

#### Build source connector docker container

Download confluentinc-kafka-connect-json-schema-converter from [Confluent Hub](https://www.confluent.io/hub/confluentinc/kafka-connect-json-schema-converter)

Build docker image using `Dockerfile-s3` and store it in docker repository.

`docker build -t <your-repo>/<your-image-name>:<your-tag> -f Dockerfile-s3 .`

For example:

`docker build -t ttl.sh/randsw-strimzi-connect-s3-4.1.0:24h -f Dockerfile-s3 .`

Then pull your image to repository.

#### Create s3 source connector configuration

In file `setup-kafka-connect-s3.sh` enter credential for Minio:

`connect.s3.aws.access.key: minio`

`connect.s3.aws.secret.key: minio123`

Also enter credential for schema registry truststore:

Get password - `kubectl get secret confluent-schema-registry-jks -n kafka -o go-template='{{.data.truststore_password | base64decode }}'`

Set password in config: `value.converter.schema.registry.ssl.truststore.password: "<your-password>"`

Set your connector image name in `KafkaConnect` in section `spec.image`

#### Run source kafka connector

Run `./setup-kafka-connect-s3.sh`

### Deploy Elastic search connector

#### Build sin connector docker container

Download confluentinc-kafka-connect-json-schema-converter from [Confluent Hub](https://www.confluent.io/hub/confluentinc/kafka-connect-json-schema-converter)

Build docker image using `Dockerfile` and store it in docker repository.

`docker build -t <your-repo>/<your-image-name>:<your-tag> -f Dockerfile .`

For example:

`docker build -t ttl.sh/randsw-strimzi-connect-elastic-4.1.0:24h -f Dockerfile .`

Then pull your image to repository.

#### Create elasticsearch sink configuration

In file `setup-kafka-connect-elastic.sh` enter credential for ElasticSearch:

`connection.username: "elastic"`
`connection.password: "<your-kibana-password>"`

Also enter credential for schema registry truststore:

Get password - `kubectl get secret confluent-schema-registry-jks -n kafka -o go-template='{{.data.truststore_password | base64decode }}'`

Set password in config: `value.converter.schema.registry.ssl.truststore.password: "<your-password>"`

Set your connector image name in `KafkaConnect` in section `spec.image`

#### Run sink kafka connector

Run `./setup-kafka-connect-elastic.sh`

### Deploy example microservice

This microservice acts as a real-time data processing layer within a Kafka-centric data pipeline. It consumes raw data events from a topic populated by a Kafka Connect S3 Source Connector. The service is responsible for validating, enriching, filtering, and transforming this data into a structured format suitable for search and analytics. The processed records are then produced to a downstream topic, from which a Kafka Connect Elasticsearch Sink Connector ingests them into the target Elasticsearch indices.

First, create user for microservice:

`kubectl apply -f consumer-producer/manifests/kafka-user.yaml`

Then deploy microservice:

`kubectl apply -f consumer-producer/manifests/deployment.yaml`

### Test pipeline

Start adding data to s3:

`cd minio-json-generator && go run main.go`

Check data appear at result-topci indices:

![alt text](images/image.png)