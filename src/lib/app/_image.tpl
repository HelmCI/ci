{{- $s := .Release.Store }}
{{- $version := or $s.v (index $s.ver .Release.Name) }}
nameOverride: {{ $s.name }}
version: {{ $version }}
image:
  tag: {{ $version }}
  repository: {{ $s.registry.host }}/{{ $s.image }}

{{- with $s.env }}
env:
{{ toYAML . | indent 2 }}
{{- end }}

{{- with $s.port }}
service:   
  port: {{ . }}
livenessProbe: &livenessProbe
  httpGet:
    port: {{ . }}
    path: /
readinessProbe: *livenessProbe
{{- end }}
{{- with $s.probeDisable }}
probeDisable: {{ . }}
{{- end }}
