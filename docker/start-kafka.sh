#!/bin/bash
set -e

# Default environment variables
KAFKA_BROKER_ID=${KAFKA_BROKER_ID:-1}
KAFKA_LISTENERS=${KAFKA_LISTENERS:-PLAINTEXT://0.0.0.0:9092}
KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}
KAFKA_LOG_DIRS=${KAFKA_LOG_DIRS:-/var/lib/kafka/logs}

# Function to handle shutdown
shutdown() {
    echo "Shutting down Kafka and ZooKeeper..."
    $KAFKA_HOME/bin/kafka-server-stop.sh
    $KAFKA_HOME/bin/zookeeper-server-stop.sh
    exit 0
}

# Trap SIGTERM and SIGINT
trap shutdown SIGTERM SIGINT

# Create log directory if it doesn't exist
mkdir -p ${KAFKA_LOG_DIRS}

# Configure Kafka broker settings
cat <<EOF > $KAFKA_HOME/config/server.properties
broker.id=${KAFKA_BROKER_ID}
log.dirs=${KAFKA_LOG_DIRS}
zookeeper.connect=${KAFKA_ZOOKEEPER_CONNECT}
listeners=${KAFKA_LISTENERS}
# Additional recommended settings
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
EOF

echo "Starting ZooKeeper..."
$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties &
ZOOKEEPER_PID=$!

# Wait for ZooKeeper to start
echo "Waiting for ZooKeeper to start..."
sleep 10

# Check if ZooKeeper is running
if ! kill -0 $ZOOKEEPER_PID > /dev/null 2>&1; then
    echo "ZooKeeper failed to start"
    exit 1
fi

echo "Starting Kafka Server..."
exec $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
