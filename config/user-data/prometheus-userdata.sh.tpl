#!/bin/bash

# Install Prometheus
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.6.0/prometheus-2.6.0.linux-amd64.tar.gz
tar xvf prometheus-2.6.0.linux-amd64.tar.gz
sudo cp prometheus-2.6.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.6.0.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo cp -r prometheus-2.6.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.6.0.linux-amd64/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus
rm -rf prometheus-2.6.0.linux-amd64.tar.gz prometheus-2.6.0.linux-amd64
echo '[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/prometheus.service
sudo chown root:root /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sleep 10
sudo systemctl enable prometheus
#sudo mv /tmp/prometheus.yml /etc/prometheus/
echo "scrape_configs:
  - job_name: 'Node Exporter'
    scrape_interval: 5s
    ec2_sd_configs:
      - region: 'us-west-2'
        access_key: '${EC2_ACCESS_KEY}'
        secret_key: '${EC2_SECRET_KEY}'
        port: 9100
    consul_sd_configs:
    - server: 'consul-server.service.consul:8500'
      datacenter: opsschool
#     services: [dummy_exporter]
    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex:         ',(metrics),'
      target_label:  'tags'
    - source_labels: ['__meta_consul_node']
      target_label: 'node'
    - source_labels: ['__meta_consul_service']
      target_label: 'service'
    - source_labels: ['__meta_ec2_tag_Name']
      target_label: 'instance'
    - source_labels: ['__meta_ec2_availability_zone']
      target_label: 'zone'
    - source_labels: ['__meta_ec2_instance_type']
      target_label: 'ec2_type'"  > /etc/prometheus/prometheus.yml
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
sudo systemctl start prometheus

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


cat << EOCSU >/etc/consul.d/prometheus.json
{"service": {
    "name": "prometheus",
    "tags": ["prometheus"], 
    "port": 9090, 
    "check": {
	    "id": "prometheus-health",
        "name": "prometheus TCP health",
        "tcp": "localhost:9090",
        "interval": "10s",
		"timeout": "1s"
        }
    }
}
EOCSU


cat << EOCSU >/etc/consul.d/prometheus-metrics.json
{
  "service": {
    "name": "prometheus-metrics",
    "port": 9100,
    "tags":  ["prometheus-metrics", "metrics"],
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