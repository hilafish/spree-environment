#!/bin/bash
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
sudo mv /tmp/grafana_dashboard.json /var/lib/grafana/dashboards/
sudo mv /tmp/prometheus_dashboards.yaml /etc/grafana/provisioning/dashboards/
dummy1_hostname=$(echo '${dummy_exporter-0}' | awk '{split($0,a,"."); print a[1]}')
dummy2_hostname=$(echo '${dummy_exporter-1}' | awk '{split($0,a,"."); print a[1]}')
sudo sed -i "s/dummy-exporter-1/$${dummy1_hostname}/g" /var/lib/grafana/dashboards/grafana_dashboard.json
sudo sed -i "s/dummy-exporter-2/$${dummy2_hostname}/g" /var/lib/grafana/dashboards/grafana_dashboard.json
sudo systemctl restart kibana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sleep 30
curl -f -XPOST -H 'Content-Type: application/json' -H 'kbn-xsrf: anything' "http://${LOCAL_IPV4}:5601/api/saved_objects/index-pattern/filebeat-*" '-d{"attributes":{"title":"filebeat-*","timeFieldName":"@timestamp"}}'
curl -u elastic:${elastic_search_private_ip} -k -XPOST "http://${LOCAL_IPV4}:5601/api/kibana/dashboards/import" -H 'Content-Type: application/json' -H "kbn-xsrf: true" -d @/tmp/kibana_dashboard.json

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

