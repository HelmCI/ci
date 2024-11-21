{{- define "fileName" }}
  {{- filepath.Base . | strings.TrimSuffix (filepath.Ext .) }}
{{- end -}}
