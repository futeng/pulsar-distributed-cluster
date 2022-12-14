#!/bin/bash

. bin/cluster.sh

stopAllBookies.sh
stopAllBrokers.sh
stopAllZookeepers.sh

ps -ef |grep prometheus.yml | grep -v "grep" | awk '{print $2}' | xargs kill -9
ps -ef |grep grafana-server | grep -v "grep" | awk '{print $2}' | xargs kill -9

# delete bookie data
go2bookies "sudo rm -rf {$bk_journalDirectory,$bk_ledgerDirectories}"
# 删除 zk 数据
go2zookeepers "sudo rm -rf $zk_data_dir"

# 删除 node 目录
go2all "rm -rf $pulsar_home"

rm -rf $pulsar_base/grafana-9.1.2
rm -rf $pulsar_base/prometheus-2.38.0.linux-amd64
rm $pulsar_base/httpd.conf
rm $pulsar_base/yum.log
rm $pulsar_base/install-jdk11.sh
