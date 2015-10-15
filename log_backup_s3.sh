#!/bin/bash
#set -xv
# Upload logs modified 2 days ago
DIR="/log/"
DIR_2_DAYS_AGO=`date +%d_%b_%Y --date='2 days ago'`
echo "creating a directory /tmp/$DIR_2_DAYS_AGO"
mkdir -p /tmp/$DIR_2_DAYS_AGO
echo "creating a directory /root/scripts/http_move_log"
mkdir -p /root/scripts/http_move_log
LOG_PATH="/root/scripts/http_move_log"
LOG_FILE="$LOG_PATH/`date +%F`_log.txt"

find $DIR -maxdepth 1 -type f -mtime +3 -name "hu-embrace*" > /tmp/log_list
for f_name in `cat /tmp/log_list`
do
 if [ `file $f_name | cut -d: -f2 | awk '{print $1}'` == "gzip" ]; then
        echo "Copying the file $f_name to /tmp/$DIR_2_DAYS_AGO/"
        cp -pvr $f_name /tmp/$DIR_2_DAYS_AGO/
        echo "Upload the file to s3://<BUCKET_NAME>/$DIR_2_DAYS_AGO/"
        aws s3 --recursive cp --storage-class STANDARD_IA /tmp/$DIR_2_DAYS_AGO/ s3://<BUCKET_NAME>/$DIR_2_DAYS_AGO/
        echo "Removing the file $f_name"
        rm -vf $f_name
        echo "Removing file /tmp/$DIR_2_DAYS_AGO/`basename $f_name`"
        rm -vf /tmp/$DIR_2_DAYS_AGO/`basename $f_name`
 else
        echo "Compressing the file."
        gzip -v -9 -c $f_name > /tmp/$DIR_2_DAYS_AGO/`basename $f_name`.gz
        echo "removing $f_name"
        rm -vf $f_name
        echo "Upload the file to s3://<BUCKET_NAME>/$DIR_2_DAYS_AGO/"
        aws s3 --recursive cp --storage-class STANDARD_IA /tmp/$DIR_2_DAYS_AGO/ s3://<BUCKET_NAME>/$DIR_2_DAYS_AGO/
        echo "removing /tmp/$DIR_2_DAYS_AGO/`basename $f_name`.gz"
        rm -vf /tmp/$DIR_2_DAYS_AGO/`basename $f_name`.gz
 fi
done >> $LOG_FILE
echo "Removing the directory /tmp/$DIR_2_DAYS_AGO/" >> $LOG_FILE
rm -rvf /tmp/$DIR_2_DAYS_AGO/ >> $LOG_FILE

aws s3 ls s3://<BUCKET_NAME>/`date +%d_%b_%Y --date='3 weeks ago'`
if [ $? -eq 0 ]; then
        echo "Deleting 3 weeks old logs"
        aws s3 rm s3://<BUCKET_NAME>/`date +%d_%b_%Y --date='3 weeks ago'`/
fi >> $LOG_FILE
