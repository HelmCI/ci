{{ with "." }}
  {{- print . "/helmwave/helmwave.tpl" | readFile  | tpl }}{{ template "helmwave" . }}
{{ end }}