{{- $s := .Release.Store }}
{{- $r := $s.registry }}

{{- $version := or $s.v (index (or $s.ver dict) .Release.Name) }}
nameOverride: {{ $s.name }}
version: &version {{ $version }}
image:
  tag: *version
  {{- $image := $s.image }}
  repository: {{ $image }}
{{- with $r.hostProxy }}
    {{- $image_repo := regexp.Find `^([^/]*[.:][^/]*)` $image | default "docker" }}
    {{- if ne . $image_repo }}
  repository:
      {{- $image_key := strings.ReplaceAll "." "_" $image_repo }}
      {{- $image_path := index $r.proxy $image_key }}
      {{- $image = strings.ReplaceAll (print $image_repo "/") "" $image }}
      {{ . }}/{{ $image_path }}/{{ $image }}
    {{- end }}
{{- end }}

{{- with $s.env }}
env:
{{ toYAML . | indent 2 }}
{{- end }}

{{- with $s.secret }}
envFrom:
  secret:
    secrets:
{{ toYAML . | indent 6 }}
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
