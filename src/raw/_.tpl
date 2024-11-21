{{- define "raw_releases" }}
{{- $V := $.V }}
  - <<: [*default, *demo] # example yaml sugar (namespace as tag without new row)
    name: nginx-raw
    chart: charts/app
    values: [src/raw/nginx.tpl] # example yaml sugar for simple list without new row
    store: { v: {{ or $V "latest" }} } # example set version with support git-lab ci
    tags: [nginx-raw, demo]

repositories:
  - name: ingress-nginx
    url: https://kubernetes.github.io/ingress-nginx
{{- end }}
