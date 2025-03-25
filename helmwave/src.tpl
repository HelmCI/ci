{{- define "src" }}
## Rich pattern "current cluster by tags":
{{- $K    := .K }}
{{- $R    := .R }}
{{- $V    := .V }}
{{- $T    := .T }}
{{- $src  := .src }}

{{- $context  := tmpl.Exec "context"  . | yaml }}
{{- range $context._debug }}
# {{ . }}
{{- end }}

{{- $s := dict "context" $context | merge . }}
{{- $store    := tmpl.Exec "store"   $s | yaml }}
# INGRESS: {{ $store.ingress.url }}
{{template "yaml" $s }}
.store: &store
{{ toYaml $store | indent 2 }}
releases:

{{- $r := dict "charts" $context.charts "modules" $context.modules | merge $ }}

{{- if not $T }}
  {{- $s := dict "dc" $context.dc | merge $r }}
  {{- template "compose" $s }}

  {{- $s := dict "db_map" $store.db_map | merge $r }}
  {{- template "db" $s }}
{{- end }}

{{- range $ns, $namespace := $context.namespace }}
#  NS: {{$ns}}
  {{- range $chart, $_ := .chart }}
#   CHART: {{$chart}}
    {{- range $name, $release := . }}

      {{- $release = or $release dict }}
      {{- if or (not $T) (eq $T $name) }}

        {{- $s := merge $r (dict
          "ns" $ns
          "ns_name" $namespace.ns_name
          "chart" $chart
          "name" $name
          "release" (merge $release (dict
            "manual" (or $release.manual $namespace.manual)))) }}
        {{- template "release" $s }}

      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
