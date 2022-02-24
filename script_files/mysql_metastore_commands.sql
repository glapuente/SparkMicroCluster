DROP DATABASE IF EXISTS metastore_db;
CREATE DATABASE IF NOT EXISTS metastore_db;
USE metastore_db;
SOURCE /opt/hive/scripts/metastore/upgrade/mysql/hive-schema-3.1.0.mysql.sql;
CREATE USER IF NOT EXISTS "hiveusr"@"%" IDENTIFIED BY "hivepassword";
GRANT ALL ON *.* TO "hiveusr"@"%" IDENTIFIED BY "hivepassword";
FLUSH privileges;
