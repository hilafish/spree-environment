#/bin/bash
sudo chmod +x /tmp/mysql/mysql-master-userdata.sh
sudo /tmp/mysql/mysql-master-userdata.sh
sudo mysql -u root spree < /tmp/mysql/spree_all.sql
