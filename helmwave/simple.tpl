{{- define "simple" }}
## Simple pattern "multycluster by tags":
{{- $V := .V }}
{{- $src := "src/simple"  }}
{{- if file.Exists $src }} 
{{- range $file := (file.ReadDir $src) }}
  {{- if not (file.IsDir (filepath.Join $src $file)) }}
    {{- $_ns := filepath.Base $file | strings.TrimSuffix (filepath.Ext $file) -}}
    {{- with filepath.Join $src $file | file.Read | data.YAML }}
      {{- $_releaseeases := . }}
  # NS: {{ $_ns }}
      {{- range $name := coll.Keys . }}
        {{- $_release := index $_releaseeases $name }}
  - <<: *default
    namespace: {{ $_ns }}
    name: {{ $name }}
    chart: {{ $_release.chart }}
    values: {{- if not $_release.values }} [{{ $src }}/{{- $_ns -}}/{{- $name -}}.tpl]
        {{- else }}
          {{- range $_release.values }}
      - {{ $src }}/{{ . }}.tpl
          {{- end }}
        {{- end }}
        {{- $v := (or $V $_release.v) }}
        {{- with $v }}
    store: {v: {{ . }}}
        {{- end }}
        {{- with $_release.dep }}
    depends_on: {{ . }}
        {{- end }}
    tags: [{{ $_ns }}, {{ $_ns }}@{{ $name }} {{- range $_release.tags }}, {{ . }}{{ end }}]
      {{ end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
