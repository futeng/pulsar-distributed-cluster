#!/usr/bin/env bash
# Script to deploy pulsar in distributed cluster.
# More info https://github.com/futeng/pulsar-distributed-cluster
# Copyright (C) 2022 stremnative.io (Please feel free to contact me : teng.fu@streamnative.io)
# Permission to copy and modify is granted under the Apache 2.0 license
# Last revised 22/11/2022

#####################################################
################# Custom variables ##################

needInstallJDK11="false"
needInitializeClusterMetadata="true"

# 如果需要 pem 文件登录，则 need 置为 true，且 pem 文件位置要填写，主要不要更改 ssh -i 的前缀
ssh_cmd="ssh"
#ssh_cmd="ssh -i /home/pulsar/.ssh/pulsar-cloud.pem"

all_nodes=("vm11" "vm12" "vm13")
bookie_nodes=("vm11" "vm12" "vm13")
zookeeper_nodes=("vm11" "vm12" "vm13")
broker_nodes=("vm12" "vm13")
dispatch_host="vm11"

# The user used by the deployment and have to get the sudo privilege.
user="futeng"
pulsar_base="/home/futeng"
pulsar_deploy_dir="pulsar-node"
pulsar_home=$pulsar_base/$pulsar_deploy_dir


# Pulsar cluster name 
cluster_name="sn"

# tarball in pkgs dir
pulsar_tarball="apache-pulsar-2.10.1.7-bin.tar.gz"
pulsar_version="apache-pulsar-2.10.1.7"


# Zookeeper 
zk_data_dir="/data/pulsar/zkdata"
zk_admin_serverPort="9990"
zk_metricsProvider_httpPort="7000"
zk_clientPort="2181"
zk_2888="2888"
zk_3888="3888"

# Bookies
bk_journalDirectory="/data/pulsar/journal"
bk_ledgerDirectories="/data/pulsar/ledger"

# Brokers
broker_managedLedgerDefaultEnsembleSize="2"
broker_managedLedgerDefaultWriteQuorum="2"
broker_managedLedgerDefaultAckQuorum="2"
