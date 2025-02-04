#!/bin/bash
set -e

# Default values
METRICS_PORT=${METRICS_PORT:-"9308"}
JMX_PORT=${JMX_PORT:-"9999"}

# Check broker metrics
check_metrics() {
    echo "Checking Kafka metrics..."
    
    # Basic metrics using JMX
    echo "Active Controller Count:"
    jcmd $KAFKA_HOME ActiveControllerCount
    
    echo "Under Replicated Partitions:"
    jcmd $KAFKA_HOME UnderReplicatedPartitions
    
    echo "Offline Partition Count:"
    jcmd $KAFKA_HOME OfflinePartitionsCount
}

# Check broker logs
check_logs() {
    echo "Checking Kafka logs..."
    tail -n 100 $KAFKA_HOME/logs/server.log | grep -i "error\|warn" || true
}

# Main monitoring function
monitor() {
    check_metrics
    check_logs
}

monitor 