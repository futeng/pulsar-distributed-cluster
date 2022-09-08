# Title: Show HOST basic informations
# Author: tydic.com
# Date: 2017/05/21
# 1. 内核
#echo "Core: "`uname -a`
KERNAL=`uname -r`
# 2. 操作系统
#echo "OS: "`head -n 1 /etc/issue`
OS_RELEASE=`cat /etc/redhat-release`
# 3. CPU信息
#echo "CPU model: "`cat /proc/cpuinfo | grep "model name" | head -1 `
CPU_PROCESSOR=`cat /proc/cpuinfo | grep processor | wc -l`
# 4. 内存
MEM_TOTAL_KB=`grep MemTotal /proc/meminfo | awk '{print $2}'`
echo $MEM_TOTAL
#echo `grep MemFree /proc/meminfo`
# 5. 磁盘信息
disk_total() {
d_t=$(fdisk -l | grep -n '磁盘' |grep -n '字节'|awk '{print $4}' |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}')
if [ ${d_t} -eq 0 ];then
d_t2=$(fdisk -l | grep -n 'Disk' |grep -n 'bytes'|awk '{print $5}'|awk 'BEGIN{sum=0}{sum+=$1}END{print sum}')
echo -e "${d_t2}"
#echo -e "磁盘总空间大小为：${d_t2}B"
else
echo -e "${d_t}"
#echo -e "磁盘总空间大小为：${d_t}B"
fi
}
dt=`disk_total`
# 6. 主机名称
HOSTNAME=`hostname`
# 7. IP地址
IP=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
echo "$HOSTNAME | $OS_RELEASE | $KERNAL | $CPU_PROCESSOR | $MEM_TOTAL_KB | $dt"
