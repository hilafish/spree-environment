#!/bin/bash

# This script is intended to install Consul client
# on Ubuntu 16.04 Xenial managed by SystemD
# including docker and DnsMasq for *.service.consul DNS resolving
# 
# Script assume that instance is running in AWS and have "ec2:DescribeInstances" permissions in IAM Role

set -x
export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive
export DATACENTER_NAME="OpsSchool"

sudo rm -rf /var/lib/dpkg/lock
sudo rm -rf /var/lib/dpkg/lock-frontend
sudo rm -rf /var/cache/apt/archives/lock
sudo rm -rf /var/cache/debconf/config.dat

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
    dnsmasq \
	gdebi

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


cat << EOCSU >/etc/consul.d/mysql-master.json
{
  "service": {
    "name": "mysql-master",
    "tags": ["mysql-master"], 
    "port": 3306, 
    "check": {
	    "id": "mysql-master-health",
        "name": "mysql-master TCP health",
        "tcp": "${LOCAL_IPV4}:3306",
        "interval": "10s",
		"timeout": "1s"
        }
    }
}
EOCSU


cat << EOCSU >/etc/consul.d/mysql-master-metrics.json
{
  "service": {
    "name": "mysql-master-metrics",
    "port": 9100,
    "tags":  ["mysql-master-metrics", "metrics"],
     "check": {
        "id": "node_exporter_health_check",
        "name": "node_exporter_port_check",
        "tcp": "localhost:9100",
        "interval": "10s",
        "timeout": "1s"
    }
  }
}
EOCSU

systemctl daemon-reload
systemctl start consul


# Install and define mysql
sudo apt-get update
sudo rm -rf /var/lib/dpkg/lock
sudo rm -rf /var/lib/dpkg/lock-frontend
sudo rm -rf /var/cache/apt/archives/lock
sudo rm -rf /var/cache/debconf/config.dat

wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo apt-get update
export MYSQL_ROOT_PASSWORD=
export DEBIAN_FRONTEND=noninteractive
echo "percona-server-server-5.7 percona-server-server-5.7/root-pass password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "percona-server-server-5.7 percona-server-server-5.7/re-root-pass password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
sudo apt install -y percona-server-server-5.7 percona-server-client-5.7
rm -rf percona-release_latest.$(lsb_release -sc)_all.deb
sudo bash -c "echo bind-address = ${LOCAL_IPV4} >> /etc/mysql/percona-server.conf.d/mysqld.cnf"
sudo bash -c "echo server-id=1 >> /etc/mysql/percona-server.conf.d/mysqld.cnf"
sudo bash -c "echo log-bin=/var/lib/mysql/mysql-bin >> /etc/mysql/percona-server.conf.d/mysqld.cnf"
sudo service mysql restart 
sleep 30
sudo mysql -e "CREATE DATABASE spree;"
sudo mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '11111';" 
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';"


# Install Node Exporter
sudo useradd --no-create-home --shell /bin/false node_exporter
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz
tar xzvf node_exporter-0.16.0.linux-amd64.tar.gz
sudo mv node_exporter-0.16.0.linux-amd64/node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-0.16.0.linux-amd64.tar.gz node_exporter-0.16.0.linux-amd64
echo '[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter


# Install filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.6.1-amd64.deb
sudo dpkg -i filebeat-6.6.1-amd64.deb
sleep 60
echo 'filebeat.inputs:
- type: log
  paths:
    - /var/log/syslog

output.elasticsearch:
  hosts: ["elasticsearch.service.consul:9200"]' > /etc/filebeat/filebeat.yml
sudo chown root:root /etc/filebeat/filebeat.yml
sudo service filebeat restart