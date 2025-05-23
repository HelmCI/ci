{{- $bin := "png jpg zip" | strings.Split " " }}
{{- $hidden := ".DS_Store" | strings.Split " " }}
{{- $s := .Release.Store }}
{{- $r := $s.registry }}
{{- $name := .Release.Name }}
{{- $version := or $s.v
  (index (or $s.ver dict) $name)
  $s.image.tag
  "latest" }}
nameOverride: {{ $name }}
version: &version {{ $version | quote }}
image:
  tag: *version
  {{- $image := $s.image.repo }}
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

{{- with $s.command }}
{{/* command: */}}
args:
{{ toYAML . | indent 2 }}
{{- end }}

{{- with $s.env }}
env:
{{ . | coll.Omit (or $s.secret dict | keys) | toYAML | indent 2 }}
{{- end }}

{{- with $s.secret }}
envFrom:
  secret:
    secrets:
{{ toYAML . | indent 6 }}
{{- end }}

{{- with $s.ports }}
service:
  {{- if . | coll.JQ `any(.[]; has("nodePort"))` }}
  type: NodePort
  {{- end }}
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

  {{- if . | len | lt $pvc }}
hostPath:
    {{- range $k, $v := . }}
      {{- if $v.root }}
  {{ $k }}: {{ $v.to }}
      {{- else if not $v.pvc | and $s.hostPath }}
  {{ requiredEnv "PWD" -}}/{{ $s.path }}/{{ $k }}: {{ $v.to }}
      {{- end }}
    {{- end }}

    {{- if not $s.hostPath }}
{{/* annotations: */}}
      {{- $d := dict }}
      {{- range $k, $v := . }}
        {{- if or $v.root $v.pvc | not }}
          {{- $path := filepath.Join $s.path $k }}
  {{/* 1-{{ $k | filepath.Clean }}: | */}}
          {{- if file.Exists $path }}
          {{- range file.Walk $path }}
            {{- if and (file.IsDir . | not) (filepath.Base . | has $hidden | not) }}
    {{/* {{ filepath.Dir . | filepath.Rel $path | filepath.Join $v.to }} {{ filepath.Base . }} */}}
              {{- $d = $d | merge (readFile .
                | dict (filepath.Base .)
                | dict (filepath.Dir . | filepath.Rel $path | filepath.Join $v.to )
                | dict (filepath.Ext . | strings.TrimPrefix "." | has $bin)
                )}}
            {{- end }}
          {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}

files:
      {{- range $p, $_ := $d.false }}
  {{ $p }}:
        {{- range $f, $_ := . }}
    {{ $f }}: |
{{ $_ | indent 6}}
        {{- end }}
      {{- end }}

binaryData:
      {{- range $p, $_ := $d.true }}
  {{ $p }}:
        {{- range $f, $_ := . }}
    {{ $f }}: {{ $_ | base64.Encode }}
        {{- end }}
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
