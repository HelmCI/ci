{{- define "release" }}

{{- $v := coll.Slice }}
{{- $chart := .charts | get .chart dict }}
{{- $template := or .template .name }}
{{- $name := print .name (or .R "") }}
  - <<: *default # RELEASE: "{{ .name }}"
    namespace: {{ or .ns_name .ns }}
    name: {{ $name }}
    chart:
      name: {{ filepath.Join ( or $chart.module "") "charts" .chart }}
      skip_dependency_update: true
    tags: [{{- if not .release.manual -}}
              {{ .K }}, {{ .ns }}
              {{- with .template }}, {{ . }}{{- end -}}
          , {{ end -}}
              {{ .name }}, {{ .ns }}@{{ .name }}
          {{- range .release.tags }}, {{ . }}{{ end }}]

{{- with .release.dep }}
    depends_on:
  {{- range . }}
    {{- if . }}
      - name: {{ . }}
        optional: true
    {{- end }}
  {{- end }}
{{- end }}
    values:

{{- range $chart.values }}
    {{- $v = $v | append (filepath.Join $.src "chart"                     (print . ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "chart"             $.chart (print . ".tpl")) }}
{{- end }}
{{- range .release.deps }}
    {{- $v = $v | append (filepath.Join $.src "lib"               $.chart (print . ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "ns"          $.ns  $.chart (print . ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "context" $.K $.ns  $.chart (print . ".tpl")) }}
{{- end }}
{{- with .release.base }}
    {{- $v = $v | append (filepath.Join $.src "lib"               $.chart (print . ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "ns"          $.ns  $.chart (print . ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "context" $.K $.ns  $.chart (print . ".tpl")) }}
{{- end }}
    {{- $v = $v | append (filepath.Join $.src "lib"               $.chart (print $template ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "ns"          $.ns  $.chart (print $template ".tpl")) }}
    {{- $v = $v | append (filepath.Join $.src "context" $.K $.ns  $.chart (print $template ".tpl")) }}

{{- $last_module := "" }}
{{- range $_, $path := $v }}
  {{- if file.Exists . }}
      - {{ . }} # file://./{{ . }}
  {{- else }}
    {{- $module := "" }}
    {{- range $.modules }}
      {{- if filepath.Join . $path | file.Exists }}
        {{- $module = . }}
        {{- break }}
      {{- end }}
    {{- end }}
    {{- if $module }}
      {{- $last_module = $module }}
      - {{ $module }}/{{ . }} # file://./{{ $module }}/{{ . }}
    {{- else }}
      # file://./{{ . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $__ := filepath.Join $last_module $.src "_" | dict "__" }}

{{- $version := dict }}
{{- with or .V .release.v }}
  {{- $version = dict "v" . }}
{{- end }}

{{- $store := or .release.base  .name | dict "name" | merge $__ $version .release.store }}
    store:
      <<: *store
{{ toYaml $store  | indent 6 }}

{{- with .release.add }}
{{ toYaml .       | indent 4 }}
{{- end }}

{{- end -}}
