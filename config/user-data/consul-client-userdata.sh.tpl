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
sudo apt-get install -y docker-ce

echo "Configuring Docker to use local DNSMasq for DNS resolution (Enabling *.service.consul resolutions inside containers)"
cat << EODDCF >/etc/docker/daemon.json
{
  "dns": ["${LOCAL_IPV4}"]
}
EODDCF

systemctl restart docker.service

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



sudo docker pull hila3000/dummy_exporter:3.0
sudo docker run -v /tmp:/tmp -it -d -p 65433:65433 hila3000/dummy_exporter:3.0 start
sleep 10
curl http://localhost:65433

sudo echo '{"service": {"name": "dummy_exporter", "tags": ["dummy-exporter"], "port": 65433}}' >> /etc/consul.d/dummy-exporter.json

systemctl daemon-reload
systemctl start consul

# remote exec originally
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.5.4-amd64.deb
sudo dpkg -i filebeat-6.5.4-amd64.deb
sleep 60
echo 'filebeat.inputs:
- type: log
  paths:
    - /tmp/*.log

output.elasticsearch:
  hosts: ["${elastic_search_private_ip}:9200"]' > /etc/filebeat/filebeat.yml
sudo chown root:root /etc/filebeat/filebeat.yml
sudo service filebeat restart