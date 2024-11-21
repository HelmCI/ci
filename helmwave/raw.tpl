{{- define "raw" }}
## Example raw releases:
{{- $V := .V }}
{{- with "src/raw/_.tpl" }}
  {{- if file.Exists . }} 
    {{- $s := (dict "V" $V) }}
    {{- readFile . | tpl }}{{ template "raw_releases" $s }}
  {{- end }}
{{- end }}
{{- end }}
