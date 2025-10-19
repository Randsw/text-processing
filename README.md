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