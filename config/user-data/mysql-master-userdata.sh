#!/bin/bash
#
# This script is intended to install Consul client
# on Ubuntu 16.04 Xenial managed by SystemD
# including docker and DnsMasq for *.service.consul DNS resolving
# 
# Script assume that instance is running in AWS and have "ec2:DescribeInstances" permissions in IAM Role

set -x
export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive
export DATACENTER_NAME="opsschool"


#Bringing the Information
echo "Determining local IP address"
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
echo "Using ${LOCAL_IPV4} as IP address for configuration and anouncement"


apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    jq \
    unzip \
    dnsmasq


sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update


echo "Enabling *.service.consul resolution system wide"
cat << EODMCF >/etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600
EODMCF

systemctl restart dnsmasq

CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
CONSUL_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')

cd /tmp/

echo "Fetching Consul version ${CONSUL_VERSION} ..."
curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
echo "Installing Consul version ${CONSUL_VERSION} ..."
unzip consul.zip
chmod +x consul
mv consul /usr/local/bin/consul

echo "Configuring Consul"
mkdir -p /var/lib/consul /etc/consul.d

cat << EOCCF >/etc/consul.d/agent.hcl
client_addr =  "0.0.0.0"
recursors =  ["127.0.0.1"]
bootstrap =  false
datacenter = "${DATACENTER_NAME}"
data_dir = "/var/lib/consul"
enable_syslog = true
log_level = "DEBUG"
retry_join = ["provider=aws tag_key=Name tag_value=consul-server"]
advertise_addr = "${LOCAL_IPV4}"
EOCCF


cat << EOCSU >/etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target
[Service]
LimitNOFILE=65536
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Type=notify
[Install]
WantedBy=multi-user.target
EOCSU


sudo echo '{"service": {"name": "mysql_master", "tags": ["mysql", "mysql_master"], "port": 3306}}' >> /etc/consul.d/mysql_master.json

systemctl daemon-reload
systemctl start consul


# Install and define mysql
apt-get update
apt-get install -y curl jq
apt-get install -y gdebi
cd /opt
wget  https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.24-27/binary/debian/trusty/x86_64/percona-server-client-5.7_5.7.24-27-1.trusty_amd64.deb
wget  https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.24-27/binary/debian/trusty/x86_64/percona-server-common-5.7_5.7.24-27-1.trusty_amd64.deb
wget  https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.24-27/binary/debian/trusty/x86_64/percona-server-server-5.7_5.7.24-27-1.trusty_amd64.deb
wget  https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.24-27/binary/debian/trusty/x86_64/libperconaserverclient20_5.7.24-27-1.trusty_amd64.deb
apt-get update
export DEBIAN_FRONTEND=noninteractive;
gdebi -n percona-server-common-5.7_5.7.24-27-1.trusty_amd64.deb 
gdebi -n libperconaserverclient20_5.7.24-27-1.trusty_amd64.deb 
gdebi -n percona-server-client-5.7_5.7.24-27-1.trusty_amd64.deb 
gdebi -n percona-server-server-5.7_5.7.24-27-1.trusty_amd64.deb  
sudo mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '11111';" 
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';"
sudo mysql -e "CREATE DATABASE spree;"
EOF 
#### need to bind address here in mysqld.cnf


# Install filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.5.4-amd64.deb
sudo dpkg -i filebeat-6.5.4-amd64.deb
sleep 60
echo 'filebeat.inputs:
- type: log
  paths:
    - /var/log/messages

output.logstash:
  hosts: ["logstash.service.consul:5044"]' > /etc/filebeat/filebeat.yml
sudo chown root:root /etc/filebeat/filebeat.yml
sudo service filebeat restart