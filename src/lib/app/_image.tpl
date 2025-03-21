{{- $s := .Release.Store }}
{{- $version := or $s.v (index (or $s.ver dict) .Release.Name) }}
nameOverride: {{ $s.name }}
version: &version {{ $version }}
image:
  tag: *version
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
