apiVersion: v1
data:
  .dockerconfigjson: ${K8S_SECRET}
kind: Secret
metadata:
  name: registrypullsecret
type: kubernetes.io/dockerconfigjson
