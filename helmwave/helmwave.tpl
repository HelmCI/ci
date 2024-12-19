{{- define "helmwave" -}} 
# bin i -f github.com/helmwave/helmwave/releases/tag/v0.41.1
version: 0.41.1
{{ $src := "src" -}}
{{ $K := or (getenv "K") ( or (getenv "KUBECONFIG") 
  (env.ExpandEnv "$HOME/.kube/config") | readFile | yaml | 
  get "current-context") -}}  # $K = {{ $K }} - Kubernetes context
{{ $R := getenv "R" -}}       # $R = {{ $R }} - Release suffix
{{ $V := getenv "V" -}}       # $V = {{ $V }} - Version
{{ $T := getenv "T" -}}       # $T = {{ $T }} - Tag (Release/Version)
{{- if $T }}
  {{- if not $V }}
    {{- with $T | strings.Split "/" }}
      {{ $T = index . 0 }} # $T = {{ $T }} 
      {{ $V = index . 1 }} # $V = {{ $V }}
    {{- end }}
  {{- end }}
  {{ $R = or $R (print "-" (replaceAll "." "-" $V)) }} # $R = {{ $R }} -> Release: {{$T}}{{$R}}
{{- end }} 
{{- $s := (dict "R" $R "V" $V "T" $T "K" $K "src" $src) }}

{{ with print . "/helmwave/" }}

  {{- print . "readFileExists.tpl" | readFile | tpl }}
  {{- print . "fileName.tpl"  | readFile | tpl }}
  {{- print . "context.tpl"   | readFile | tpl }}
  {{- print . "store.tpl"     | readFile | tpl }}
  {{- print . "release.tpl"   | readFile | tpl }}
  {{- print . "db.tpl"        | readFile | tpl }}
  {{- print . "yaml.tpl"      | readFile | tpl }}{{ template "yaml"   $s }}
  {{- print . "src.tpl"       | readFile | tpl }}{{ template "src"    $s }}

  {{- if not $T }}

    {{- print . "simple.tpl"  | readFile | tpl }}{{ template "simple" $s }}
    {{- print . "raw.tpl"     | readFile | tpl }}{{ template "raw"    $s }}

  {{- end }}
{{- end }}
{{- end -}}
