{{- define "readFileExists" }}
{{- if file.Exists . }} 
{{ readFile . }}
_status: {{ . }} <- exists
{{- else }}
_status: {{ . }} <- NOT exists
{{- end }}
{{- end -}}
