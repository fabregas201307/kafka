#!/bin/bash
set -e

# Default values
BACKUP_DIR=${BACKUP_DIR:-"/var/lib/kafka/backup"}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup Kafka configurations
backup_configs() {
    echo "Backing up Kafka configurations..."
    tar -czf $BACKUP_DIR/kafka_configs_$TIMESTAMP.tar.gz \
        $KAFKA_HOME/config/server.properties \
        $KAFKA_HOME/config/zookeeper.properties \
        $KAFKA_HOME/config/log4j.properties
}

# Backup topic configurations
backup_topics() {
    echo "Backing up topic configurations..."
    $KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | \
    while read topic; do
        $KAFKA_HOME/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --describe --topic "$topic" \
            > $BACKUP_DIR/topic_${topic}_${TIMESTAMP}.config
    done
}

backup_configs
backup_topics 