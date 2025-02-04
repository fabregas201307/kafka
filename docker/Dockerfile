# Build stage
FROM openjdk:11-jre-slim AS builder

# Set environment variables
ENV KAFKA_VERSION=3.8.1 \
    SCALA_VERSION=2.13 \
    KAFKA_HOME=/opt/kafka

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget jq netcat && \
    rm -rf /var/lib/apt/lists/* && \
    # Download and extract Kafka
    wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /tmp/kafka.tgz && \
    mkdir -p ${KAFKA_HOME} && \
    tar -xzf /tmp/kafka.tgz --strip-components=1 -C ${KAFKA_HOME} && \
    rm /tmp/kafka.tgz

# Final stage
FROM openjdk:11-jre-slim

# Set environment variables
ENV KAFKA_VERSION=3.8.1 \
    SCALA_VERSION=2.13 \
    KAFKA_HOME=/opt/kafka

# Create kafka user
RUN groupadd -r kafka && \
    useradd -r -g kafka kafka && \
    apt-get update && \
    apt-get install -y netcat && \
    rm -rf /var/lib/apt/lists/*

# Copy Kafka from builder stage
COPY --from=builder --chown=kafka:kafka ${KAFKA_HOME} ${KAFKA_HOME}

# Create data and log directories
RUN mkdir -p /var/lib/kafka/data /var/lib/kafka/logs && \
    chown -R kafka:kafka /var/lib/kafka

# Set working directory
WORKDIR ${KAFKA_HOME}

# Create volume mount points
VOLUME ["/var/lib/kafka/data", "/var/lib/kafka/logs"]

# Expose Kafka and Zookeeper ports
EXPOSE 9092 2181

# Copy startup script
COPY --chown=kafka:kafka docker/start-kafka.sh /usr/bin/
RUN chmod +x /usr/bin/start-kafka.sh

# Switch to kafka user
USER kafka

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD nc -z localhost 9092 || exit 1

# Set default command to start Kafka
CMD ["start-kafka.sh"]