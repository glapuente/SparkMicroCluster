#!/bin/bash

hdfs namenode -format
service ssh start
if [ "$HOSTNAME" = node-master ]; then
    # rename some template files
    mv /opt/hive/conf/hive-exec-log4j2.properties.template /opt/hive/conf/hive-exec-log4j2.properties
    mv /opt/hive/conf/beeline-log4j2.properties.template /opt/hive/conf/beeline-log4j2.properties
    mv /opt/hive/conf/hive-exec-log4j2.properties.template /opt/hive/conf/hive-exec-log4j2.properties
    mv /opt/hive/conf/hive-log4j2.properties.template /opt/hive/conf/hive-log4j2.properties

    # cp /opt/hadoop/share/hadoop/hdfs/hadoop-hdfs-client-3.2.0.jar /opt/tez/lib/hadoop-hdfs-client-3.1.3.jar
    # mkdir -p /opt/livy/logs

    start-dfs.sh
    start-yarn.sh
    start-master.sh
    hdfs dfs -mkdir /spark2-history
    bash /opt/spark/sbin/start-all.sh
    # bash /opt/spark/sbin/start-history-server.sh
    hdfs dfs -put /root/lab/datasets/ /.
    hdfs dfs -mkdir -p /datos/in/tweets/csv
    hdfs dfs -mkdir -p /datos/tmp/tweets
    hdfs dfs -put /root/tweets_dir/tweets/* /datos/in/tweets/csv/.
    hdfs dfs -mkdir /spark-jars
    hdfs dfs -put /opt/spark/jars/*.jar /spark-jars/.
    # create HIVE directories in HDFS
    hdfs dfs -mkdir /tmp
    hdfs dfs -chmod g+w /tmp
    hdfs dfs -mkdir -p /user/hive/warehouse
    hdfs dfs -chmod g+w /user/hive/warehouse

    # create Tez directories and upload files
    hdfs dfs -mkdir -p /apps/tez
    hdfs dfs -put /opt/tez/* /apps/tez
    hdfs dfs -chmod g+w /apps/tez
    hdfs dfs -mkdir /user/tez
    hdfs dfs -chown tez:tez /user/tez
    hdfs dfs -chmod 766 /user/tez

    # create some users in HDFS
    hdfs dfs -mkdir /user/spark
    hdfs dfs -chown spark:spark /user/spark
    hdfs dfs -chmod 766 /user/spark

    hdfs dfs -mkdir /user/hdfs
    hdfs dfs -chown hdfs:hdfs /user/hdfs
    hdfs dfs -chmod 766 /user/hdfs

    hdfs dfs -mkdir /user/yarn
    hdfs dfs -chown yarn:yarn /user/yarn
    hdfs dfs -chmod 766 /user/yarn

    # install MySQL and configure stuff for using it as the metastore
    apt-get install -y mysql-server
    service mysql start
    mysql -uroot -proot < mysql_metastore_commands.sql
    cp /mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
    service mysql restart
    schematool -initSchema -dbType mysql
    hiveserver2 &

    # hiveserver2 &  # it's better to fire up the server afterwards.. having changed configuration files on demand
    # manually fire up the hiveserver when MySQL is already set up

fi
#bash
while :; do :; done & kill -STOP $! && wait $!
