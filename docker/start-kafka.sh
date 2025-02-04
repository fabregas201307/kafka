#!/bin/bash

# Start Zookeeper in the background
$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties &

# Configure Kafka broker settings
cat <<EOF > $KAFKA_HOME/config/server.properties
broker.id=1
log.dirs=/var/lib/kafka/logs
zookeeper.connect=localhost:2181
listeners=PLAINTEXT://0.0.0.0:9092
EOF

# Start Kafka server
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
