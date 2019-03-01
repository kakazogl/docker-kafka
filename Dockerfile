## Apache Kafka distribution with Scala 2.12
## Fork from ches/kafka

FROM java:openjdk-8-jdk-alpine
MAINTAINER Iurii Karakosov <y.karakosov@gmail.com>

# The Scala 2.12 build is currently recommended by the project.
ENV KAFKA_VERSION=2.1.1 KAFKA_SCALA_VERSION=2.12 JMX_PORT=7203
ENV KAFKA_RELEASE_ARCHIVE=kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}

# Download Kafka binary distribution
ADD http://apache-mirror.rbc.ru/pub/apache/kafka/${KAFKA_VERSION}/${KAFKA_RELEASE_ARCHIVE}.tgz /

# Install Kafka to /kafka

RUN mkdir /kafka /data /log && apk add --no-cache bash
RUN tar -xf ${KAFKA_RELEASE_ARCHIVE}.tgz -C / && mv /${KAFKA_RELEASE_ARCHIVE}/* /kafka/

COPY config /kafka/config
COPY start.sh /start.sh

ENV PATH /kafka/bin:$PATH

# broker, jmx
EXPOSE 9092 ${JMX_PORT}
VOLUME [ "/data", "/logs" ]

CMD ["/start.sh"]
