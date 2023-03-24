#!/bin/bash

yum -y install tar wget > ./yum.log 2>&1

url="http://DISPATCH_HOST/pulsar/pkgs/jdk-11.0.15.1_linux-x64_bin.tar.gz"
if [[ $(grep -c "pulsar-distributed-cluster-jdk11" /etc/profile) -ne 0 ]]; then 
	echo "[$(hostname)]exec> The JDK is already installed and will be skipped."; 
else 

	mkdir -p /opt/java
	cd /opt/java
	
	echo "[$(hostname)]exec> Download JDK from : $url"
	wget -q http://DISPATCH_HOST/pulsar/pkgs/jdk-11.0.15.1_linux-x64_bin.tar.gz
	tar zxf jdk-11.0.15.1_linux-x64_bin.tar.gz
	rm jdk-11.0.15.1_linux-x64_bin.tar.gz
	
	cp /etc/profile /etc/profile.bak.beforeAddJDK11
	
	echo "[$(hostname)]exec> Configure JDK env."

	echo "## pulsar-distributed-cluster-jdk11 ##" | sudo tee -a /etc/profile
	echo 'export JAVA_HOME=/opt/java/jdk-11.0.15.1' | sudo tee -a /etc/profile
	echo 'export JRE_HOME=$JAVA_HOME/jre' | sudo tee -a /etc/profile
	echo 'export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' | sudo tee -a /etc/profile
	echo 'export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$HOME/bin' | sudo tee -a /etc/profile
	echo "## pulsar-distributed-cluster-jdk11 ##" | sudo tee -a /etc/profile

fi

source /etc/profile
java -version

rm -f ~/install-jdk11.sh ~/yum.log
