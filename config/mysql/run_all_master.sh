#/bin/bash
sudo chmod +x /tmp/mysql/mysql-master-userdata.sh
sudo /tmp/mysql/mysql-master-userdata.sh
sudo mysql -u root spree < /tmp/mysql/spree_all.sql
sudo mysql -u root spree <<-EOSQL &
	GRANT REPLICATION SLAVE ON *.* TO 'root'@'%' IDENTIFIED BY '11111';
	FLUSH PRIVILEGES;
	FLUSH TABLES WITH READ LOCK;
	DO SLEEP(3600);
EOSQL
