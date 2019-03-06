#!/bin/bash

sudo apt-get update

# Install Kibana and Grafana
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
echo "deb https://packagecloud.io/grafana/stable/debian/ stretch main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo curl https://packagecloud.io/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y --allow-unauthenticated kibana grafana
sudo mv /tmp/kibana.yml /etc/kibana/
sudo sed -i 's/#server.host: "localhost"/server.host: '"${LOCAL_IPV4}"'/g' /etc/kibana/kibana.yml
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo mkdir /var/lib/grafana/dashboards
sudo mv /tmp/prometheus_datasource.yaml /etc/grafana/provisioning/datasources/
sudo mv /tmp/grafana_system_dashboard.json /var/lib/grafana/dashboards/
sudo mv /tmp/prometheus_dashboards.yaml /etc/grafana/provisioning/dashboards/
sudo systemctl restart kibana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

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

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

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


cat << EOCSU >/etc/consul.d/kibana.json
{
  "service": {
    "name": "kibana",
    "tags": ["kibana"], 
    "port": 5601, 
    "check": {
	    "id": "kibana-health",
        "name": "kibana TCP health",
        "tcp": "${LOCAL_IPV4}:5601",
        "interval": "10s",
		"timeout": "1s"
        }
    }
}
EOCSU


cat << EOCSU >/etc/consul.d/grafana.json
{
  "service": {
    "name": "grafana",
    "tags": ["grafana"], 
    "port": 3000, 
    "check": {
	    "id": "grafana-health",
        "name": "grafana TCP health",
        "tcp": "localhost:3000",
        "interval": "10s",
		"timeout": "1s"
        }
    }
}
EOCSU


cat << EOCSU >/etc/consul.d/kibana-grafana-metrics.json
{
  "service": {
    "name": "kibana-grafana-metrics",
    "port": 9100,
    "tags":  ["kibana-grafana-metrics", "metrics"],
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

## Kibana - Create index pattern and dashboard
curl -f -XPOST -H 'Content-Type: application/json' -H 'kbn-xsrf: anything' "http://${LOCAL_IPV4}:5601/api/saved_objects/index-pattern/filebeat-*" '-d{"attributes":{"title":"filebeat-*","timeFieldName":"@timestamp"}}'
curl -u elastic:elasticsearch.service.consul -k -XPOST "http://${LOCAL_IPV4}:5601/api/kibana/dashboards/import" -H 'Content-Type: application/json' -H "kbn-xsrf: true" -d @/tmp/kibana/kibana_dashboard.json
