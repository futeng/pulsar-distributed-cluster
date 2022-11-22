#!/bin/bash 
# 先清除
swapoff -a
# 临时关闭
echo 0 > /proc/sys/vm/swappiness
# 永久生效
echo "vm.swappiness=0" >> /etc/sysctl.conf 
sysctl -p
