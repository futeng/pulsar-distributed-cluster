# pulsar-distributed-cluster

Script to deploy pulsar in distributed cluster.

1. The script requires a dispatch machine:
	- to deploy the httpd service for installation package, script, and configuration distribution;
	- install the Prometheus and Grafana services and configured as a Pulsar Client.
2. This repo do not contains all the installation packages, please refer to the Get Ready section for manual download.
3. Different clusters have different environment information, especially the data directory, and need to modify the `depoly.sh` script manually.


## Get Ready

If you need to install the JDK, please replace the package name in the script of `pkgs/install-jdk11.sh`.

All installation packages need to be downloaded manually and placed in the `deploy-pulsar/pkgs` directory.

The following is the download address of the installation package used by the current script:

```shell
wget https://github.com/streamnative/pulsar/releases/download/v2.10.1.7/apache-pulsar-2.10.1.7-bin.tar.gz
wget https://github.com/streamnative/kop/releases/download/v2.10.1.7/pulsar-protocol-handler-kafka-2.10.1.7.nar
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0-rc.0/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
wget https://github.com/prometheus/prometheus/releases/download/v2.38.0/prometheus-2.38.0.linux-amd64.tar.gz
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-9.1.2.linux-amd64.tar.gz
```

## Guides

```shell

# STEP 1. clone pulsar-distributed-cluster
git clone https://github.com/futeng/pulsar-distributed-cluster.git

# STEP 2. Download pkgs
cd pkgs

wget https://github.com/streamnative/pulsar/releases/download/v2.10.1.7/apache-pulsar-2.10.1.7-bin.tar.gz
wget https://github.com/streamnative/kop/releases/download/v2.10.1.7/pulsar-protocol-handler-kafka-2.10.1.7.nar
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0-rc.0/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
wget https://github.com/prometheus/prometheus/releases/download/v2.38.0/prometheus-2.38.0.linux-amd64.tar.gz
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-9.1.2.linux-amd64.tar.gz

cd ..
# cp jdk manually
# cp jdk-11.0.15.1_linux-x64_bin.tar.gz pkgs/

# STEP 3. Modify the 'Custom variables' based on your own environment.

# The following default configuration:

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

# STEP 4. Modify the Bookie data directory
# Please search function initBookieConf()

# **You need to change everything in this function that is related to directories. **

# STEP 5. One click to depoly a distribued pulsar cluster
./deploy.sh 

```