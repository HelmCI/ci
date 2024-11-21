{{- $s := .Release.Store }}
{{- $route := or $s.route (print "/api/" $s.name "/(.*)") }}
replicaCount: {{ or $s.replicas 1 }}
nameOverride: &name {{ $s.name }}
ingresses:
  _:
    hosts:
      "":
        host: {{ or $s.host $s.ingress.host | quote }}
        paths:
          _:
            path: {{ $route }}
    nginx:
      {{- if ($route | strings.Contains "*")}}
      rewrite-target: /$1
      {{- end }}
