#/bin/bash

sudo chmod +x /tmp/mysql/mysql-slave-userdata.sh
sudo /tmp/mysql/mysql-slave-userdata.sh


#title			: replication-start.sh
#description	: This script automates the process of starting a Mysql Replication on 1 master node and N slave nodes.
#author		 	: Nicolas Di Tullio (With Changes by Hila F)
#date			: 20190302
#version		: 0.2  
#usage			: bash mysql_replication_autostart.sh
#bash_version	: 4.3.11(1)-release
#=============================================================================

#
# Requirements for this script to work:
# * The Mysql user defined by the $USER variable must:
#   - Have the same password $PASS on all mysql instances
#   - Be able to grant replication privileges
#   - All hosts must be able to receive mysql commands remotely from the node executing this script
#

DB=spree
DUMP_FILE="/tmp/mysql/spree_all.sql"

USER=root
PASS=11111

LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")

MASTER_HOST=mysql-master.service.consul
SLAVE_HOST=${LOCAL_IPV4}


# Take note of the master log position at the time of dump
MASTER_STATUS=$(sudo mysql -h $MASTER_HOST "-u$USER" "-p$PASS" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
LOG_FILE=$(echo $MASTER_STATUS | cut -f1 -d ' ')
LOG_POS=$(echo $MASTER_STATUS | cut -f2 -d ' ')
echo "  - Current log file is $LOG_FILE and log position is $LOG_POS"


# Import the dump into slaves and activate replication with
# binary log file and log position obtained from master.
##

echo "SLAVE: $SLAVE_HOST"
echo " - Creating database copy"
sudo mysql -h $SLAVE_HOST "-u$USER" "-p$PASS" -e "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB;"
#scp $DUMP_FILE $SLAVE_HOST:$DUMP_FILE >/dev/null
sudo mysql -h $SLAVE_HOST "-u$USER" "-p$PASS" $DB < $DUMP_FILE

echo "  - Setting up slave replication"
sudo mysql -h $SLAVE_HOST "-u$USER" "-p$PASS" $DB <<-EOSQL &
	STOP SLAVE;
	CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',
	MASTER_USER='$USER',
	MASTER_PASSWORD='$PASS',
	MASTER_LOG_FILE='$LOG_FILE',
	MASTER_LOG_POS=$LOG_POS;
	START SLAVE;
EOSQL
# Wait for slave to get started and have the correct status
sleep 2
# Check if replication status is OK
SLAVE_OK=$(sudo mysql -h $SLAVE_HOST "-u$USER" "-p$PASS" -e "SHOW SLAVE STATUS\G;" | grep 'Waiting for master')
if [ -z "$SLAVE_OK" ]; then
	echo "  - Error ! Wrong slave IO state."
else
	echo "  - Slave IO state OK"
fi

