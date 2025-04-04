{{- $s := .Release.Store }}
{{- $name := .Release.Name }}
{{- $version := or $s.v
  (index (or $s.ver dict) $name)
  $s.image.tag
  "latest" }}
nameOverride: {{ $name }}
version: &version {{ $version }}
image:
  tag: *version
  repository: {{ $s.image.repo }}

{{- with $s.command }}
{{/* command: */}}
args:
{{ toYAML . | indent 2 }}
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

{{- with $s.ports }}
service:
  {{/* type: NodePort */}}
  ports:
{{ toYAML . | indent 4 }}
{{- else }}
serviceDisable: true
{{- end }}

{{- with $s.volumes }}
  {{- $pvc := . | coll.JQ `[.[] | select(.pvc == true)] | length` }}
  {{- if and $pvc $s.pvc }}
pvc:
    {{- range $k, $v := . }}
      {{- if $v.pvc }}
  {{ $k }}:
    {{/* annotations:
      helm.sh/resource-policy: keep */}}
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi  
      {{- end }}
    {{- end }}
volume:
    {{- range $k, $v := . }}
      {{- if $v.pvc }}
  {{ $k }}:
    persistentVolumeClaim:
      claimName: {{ $k }}
      {{- end }}
    {{- end }}
volumeMount:
    {{- range $k, $v := . }}
      {{- if $v.pvc }}
  {{ $k }}:
    mountPath: {{ $v.to }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if and $s.hostPath (. | len | lt $pvc) }}
hostPath:
    {{- range $k, $v := . }}
      {{- if $v.root }}
  {{ $k }}: {{ $v.to }}
      {{- else if not $v.pvc }}
  {{ requiredEnv "PWD" -}}/{{ $s.path }}/{{ $k }}: {{ $v.to }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- with $s.healthcheck }}
livenessProbe: &livenessProbe
  exec:
    command: {{ coll.GoSlice .test 1 (len .test) | data.ToJSON }}
  periodSeconds: {{ .interval | strings.TrimSuffix "s" | conv.ToInt }}
  timeoutSeconds: {{ .timeout | strings.TrimSuffix "s" | conv.ToInt }}
  failureThreshold: {{ .retries }}
readinessProbe: *livenessProbe
{{- else }}
probeDisable: true
{{- end }}

{{- with $s.privileged }}
securityContext:
  privileged: {{ . }}
  {{/* capabilities:
    add:
      - SYS_ADMIN
      - SYS_RAWIO
      - SYS_PTRACE */}}
  {{/* allowPrivilegeEscalation: true */}}
  {{/* readOnlyRootFilesystem: true */}}
{{/* hostPID: true */}}
{{/* hostIPC: true */}}
{{/* hostNetwork: true */}}
{{/* strategy:
  type: Recreate */}}
{{- end }}

{{- with $s.node }}
nodeSelector: 
  kubernetes.io/hostname: {{ . }}
{{- end }}
