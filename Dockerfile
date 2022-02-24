FROM ubuntu:bionic

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64/jre
ENV HADOOP_HOME /opt/hadoop
ENV SPARK_HOME /opt/spark
ENV HIVE_HOME /opt/hive
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${HIVE_HOME}/bin:${PATH}"
# ENV HADOOP_VERSION 3.2.0
ENV SHORT_HADOOP_VERSION 3.2
ENV HADOOP_VERSION 3.1.1
ENV HIVE_VERSION 3.1.2
# ENV SPARK_VERSION 3.2.1
ENV SPARK_VERSION 3.1.2
ENV PYSPARK_PYTHON=python3
# when the time comes, upgrade the version of Zeppelin to 0.11.0 or 0.10.1 since 0.10.0 DOES NOT work with Spark 3.2..
ENV ZEPPELIN_VERSION=0.10.0

ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

# create some users..
RUN useradd -ms /bin/bash hdfs
RUN useradd -ms /bin/bash hive
RUN useradd -ms /bin/bash yarn
RUN useradd -ms /bin/bash tez
RUN useradd -ms /bin/bash spark

# install Python3 stuff..
RUN apt-get update && \
    apt-get install -y wget nano openjdk-8-jdk ssh openssh-server unzip
RUN apt update && apt install -y python3 python3-pip python3-dev build-essential libssl-dev libffi-dev libpq-dev

# install Hadoop
RUN wget -P /tmp/ https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
RUN tar xvf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /tmp && \
	mv /tmp/hadoop-${HADOOP_VERSION} /opt/hadoop

# once Hadoop has been installed in the appropriate path, remove the zipped binaries
RUN rm -rf /tmp/hadoop-${HADOOP_VERSION}.tar.gz

COPY /confs/hdfs-site.xml ${HADOOP_CONF_DIR}/
COPY /confs/core-site.xml ${HADOOP_CONF_DIR}/
COPY /confs/mapred-site.xml ${HADOOP_CONF_DIR}/
COPY /confs/yarn-site.xml ${HADOOP_CONF_DIR}/
COPY /confs/slaves ${HADOOP_CONF_DIR}/workers
COPY /confs/capacity-scheduler.xml ${HADOOP_CONF_DIR}/

COPY /confs/libsnappy.so ${HADOOP_HOME}/lib/native/libsnappy.so.1

# install Spark
RUN wget -P /tmp/ https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SHORT_HADOOP_VERSION}.tgz
RUN tar xvf /tmp/spark-${SPARK_VERSION}-bin-hadoop${SHORT_HADOOP_VERSION}.tgz -C /tmp && \
    mv /tmp/spark-${SPARK_VERSION}-bin-hadoop${SHORT_HADOOP_VERSION} ${SPARK_HOME}

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
	chmod 600 ~/.ssh/authorized_keys
COPY /confs/config /root/.ssh
RUN chmod 600 /root/.ssh/config

# once Spark has been installed in the appropriate path, remove the zipped binaries
RUN rm -rf /tmp/spark-${SPARK_VERSION}-bin-hadoop${SHORT_HADOOP_VERSION}.tgz

# install Livy
# RUN wget -P /tmp/ https://dlcdn.apache.org/incubator/livy/0.7.1-incubating/apache-livy-0.7.1-incubating-bin.zip
# RUN unzip /tmp/apache-livy-0.7.1-incubating-bin.zip -d /tmp && \
#     mv /tmp/apache-livy-0.7.1-incubating-bin /opt/livy
# COPY /confs/livy-env.sh /opt/livy/conf
# once Livy has been installed in the appropriate path, remove the zipped binaries
# RUN rm -rf /tmp/apache-livy-0.7.1-incubating-bin.zip

# install Tez
RUN wget -P /tmp/ https://dlcdn.apache.org/tez/0.9.1/apache-tez-0.9.1-bin.tar.gz
RUN tar xvf /tmp/apache-tez-0.9.1-bin.tar.gz -C /tmp && \
	mv /tmp/apache-tez-0.9.1-bin /opt/tez
COPY /confs/tez-site.xml /opt/tez/conf/

# once Tez has been installed in the appropriate path, remove the zipped binaries
RUN rm -rf /tmp/apache-tez-0.9.1-bin.tar.gz


# install Hive
RUN wget -P /tmp/ https://dlcdn.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz
RUN tar xvf /tmp/apache-hive-${HIVE_VERSION}-bin.tar.gz -C /tmp && \
	mv /tmp/apache-hive-${HIVE_VERSION}-bin /opt/hive

COPY /confs/hive-env.sh ${HIVE_HOME}/conf
COPY /confs/hive-site.xml ${HIVE_HOME}/conf
COPY /confs/mysql-connector-java.jar ${HIVE_HOME}/lib
COPY /confs/mysql-connector-java.jar ${SPARK_HOME}/jars
RUN ln -sf /opt/tez/conf/tez-site.xml /opt/hive/conf/.

# once Hive has been installed in the appropriate path, remove the zipped binaries
RUN rm -rf /tmp/apache-hive-${HIVE_VERSION}-bin.tar.gz


# install Zeppelin
# do NOT install Zeppelin until we can find a distribution which supports Spark 2.3
# RUN wget -P /tmp/ https://dlcdn.apache.org/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz
# RUN tar xvf /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz -C /tmp && \
#	mv /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all /opt/zeppelin

# COPY /confs/zeppelin-site.xml /opt/zeppelin/conf
# COPY /confs/zeppelin-env.sh /opt/zeppelin/conf
# COPY /confs/interpreter.json /opt/zeppelin/conf

# once Zeppelin has been installed in the appropriate path, remove the zipped binaries
# RUN rm -rf /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz


# create symlinks of Spark jars into the Hive lib classpath
RUN ln -sf /opt/spark/jars/scala-library-2.12.15.jar /opt/hive/lib/.
RUN ln -sf /opt/spark/jars/spark-network-common_2.12-${SPARK_VERSION}.jar /opt/hive/lib/.
RUN ln -sf /opt/spark/jars/spark-core_2.12-${SPARK_VERSION}.jar /opt/hive/lib/.

COPY /confs/slaves ${SPARK_HOME}/conf/workers
COPY /confs/spark-defaults.conf ${SPARK_HOME}/conf
RUN ln -sf /opt/spark/conf/spark-defaults.conf /opt/hive/conf/.
RUN ln -sf /opt/spark/conf/spark-defaults.conf /opt/hive/lib/.
RUN ln -sf /opt/spark/conf/spark-defaults.conf /opt/hive/bin/.
RUN ln -sf /opt/hive/conf/hive-site.xml /opt/spark/conf/.
RUN ln -sf /opt/hadoop/etc/hadoop/core-site.xml /opt/spark/conf/.
RUN ln -sf /opt/hadoop/etc/hadoop/hdfs-site.xml /opt/spark/conf/.
RUN ln -sf /opt/spark/conf/spark-defaults.conf /opt/hive/.

COPY /script_files/bootstrap.sh /
COPY /script_files/mysql_metastore_commands.sql /
COPY /confs/mysqld.cnf /
COPY /script_files/BizkaiBusGPS_tracking.py /opt/spark/examples/src/main/python/
COPY /script_files/Streaming_BizkaiBusGPS_tracking.py /opt/spark/examples/src/main/python/
COPY /script_files/Kafka_Streaming_BizkaiBusGPS_tracking.py /opt/spark/examples/src/main/python/

RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/environment

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# run needed python libraries on every node so that PySpark works
RUN pip3 install utm
# RUN pip3 install matplotlib 
RUN pip3 install pandas 
RUN pip3 install numpy

EXPOSE 9000
EXPOSE 8998
EXPOSE 9083
EXPOSE 10000
EXPOSE 10001
EXPOSE 10002
EXPOSE 10003
EXPOSE 7077
EXPOSE 9870
EXPOSE 4040
EXPOSE 8020
EXPOSE 22
EXPOSE 18081
EXPOSE 3306
EXPOSE 8085

RUN mkdir lab
COPY datasets /root/lab/datasets
RUN mkdir tweets_dir
COPY tweets /root/tweets_dir/tweets

ENTRYPOINT ["/bin/bash", "bootstrap.sh"]
