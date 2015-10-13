#!/bin/bash

### Username and Password should be stored in /root/.my.cnf file.
### Contents of /root/.my.cnf should be as below (without hash)
# [client]
# user=<username>
# password=<password>

DATE_TODAY=`date +%F`
DATE_TWO_WEEKS_AGO=`date +%F -d '2 week ago'`
DB_BKP_PATH=/Backup/Database
DATA_BKP_PATH=/Backup/Data
DB_BACKUP_LOCATION=/Backup/Database/$DATE_TODAY
DATA_BACKUP_LOCATION=/Backup/Data/$DATE_TODAY
LOG_LOCATION=/Backup/logs
LOG_FILE=$LOG_LOCATION/$DATE_TODAY-log.txt

# Create the backup location and logs directory
mkdir -p $LOG_LOCATION $DB_BACKUP_LOCATION $DATA_BACKUP_LOCATION

for DATABASE in confluencedb jiradb mysql; do
        # Create the dump of database. The Option "-B" is for database name, "-R" is to include stored procedures and functions.
        echo "$(date +%T\_%F) - Executing: 'mysqldump -v -R -B $DATABASE > $DB_BACKUP_LOCATION/$DATE_TODAY.$DATABASE.sql'"
        mysqldump -v -R -B $DATABASE > $DB_BACKUP_LOCATION/$DATE_TODAY.$DATABASE.sql

        # Sleep for few seconds
        sleep 2

        # Compress the database dump
        echo "$(date +%T\_%F) - Executing: 'gzip -v $DB_BACKUP_LOCATION/$DATE_TODAY.$DATABASE.sql'"
        gzip -v $DB_BACKUP_LOCATION/$DATE_TODAY.$DATABASE.sql
done >> $LOG_FILE

# Remove 15 days old database backup file
if [ -e $DB_BKP_PATH/$DATE_TWO_WEEKS_AGO ]; then
        echo ""
        echo "Removing 2 weeks old database backup."
        rm -vf $DB_BKP_PATH/$DATE_TWO_WEEKS_AGO
fi >> $LOG_FILE

# Backup the data
echo "$(date +%T\_%F) - Executing: 'tar -cpzf $DATA_BACKUP_LOCATION/$DATE_TODAY-opt_atlassian.tar.gz /opt/atlassian'" >> $LOG_FILE
tar -cpzf $DATA_BACKUP_LOCATION/$DATE_TODAY-opt_atlassian.tar.gz /opt/atlassian

echo "$(date +%T\_%F) - Executing: 'tar -cpzf $DATA_BACKUP_LOCATION/$DATE_TODAY-var_atlassian.tar.gz /var/atlassian'" >> $LOG_FILE
tar -cpzf $DATA_BACKUP_LOCATION/$DATE_TODAY-var_atlassian.tar.gz /var/atlassian

# Remove 15 days Data backup file.
if [ -e $DATA_BKP_PATH/$DATE_TWO_WEEKS_AGO ]; then
        echo ""
        echo "Removing 2 weeks old data backup."
        rm -vf $DATA_BKP_PATH/$DATE_TWO_WEEKS_AGO
fi >> $LOG_FILE

# Send an email once the backup is done.
mailx -s "Confluence & Jira Backup Status on `hostname -A` | $DATE_TODAY" <email_id> < $LOG_FILE
