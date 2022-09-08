stopAllBookies.sh
stopAllBrokers.sh
stopAllZookeepers.sh
ps -ef |grep prometheus.yml | grep -v "grep" | awk '{print $2}' | xargs kill -9
ps -ef |grep grafana-server | grep -v "grep" | awk '{print $2}' | xargs kill -9


# 删除 Bookie 数据
ssh2bookies "sudo rm -rf /journal01 /journal02 /ledger01 /ledger02"
# 删除 zk 数据
ssh2zookeepers "sudo rm -rf /zkdata"
# 删除 node 目录
ssh2all "rm -rf /home/pulsar/pulsar-node"
rm -rf /home/pulsar/grafana-9.1.2
rm -rf /home/pulsar/prometheus-2.38.0.linux-amd64
rm -rf /home/pulsar/*.conf
rm -rf /home/pulsar/*.sh
rm -rf /home/pulsar/*.log
