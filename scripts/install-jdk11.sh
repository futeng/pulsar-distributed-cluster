#!/bin/bash

yum -y install tar wget
mkdir -p /opt/java
cd /opt/java
wget http://PULSAR-CLIENT/pulsar/pkgs/jdk-11.0.15.1_linux-x64_bin.tar.gz
tar zxvf jdk-11.0.15.1_linux-x64_bin.tar.gz
rm jdk-11.0.15.1_linux-x64_bin.tar.gz


cp /etc/profile /etc/profile.bak.beforeAddJDK11

echo "## JDK11 ##" | sudo tee -a /etc/profile
echo 'export JAVA_HOME=/opt/java/jdk-11.0.15.1' | sudo tee -a /etc/profile
echo 'export JRE_HOME=$JAVA_HOME/jre' | sudo tee -a /etc/profile
echo 'export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' | sudo tee -a /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$HOME/bin' | sudo tee -a /etc/profile
echo "## JDK11 ##" | sudo tee -a /etc/profile

source /etc/profile
java -version

rm -f install_jdk11.sh
