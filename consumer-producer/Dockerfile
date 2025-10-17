# Build the manager binary
FROM golang:1.25 AS builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY . .

# Build
RUN make build

FROM debian:bookworm-slim

# Install CA certificates and any required libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /
COPY --from=builder /workspace/kafka-consumer-producer /kafka-consumer-producer

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

ENTRYPOINT ["/kafka-consumer-producer"]



# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
# FROM gcr.io/distroless/static:nonroot
# WORKDIR /
# COPY --from=builder /workspace/kafka-consumer-producer .
# USER 65532:65532

# ENTRYPOINT ["/kafka-consumer-producer"]

