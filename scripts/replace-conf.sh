#!/usr/bin/env bash
BINDIR=$(dirname "$0")
export PULSAR_HOME=`cd -P $BINDIR/..;pwd`

# i.e broker.conf bookkeeper.conf zookkeeper.conf
CONF_FILE=$1
UPDATE_FILE=$2

DEST="$PULSAR_HOME/conf/$CONF_FILE"
BAK_DIR="$PULSAR_HOME/conf.bak"
# BAK_DIR already exists by deploy.sh 
# mkdir -p $BAK_DIR

cp $DEST $BAK_DIR/$CONF_FILE-before-replacedBy-$UPDATE_FILE

echo "" >> $DEST
echo "update using file: $UPDATE_FILE"
echo "" >> $DEST

cat $PULSAR_HOME/conf.version/$UPDATE_FILE | while read line
do
  #echo "File:${line}"
  parameter_name=${line%=*}
  #parameter_value=${line#*=}
  #echo $parameter_name
  #echo $parameter_value
  sed -i "/$parameter_name/d" $DEST
  echo $line >> $DEST
done

echo ""  >> $DEST
