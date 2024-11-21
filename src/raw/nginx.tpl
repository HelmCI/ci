nameOverride: {{ .Release.Name }}
image:
  tag: {{ or .Release.Store.v "1.27.2" }} # https://hub.docker.com/_/nginx
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  hosts:
    - paths:
        - path: /{{ .Release.Name }}/(.*) # http://localhost/nginx-raw/
          pathType: Prefix
files:
  /usr/share/nginx/html:
    index.html: |
{{ readFile "README.md" | indent 6 }}
