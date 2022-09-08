#!/usr/bin/env bash

# i.e broker.conf bookkeeper.conf zookkeeper.conf
CONF_FILE=$1
UPDATE_FILE=$2

DEST="/home/pulsar/pulsar-node/conf/$CONF_FILE"
BAK_DIR="/home/pulsar/pulsar-node/conf.bak"
mkdir -p $BAK_DIR

cp $DEST $BAK_DIR/$CONF_FILE-before-replaceby-$UPDATE_FILE

echo "" >> $DEST
echo "update using file: $UPDATE_FILE"
echo "" >> $DEST

cat $UPDATE_FILE | while read line
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
