#!/usr/bin/env bash
# Script to deploy pulsar in distributed cluster.
# More info https://github.com/futeng/pulsar-distributed-cluster
# Copyright (C) 2022 stremnative.io (Please feel free to contact me : teng.fu@streamnative.io)
# Permission to copy and modify is granted under the Apache 2.0 license
# Last revised 8/9/2022

printHello() {

echo " _   _  _     ______        _                    _ ";
echo "| | | |(_)    | ___ \      | |                  | |";
echo "| |_| | _     | |_/ /_   _ | | ___   __ _  _ __ | |";
echo "|  _  || |    |  __/| | | || |/ __| / _\` || '__|| |";
echo "| | | || | _  | |   | |_| || |\__ \| (_| || |   |_|";
echo "\_| |_/|_|( ) \_|    \__,_||_||___/ \__,_||_|   (_)";
echo "          |/                                       ";
echo "                                                   ";
}

## Conditions
# [] 1. Dispatch nodes can access all nodes without entering a password.
# [] 2. Dispatch nodes users have sudo permissions (httpd needs to be turned on).
# [] 3. Configured the /etc/hosts of all the nodes , and make sure the hostnames are correct.
# [] 4. Configured time synchronization.
# [] 5. Modify the custom storage directory directly in the function. initBookieConf
# [] 6. We need download pkgs put into dir: deploy-pulsar/pkgs

# Current version
# apache-pulsar-2.10.1.7-bin.tar.gz
# grafana-enterprise-9.1.2.linux-amd64.tar.gz
# node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
# prometheus-2.38.0.linux-amd64.tar.gz
# pulsar-protocol-handler-kafka-2.10.1.7.nar

#####################################################
################# Custom variables ##################

needInstallJDK11="false"
needInitializeClusterMetadata="true"

all_nodes=("test-pulsar-client" "test-pulsar-node1" "test-pulsar-node2")
bookie_nodes=("test-pulsar-client" "test-pulsar-node1" "test-pulsar-node2")
zookeeper_nodes=("test-pulsar-client" "test-pulsar-node1" "test-pulsar-node2")
broker_nodes=("test-pulsar-node1" "test-pulsar-node2")
dispatch_host="test-pulsar-client"

# The user used by the deployment.
user="pulsar"
pulsar_base="/home/pulsar"
pulsar_deploy_dir="pulsar-node"
pulsar_home=$pulsar_base/$pulsar_deploy_dir

# Set zookeeper data directory
data_dir="/zkdata"
# Pulsar cluster name 
cluster_name="sn"

#####################################################
########## System function and variables ############

# Timestampe
datename=$(date +"%Y-%m-%d %H:%M:%S")
echo_with_date="echo [$datename]"

# Zookeeper Quorum 
zkQuorum=""
length=${#zookeeper_nodes[@]}
for (( j=0; j<${length}; j++ ));
do
	zkQuorum="$zkQuorum${zookeeper_nodes[$j]}:2181,"
done
zkQuorum=${zkQuorum%?}
# echo "$zkQuorum"


check_port() {
  sudo netstat -tlpn | grep "\b$1\b"
}

# Client tools will deploy to /usr/local/bin
initClientTools() {
	sed -i "s/DISPATCH_HOST=\"pulsar-client\"/DISPATCH_HOST=\"$dispatch_host\"/" bin/dispatchConfWithFile
	
	rm bin/pulsar-hosts
	length=${#all_nodes[@]}
	for (( j=0; j<${length}; j++ ));
	do
		echo "${all_nodes[$j]}" >> bin/pulsar-hosts
	done
	
	rm bin/pulsar-hosts-only-bookies
	length=${#bookie_nodes[@]}
	for (( j=0; j<${length}; j++ ));
	do
		echo "${bookie_nodes[$j]}" >> bin/pulsar-hosts-only-bookies
		echo "#!/bin/bash" > bin/"ssh2bookie$j"
		echo "ssh -i /home/pulsar/.ssh/pulsar-cloud.pem pulsar@${bookie_nodes[$j]}" >> bin/"ssh2bookie$j"
	done
	
	rm bin/pulsar-hosts-only-brokers
	length=${#broker_nodes[@]}
	for (( j=0; j<${length}; j++ ));
	do
		echo "${broker_nodes[$j]}" >> bin/pulsar-hosts-only-brokers
		echo "#!/bin/bash" > bin/"ssh2broker$j"
		echo "ssh -i /home/pulsar/.ssh/pulsar-cloud.pem pulsar@${broker_nodes[$j]}" >> bin/"ssh2broker$j"
	done
	
	rm bin/pulsar-hosts-only-zookeepers
	length=${#zookeeper_nodes[@]}
	for (( j=0; j<${length}; j++ ));
	do
		echo "${zookeeper_nodes[$j]}" >> bin/pulsar-hosts-only-zookeepers
		echo "#!/bin/bash" > bin/"ssh2zk$j"
		echo "ssh -i /home/pulsar/.ssh/pulsar-cloud.pem pulsar@${zookeeper_nodes[$j]}" >> bin/"ssh2zk$j"
	done
	
	echo "#!/bin/bash" > bin/startAllBookies.sh
	echo "ssh2bookies \"source /etc/profile; $pulsar_home/bin/pulsar-daemon start bookie\"" >> bin/startAllBookies.sh
	
	echo "#!/bin/bash" > bin/startAllBrokers.sh
	echo "ssh2brokers \"source /etc/profile; $pulsar_home/bin/pulsar-daemon start broker\"" >> bin/startAllBrokers.sh
	
	echo "#!/bin/bash" > bin/startAllZookeepers.sh
	echo "ssh2zookeepers \"source /etc/profile; $pulsar_home/bin/pulsar-daemon start zookeeper\"" >> bin/startAllZookeepers.sh
	
	echo "#!/bin/bash" > bin/stopAllBookies.sh
	echo "ssh2bookies \"source /etc/profile; $pulsar_home/bin/pulsar-daemon stop bookie\"" >> bin/stopAllBookies.sh
	
	echo "#!/bin/bash" > bin/stopAllBrokers.sh
	echo "ssh2brokers \"source /etc/profile; $pulsar_home/bin/pulsar-daemon stop broker\"" >> bin/stopAllBrokers.sh
	
	echo "#!/bin/bash" > bin/stopAllZookeepers.sh
	echo "ssh2zookeepers \"source /etc/profile; $pulsar_home/bin/pulsar-daemon stop zookeeper\"" >> bin/stopAllZookeepers.sh
}

copyDeployTools() {

	sudo cp bin/* /usr/local/bin/
	sudo chown -R $user:$user /usr/local/bin/*
	sudo chmod u+x /usr/local/bin/*.sh
	sudo chmod u+x /usr/local/bin/ssh*
	
	cp -R pkgs/* /var/www/html/
	cp -R service/* /var/www/html/

}

startHttpd() {
	sudo yum -y install httpd
	sudo systemctl start httpd
	sudo systemctl enable httpd
	sudo systemctl status httpd
	sudo chown -R  $user:$user /var/www/html
	sudo mkdir -p /var/www/html/pulsar/conf
}

installJDK() {
	need=$1
	if [[ $need == "true" ]]; then
		ssh2all "wget -q $dispatch_host/install-jdk11.sh -O install-jdk11.sh"
		ssh2all "sudo sh install-jdk11.sh"
		ssh2all "java -version"
		ssh2all "source /etc/profile; java -version"
	fi
}

dispatchPkgs() {
	ssh2all "rm -rf ~/pulsar-node"
	ssh2all "wget -q $dispatch_host/replace-conf.sh -O replace-conf.sh"
	ssh2all "wget -q $dispatch_host/apache-pulsar-2.10.1.7-bin.tar.gz -O apache-pulsar-2.10.1.7-bin.tar.gz" 
	ssh2all "tar zxf apache-pulsar-2.10.1.7-bin.tar.gz"
	ssh2all "mv apache-pulsar-2.10.1.7 $pulsar_deploy_dir"
	ssh2all "rm apache-pulsar-2.10.1.7-bin.tar.gz"
}

initZookeeperConf() {
	initZKConf="init-zk.conf"

	echo "dataDir=$data_dir" > $initZKConf
	echo "admin.serverPort=9990" >> $initZKConf
	echo "metricsProvider.httpPort=7000" >> $initZKConf
	echo "clientPort=2181" >> $initZKConf
	
	length=${#zookeeper_nodes[@]}
	for (( j=0; j<${length}; j++ ));
	do
		# printf  "Current index %d with value %s\n" $j "${zookeeper_nodes[$j]}"
		ssh -i /home/pulsar/.ssh/pulsar-cloud.pem $user@"${zookeeper_nodes[$j]}" "sudo mkdir -p $data_dir; sudo chown -R $user:$user $data_dir; echo $j > $data_dir/myid"
		echo "server.$j=${zookeeper_nodes[$j]}:2888:3888" >> $initZKConf
	done
	# cat $initZKConf
	dispatchConfWithFile zookeeper $initZKConf
}

initPulsarMetadata() {
	if [[ $needInitializeClusterMetadata == "true" ]]; then
		cd $pulsar_home
		bin/pulsar initialize-cluster-metadata \
  			--cluster $cluster_name \
  			--zookeeper $zkQuorum \
  			--configuration-store $zkQuorum \
  			--web-service-url http://${broker_nodes[0]}:8080 \
  			--broker-service-url pulsar://${broker_nodes[0]}:6650 > ./initialize-cluster-metadata.log 2>&1

  		if [[ -f ./initialize-cluster-metadata.log && $(grep -c "Successfully" ./initialize-cluster-metadata.log) -ne 0 ]]; then
			${echo_with_date} "[7/9][√] Your cluster metadata initialized in Zookeeper is ready."
			rm ./initialize-cluster-metadata.log
		else
			${echo_with_date} "[7/9][x] Initialize pulsar metadata in Zookeeper failed. Please check it manually."
			exit 1
		fi
	fi
}

initBookieConf() {
	initBookiesConf="init-bk.conf"
	
	echo "journalDirectory=/journal01,/journal02" > $initBookiesConf
	echo "ledgerDirectories=/ledger01,/ledger02" >> $initBookiesConf
	echo "zkServers=$zkQuorum" >> $initBookiesConf
	echo "httpServerEnabled=true" >> $initBookiesConf
	echo "autoRecoveryDaemonEnabled=false" >> $initBookiesConf
	
	length=${#bookie_nodes[@]}
	for (( j=0; j<${length}; j++ ));
	do
		# printf  "Current index %d with value %s\n" $j "${zookeeper_nodes[$j]}"
		ssh -i /home/pulsar/.ssh/pulsar-cloud.pem $user@"${zookeeper_nodes[$j]}" "sudo mkdir -p /{journal01,journal02,ledger01,ledger02}"
		ssh -i /home/pulsar/.ssh/pulsar-cloud.pem $user@"${zookeeper_nodes[$j]}" "sudo chown -R $user:$user /journal01; sudo chown -R $user:$user /journal02; sudo chown -R $user:$user /ledger01; sudo chown -R $user:$user /ledger02"
	done
	
	dispatchConfWithFile bookie $initBookiesConf	
}

testBookies() {
	ssh2bookies "source /etc/profile; $pulsar_home/bin/bookkeeper shell simpletest --ensemble 2 --writeQuorum 2 --ackQuorum 2 --numEntries 10" > $pulsar_base/10_entries_written.log 2>&1 
	length=${#bookie_nodes[@]}

 	if [[ -f $pulsar_base/10_entries_written.log && $(grep -c "10 entries written" $pulsar_base/10_entries_written.log) -eq $length ]]; then
		${echo_with_date} "[9/9][√] Your bookies is all ready."
		rm $pulsar_base/10_entries_written.log

	else
		${echo_with_date} "[9/9][x] Bookies simpletest failed. Please check it manually."
		exit 1
	fi	
}

initBrokerConf() {

	initBrokerConf="init-broker.conf"

	echo "metadataStoreUrl=zk:$zkQuorum" > $initBrokerConf
	echo "configurationMetadataStoreUrl=zk:$zkQuorum" >> $initBrokerConf
	echo "clusterName=$cluster_name" >> $initBrokerConf
	echo "loadBalancerAutoBundleSplitEnabled=false" >> $initBrokerConf
	echo "loadBalancerAutoUnloadSplitBundlesEnabled=false" >> $initBrokerConf
	echo "defaultNumberOfNamespaceBundles=500" >> $initBrokerConf
	echo "systemTopicEnabled=true" >> $initBrokerConf
	echo "topicLevelPoliciesEnabled=true" >> $initBrokerConf
	echo "maxMessageSize=5242880" >> $initBrokerConf
	echo "zooKeeperSessionTimeoutMillis=30000" >> $initBrokerConf
	echo "managedLedgerDefaultEnsembleSize=2" >> $initBrokerConf
	echo "managedLedgerDefaultWriteQuorum=2" >> $initBrokerConf
	echo "managedLedgerDefaultAckQuorum=2" >> $initBrokerConf
	echo "bookkeeperClientMinNumRacksPerWriteQuorum=1" >> $initBrokerConf
	echo "brokerDeleteInactiveTopicsEnabled=false" >> $initBrokerConf
	echo "allowAutoTopicCreationType=partitioned" >> $initBrokerConf

	dispatchConfWithFile broker $initBrokerConf
}

replaceClientConf() {
	cd $pulsar_home
	# webServiceUrl=http://127.0.0.1:8080/
	sed -i "s|webServiceUrl=http://localhost:8080/|webServiceUrl=http://${broker_nodes[0]}:8080/|" conf/client.conf

	# brokerServiceUrl=pulsar://127.0.0.1:6650/
	sed -i "s|brokerServiceUrl=pulsar://localhost:6650/|brokerServiceUrl=pulsar://${broker_nodes[0]}:6650/|" conf/client.conf
}

# Commands for create local cluster, tenant and namespaces.
crateTenantAndNamespace() {
	# jps -m| grep -v Jps
	cd $pulsar_home
	${echo_with_date} "[ list brokers ] -> bin/pulsar-admin brokers list $cluster_name"
	bin/pulsar-admin brokers list $cluster_name
	
	# leader-broker command dose not exits before pulsar 2.8.0
	#${echo_with_date} "[ leader-broker ] -> bin/pulsar-admin brokers leader-broker"
	#bin/pulsar-admin brokers leader-broker
	
	${echo_with_date} "[ create local cluster ] -> bin/pulsar-admin clusters create $cluster_name"	
	bin/pulsar-admin clusters create  $cluster_name --url "${broker_nodes[0]}:8080"
	${echo_with_date} "[ create tenant ] -> bin/pulsar-admin tenants create t1 -c $cluster_name"	
	bin/pulsar-admin tenants create t1 -c $cluster_name
	${echo_with_date} "[ create tenant/namespaces ] -> bin/pulsar-admin namespaces create t1/ns1 -c $cluster_name"
	bin/pulsar-admin namespaces create t1/ns1 -c $cluster_name

	${echo_with_date} "[ list tenants ] -> bin/pulsar-admin tenants list"
	bin/pulsar-admin tenants list 
	${echo_with_date} "[ list tenant's namespaces ] -> bin/pulsar-admin namespaces list t1"
	bin/pulsar-admin namespaces list t1
	${echo_with_date} "[ get tenant's clusters ] -> bin/pulsar-admin namespaces get-clusters t1/ns1"
	bin/pulsar-admin namespaces get-clusters t1/ns1

}

testBrokers() {
	cd $pulsar_home
	bin/pulsar-client produce persistent://t1/ns1/test -n 10  -m "hello pulsar" > ./produce.log 2>&1
	
  	if [[ -f ./produce.log && $(grep -c "10 messages successfully produced" ./produce.log) -ne 0 ]]; then
		${echo_with_date} "[pulsar-client produce][√] 10 messages successfully produced"
		rm ./produce.log
	else
		${echo_with_date} "[pulsar-client produce][x] Something wrong when using pulsar-client produce message."
		exit 1
	fi		

	# Comsume test
	${echo_with_date} "[pulsar-client consume] Now it's your turn to test. Please execute consume command like:"
	echo "bin/pulsar-client consume persistent://t1/ns1/test -n 10 -s \"consumer-test\"  -t \"Exclusive\" -p \"Earliest\""
}

installNodeExporter() {
	if check_port 9100
	then
		${echo_with_date} "9100 exist, skip install node-exporter."
	else
		${echo_with_date} "Start deploy node-exporter on all nodes."
		ssh2all "sudo wget $dispatch_host/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz -O /var/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz"
		ssh2all "cd /var; sudo tar zxf node_exporter-1.4.0-rc.0.linux-amd64.tar.gz"
		ssh2all "sudo rm /var/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz"
			
		ssh2all "wget $dispatch_host/node_exporter.service"
		ssh2all "sudo mv node_exporter.service /etc/systemd/system/"
		
		ssh2all "sudo systemctl daemon-reload"
		ssh2all "sudo systemctl start node_exporter"
		ssh2all "sudo systemctl enable node_exporter"		
	fi
}

testDispachHostNodeExporter() {

	curl -s $dispatch_host:9100 > node-exporter.test

	if [[ -f ./node-exporter.test && $(grep "Metrics" ./node-exporter.test) =~ "Metrics" ]]; then
		${echo_with_date} "[/][√] Your node-exporter is all ready."
		rm ./node-exporter.test
	else
		${echo_with_date} "[/][x] Your node-exporter service test failed. Please check it manually."
		exit 1
	fi
}

installProm() {

	if check_port 9090
	then
		${echo_with_date} "9090 exist, skip install prometheus."
	else
		cd $pulsar_base/
		wget -q $dispatch_host/prometheus-2.38.0.linux-amd64.tar.gz -O prometheus-2.38.0.linux-amd64.tar.gz
		tar zxf prometheus-2.38.0.linux-amd64.tar.gz 
		rm prometheus-2.38.0.linux-amd64.tar.gz
	
		prometheus_yml="$pulsar_base/prometheus-2.38.0.linux-amd64/prometheus.yml"
		wget -q $dispatch_host/prometheus.yml.template -O $prometheus_yml
	
		all_nodes_str=""
		bookie_nodes_str=""
		broker_nodes_str=""
		zookeeper_nodes_str=""
		
		oldIFS="$IFS"
		IFS="^^"
		
		length=${#all_nodes[@]}
		for (( j=0; j<${length}; j++ ));
		do
			all_nodes_str="$all_nodes_str        - '${all_nodes[$j]}:9100'\n"
		done
		
		length=${#bookie_nodes[@]}
		for (( j=0; j<${length}; j++ ));
		do
			bookie_nodes_str="$bookie_nodes_str        - '${bookie_nodes[$j]}:8000'\n"
		done
		
		length=${#broker_nodes[@]}
		for (( j=0; j<${length}; j++ ));
		do
			broker_nodes_str="$broker_nodes_str        - '${broker_nodes[$j]}:8000'\n"
		done
		
		length=${#zookeeper_nodes[@]}
		for (( j=0; j<${length}; j++ ));
		do
			zookeeper_nodes_str="$zookeeper_nodes_str        - '${zookeeper_nodes[$j]}:8000'\n"
		done
	
		IFS="$oldIFS"
		sed -i "s/{node_metrics}/$all_nodes_str/g" $prometheus_yml
		sed -i "s/{pulsar-bookie}/$bookie_nodes_str/g" $prometheus_yml
		sed -i "s/{pulsar-broker}/$broker_nodes_str/g" $prometheus_yml
		sed -i "s/{pulsar-zookeeper}/$zookeeper_nodes_str/g" $prometheus_yml
		sed -i "s/{pulsar-cluster-name}/$cluster_name/g" $prometheus_yml	

		cd $pulsar_base/prometheus-2.38.0.linux-amd64
		nohup ./prometheus --config.file=prometheus.yml --web.enable-lifecycle --storage.tsdb.retention=30d --storage.tsdb.retention.size=10GB >prometheus.log 2>&1 &	
		${echo_with_date} "[/][√] Your Prome is ready: $dispatch_host:9090"

	fi

}

installGrafana() {
	if check_port 3000
	then
		${echo_with_date} "3000 exist, skip install grafana."
	else
		cd $pulsar_base/
		wget -q $dispatch_host/grafana-enterprise-9.1.2.linux-amd64.tar.gz -O grafana-enterprise-9.1.2.linux-amd64.tar.gz
		tar zxf grafana-enterprise-9.1.2.linux-amd64.tar.gz 
		rm grafana-enterprise-9.1.2.linux-amd64.tar.gz
		cd grafana-9.1.2
		nohup bin/grafana-server web > grafana.log 2>&1 &
		${echo_with_date} "[/][√] Your Grafana is ready. Please login using admin/admin and reset it: $dispatch_host:3000"
	fi
}


#####################################################
##########          Start deploy         ############

# Prepare Client Node
startHttpd
initClientTools
copyDeployTools

# JDK and prepare tarball
installJDK $needInstallJDK11
dispatchPkgs

# Deploy and start Zookeeper
initZookeeperConf
startAllZookeepers.sh

# Init Pulsar metadata in zookeeper
initPulsarMetadata

# Deploy and start Booies
initBookieConf
startAllBookies.sh
testBookies

# Deploy and start Brokers
initBrokerConf
startAllBrokers.sh
replaceClientConf
crateTenantAndNamespace
testBrokers

# Deploy monitors 
installNodeExporter
testDispachHostNodeExporter
installProm
installGrafana

printHello

