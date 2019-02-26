#!/bin/bash
#
# This script is intended to install Consul
# on Ubuntu 16.04 Xenial managed by SystemD
# including DnsMasq for *.service.consul DNS resolving

set -i
export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive
export DATACENTER_NAME="opsschool"

echo "Determining local IP address"
LOCAL_IPV4=$(hostname --ip-address)
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

cat << EODMCF >/etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600
EODMCF

systemctl restart dnsmasq

echo "Checking latest Consul version..."
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

cat << EOCCF >/etc/consul.d/server.hcl
advertise_addr = "${LOCAL_IPV4}"
bootstrap_expect = 3
client_addr =  "0.0.0.0"
data_dir = "/var/lib/consul"
datacenter = "${DATACENTER_NAME}"
enable_syslog = true
log_level = "DEBUG"
recursors =  ["127.0.0.1"]
retry_join = ["provider=aws tag_key=Name tag_value=consul-server"]
server = true
ui = true
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


systemctl daemon-reload
systemctl start consul


# Install Filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.5.4-amd64.deb
sudo dpkg -i filebeat-6.5.4-amd64.deb
sleep 60
echo 'filebeat.inputs:
- type: log
  paths:
    - /tmp/*.log

output.elasticsearch:
  hosts: ["elastic.service.consul:9200"]' > /etc/filebeat/filebeat.yml
sudo chown root:root /etc/filebeat/filebeat.yml
sudo service filebeat restart


# Install Node Exporter
sudo useradd --no-create-home --shell /bin/false node_exporter
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz
tar xzvf node_exporter-0.16.0.linux-amd64.tar.gz
sudo mv node_exporter-0.16.0.linux-amd64/node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-0.16.0.linux-amd64.tar.gz node_exporter-0.16.0.linux-amd64
sudo echo '[Unit]
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
