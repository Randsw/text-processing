FROM quay.io/strimzi/kafka:latest-kafka-4.1.0

USER root:root

# Install required packages
RUN microdnf update -y && \
    microdnf install -y unzip wget && \
    microdnf clean all

# Create plugin directory
RUN mkdir -p /opt/kafka/plugins/elasticsearch-connector && \
    chown -R 1001:0 /opt/kafka/plugins

USER 1001

# Download Confluent JSON converter from Confluent Hub
COPY ./confluentinc-kafka-connect-json-schema-converter-8.1.0.zip /opt/kafka/plugins
RUN cd /opt/kafka/plugins && unzip -q confluentinc-kafka-connect-json-schema-converter-8.1.0.zip && \
    rm confluentinc-kafka-connect-json-schema-converter-8.1.0.zip

# Download Elasticsearch connector from Confluent Hub
RUN cd /opt/kafka/plugins && \
    wget -q "https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-elasticsearch/versions/15.0.1/confluentinc-kafka-connect-elasticsearch-15.0.1.zip" && \
    unzip -q confluentinc-kafka-connect-elasticsearch-15.0.1.zip && \
    rm confluentinc-kafka-connect-elasticsearch-15.0.1.zip

# Set environment variables
ENV CONNECT_PLUGIN_PATH="/opt/kafka/plugins"