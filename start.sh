#!/bin/bash -x

IP=$(grep "\s${HOSTNAME}$" /etc/hosts | head -n 1 | awk '{print $1}')

cat /kafka/config/server.properties.template | sed \
  -e "s|{{KAFKA_ADVERTISED_LISTENERS}}|${KAFKA_ADVERTISED_LISTENERS:-PLAINTEXT://9092}|g" \
  -e "s|{{KAFKA_LISTENERS}}|${KAFKA_LISTENERS:-PLAINTEXT://9092}|g" \
  -e "s|{{KAFKA_LISTENER_PROTOCOL_MAP}}|${KAFKA_LISTENER_PROTOCOL_MAP:-PLAINTEXT:PLAINTEXT}|g" \
  -e "s|{{KAFKA_INTER_BROKER_LISTENER}}|${KAFKA_INTER_BROKER_LISTENER:-PLAINTEXT}|g" \
  -e "s|{{KAFKA_AUTO_CREATE_TOPICS_ENABLE}}|${KAFKA_AUTO_CREATE_TOPICS_ENABLE:-false}|g" \
  -e "s|{{KAFKA_BROKER_ID}}|${KAFKA_BROKER_ID:-0}|g" \
  -e "s|{{KAFKA_DEFAULT_REPLICATION_FACTOR}}|${KAFKA_DEFAULT_REPLICATION_FACTOR:-1}|g" \
  -e "s|{{KAFKA_DEFAULT_TOPIC_REPLICATION_FACTOR}}|${KAFKA_DEFAULT_TOPIC_REPLICATION_FACTOR:-1}|g" \
  -e "s|{{KAFKA_DELETE_TOPIC_ENABLE}}|${KAFKA_DELETE_TOPIC_ENABLE:-true}|g" \
  -e "s|{{KAFKA_GROUP_MAX_SESSION_TIMEOUT_MS}}|${KAFKA_GROUP_MAX_SESSION_TIMEOUT_MS:-300000}|g" \
  -e "s|{{KAFKA_INTER_BROKER_PROTOCOL_VERSION}}|${KAFKA_INTER_BROKER_PROTOCOL_VERSION:-$KAFKA_VERSION}|g" \
  -e "s|{{KAFKA_LOG_MESSAGE_FORMAT_VERSION}}|${KAFKA_LOG_MESSAGE_FORMAT_VERSION:-$KAFKA_VERSION}|g" \
  -e "s|{{KAFKA_LOG_RETENTION_HOURS}}|${KAFKA_LOG_RETENTION_HOURS:-168}|g" \
  -e "s|{{KAFKA_NUM_PARTITIONS}}|${KAFKA_NUM_PARTITIONS:-1}|g" \
  -e "s|{{ZOOKEEPER_CHROOT}}|${ZOOKEEPER_CHROOT:-}|g" \
  -e "s|{{ZOOKEEPER_CONNECTION_STRING}}|${ZOOKEEPER_CONNECTION_STRING:-localhost:2181}|g" \
  -e "s|{{ZOOKEEPER_CONNECTION_TIMEOUT_MS}}|${ZOOKEEPER_CONNECTION_TIMEOUT_MS:-10000}|g" \
  -e "s|{{ZOOKEEPER_SESSION_TIMEOUT_MS}}|${ZOOKEEPER_SESSION_TIMEOUT_MS:-10000}|g" \
  -e "s|{{KAFKA_MESSAGE_MAX_BYTES}}|${KAFKA_MESSAGE_MAX_BYTES:-1000012}|g" \
  -e "s|{{KAFKA_REPLICA_FETCH_MAX_BYTES}}|${KAFKA_REPLICA_FETCH_MAX_BYTES:-1048576}|g" \
   > /kafka/config/server.properties

# Kafka's built-in start scripts set the first three system properties here, but
# we add two more to make remote JMX easier/possible to access in a Docker
# environment:
#
#   1. RMI port - pinning this makes the JVM use a stable one instead of
#      selecting random high ports each time it starts up.
#   2. RMI hostname - normally set automatically by heuristics that may have
#      hard-to-predict results across environments.
#
# These allow saner configuration for firewalls, EC2 security groups, Docker
# hosts running in a VM with Docker Machine, etc. See:
#
# https://issues.apache.org/jira/browse/CASSANDRA-7087
if [ -z $KAFKA_JMX_OPTS ]; then
    KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.ssl=false"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-$KAFKA_ADVERTISED_HOST_NAME} "
    export KAFKA_JMX_OPTS
fi

echo "Starting kafka"
exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties
