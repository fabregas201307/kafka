# Use official OpenJDK image as base
FROM openjdk:11-jre-slim

# Set environment variables
ENV KAFKA_VERSION=3.8.1 \
    SCALA_VERSION=2.13 \
    KAFKA_HOME=/opt/kafka

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget jq netcat && \
    rm -rf /var/lib/apt/lists/*

# Download and extract Kafka
RUN wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /tmp/kafka.tgz && \
    mkdir -p ${KAFKA_HOME} && \
    tar -xzf /tmp/kafka.tgz --strip-components=1 -C ${KAFKA_HOME} && \
    rm /tmp/kafka.tgz

# Expose Kafka and Zookeeper ports
EXPOSE 9092 2181

# Copy startup script
COPY start-kafka.sh /usr/bin/start-kafka.sh
RUN chmod +x /usr/bin/start-kafka.sh

# Set default command to start Kafka
CMD ["start-kafka.sh"]
