#!/bin/bash
set -e

# Default values
KAFKA_BOOTSTRAP_SERVERS=${KAFKA_BOOTSTRAP_SERVERS:-"localhost:9092"}
REPLICATION_FACTOR=${REPLICATION_FACTOR:-3}
PARTITIONS=${PARTITIONS:-3}

# Create default topics
create_topics() {
    # List of topics to create with their configurations
    declare -A topics=(
        ["events"]="--config retention.ms=604800000"
        ["notifications"]="--config retention.ms=259200000"
        ["deadletters"]="--config retention.ms=1209600000"
    )

    for topic in "${!topics[@]}"; do
        echo "Creating topic: $topic"
        $KAFKA_HOME/bin/kafka-topics.sh --create \
            --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
            --topic "$topic" \
            --partitions $PARTITIONS \
            --replication-factor $REPLICATION_FACTOR \
            ${topics[$topic]} || echo "Topic $topic already exists"
    done
}

create_topics 