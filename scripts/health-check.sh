#!/bin/bash
set -e

# Health check script for Kafka broker
check_kafka() {
    echo "Checking Kafka broker..."
    nc -z localhost 9092 || return 1
    
    # Check if broker is registered with ZooKeeper
    $KAFKA_HOME/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092 || return 1
    
    echo "Kafka broker is healthy"
    return 0
}

# Health check for ZooKeeper
check_zookeeper() {
    echo "Checking ZooKeeper..."
    nc -z localhost 2181 || return 1
    echo "ruok" | nc localhost 2181 | grep "imok" || return 1
    
    echo "ZooKeeper is healthy"
    return 0
}

# Main health check
main() {
    check_zookeeper || exit 1
    check_kafka || exit 1
    exit 0
}

main 