controller:
  image:
    tag: {{ or .Release.Store.v "v1.11.2" }}  # https://explore.ggcr.dev/?repo=registry.k8s.io/ingress-nginx/controller 
  admissionWebhooks:
    enabled: false
