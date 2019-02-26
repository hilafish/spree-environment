#!/bin/bash
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
  - job_name: 'consul_services'
    scrape_interval: 5s
    consul_sd_configs:
    - server: '${consul_server_private_ip}:8500'
      datacenter: opsschool
      services: [dummy_exporter]
    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex:         ',(dummy_exporter|dummy-exporter),'
      target_label:  'app'
    - source_labels: ['__meta_consul_node']
      target_label: instance
    - source_labels: ['__meta_consul_service']
      target_label: service" > /etc/prometheus/prometheus.yml
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

