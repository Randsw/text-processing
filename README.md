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

Run `./setup-vms.sh`

## Get grafana password

Login - admin

Password:

`kubectl get secret --namespace victoria-metrics vm-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

## Deploy VictoriaLogs with Vector

Run `./setup-vl.sh`

## Deploy minio and minio tenant with 4 node pool

Run `./setup-minio.sh`

## Access minio UI and create bucket

Go to `http://minio-console.kind.cluster`

Login - minio

Password - minio123

Create bucket named `texts` using ui

## Deploy ElasticSearch and Kibana

Run `./setup-elastic.sh`

## Get kibana password

Login - elastic

Password:

`kubectl get secret elasticsearch-es-elastic-user -n elastic -o go-template='{{.data.elastic | base64decode }}'`

## Access kibana UI

Go to `http://kibana.kind.cluster`

## Deploy Kafka Cluster and Schema Registry

Run `./kafka-cluster.sh` to deploy 3 Kafka brocker and 3 Kafka KRaft control node and Schema Registry. Schema-registry required special user and topic to storage his data in Kafka so we deploy them too.

Schema-Registry deployed using [ssr-operator.](https://github.com/Randsw/schema-registry-operator-strimzi)

User deployed usind `KafkaUser` CR and named `confluent-schema-registry`.
Topic deployed usind `KafkaTopic` CR and named `registry-schemas`.

Mow we have running Kafka Cluser with Schema REgistry inside our `kafka` namespace.

You can access Schema registry at `http://schema.kind.cluster` :warning: Schema registry used HTTP/2





ElasticSearch dashboard - 14191
Kibana Dashboard - 21420

Minio bucket dashboard - 19237
Minio dashboard - 13502
MinIO Node Dashboard - 

Nginx Ingress Dashboard - 14314
Victoria logs  - 22084

Victoria logs logs - 22759