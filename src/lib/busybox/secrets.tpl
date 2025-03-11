{{- $r := .Release }}
{{- with $r.Store.secrets }}
Secret:
  metadata:
    name: secrets
  stringData:
{{ index . $r.Namespace | toYAML | indent 4 }}
{{- end }}
