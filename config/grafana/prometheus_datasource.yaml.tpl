apiVersion: 1
datasources:
 - name: Prometheus
   type: prometheus
   access: proxy
   orgId: 1
   url: http://${prometheus_private_ip}:9090
   isDefault: yes