{{- define "compose" }}
{{- with .dc }}
## Pattern "release generation from docker-compose":
  {{- $release := dict }}
  {{- range $project, $dc := . }}
#  COMPOSE: {{ $project }}
    {{- with $dc.file | readFile | yaml }}
      {{- range $_srv, $srv := .services }}
        {{- $a := strings.Split ":" .image }}
        {{- $image := index $a 0 | dict "repo" }}
        {{- if gt (len $a) 1 }}
          {{- $image = index $a 1 | dict "tag" | merge $image }}
        {{- end }}
        {{- $store := dict
          "image" $image
          "path" $dc.path }}
        {{- with .healthcheck }}
          {{- $store = dict "healthcheck" . | merge $store }}
        {{- end }}
        {{- with .privileged }}
          {{- $store = dict "privileged" . | merge $store }}
        {{- end }}
        {{- with .command }}
          {{- $store = dict "command" . | merge $store }}
        {{- end }}
        {{- with .environment }}
          {{- $envs := dict }}
          {{- if test.IsKind "slice" . }}
            {{- range . }}
              {{- $kv := strings.SplitN "=" 2 . }}
              {{- $envs = index $kv 1 | dict (index $kv 0) | merge $envs }}
            {{- end }}
          {{- else }}
            {{- $envs = . }}
          {{- end }}
          {{- $store = dict "env" $envs | merge $store }}
        {{- end }}
        {{- with .ports }}
          {{- $ports := coll.Slice }}
          {{- range . }}
            {{- $s1 := strings.SplitN ":" 2 . }}
            {{- $s2 := index $s1 1 | strings.SplitN "/" 2 }}
            {{/* {{- $fromPort   := index $s1 0 | conv.ToInt }} */}}
            {{- $targetPort := index $s2 0 | conv.ToInt }}
            {{- $port := (dict
              "port"       $targetPort
              "targetPort" $targetPort
              ) }}
              {{/* "nodePort"   $fromPort */}}
            {{- if (gt (len $s2) 1) }}
              {{- $port = index $s2 1 | strings.ToUpper | dict "protocol" | merge $port }}
            {{- end }}
            {{- $ports = $ports | append $port }}
          {{- end }}
          {{- $store = dict "ports" $ports | merge $store }}
        {{- end }}
        {{- with .expose }}
          {{- $ports := or $store.ports coll.Slice }}
          {{- range . }}
            {{- $ports = $ports | append (dict "port" .) }}
          {{- end }}
          {{- $store = dict "ports" $ports | merge $store }}
        {{- end }}
        {{- with .volumes }}
          {{- $volumes := dict }}
          {{- range . }}
            {{- $a := strings.Split ":" . }}
            {{- $from := index $a 0 }}
            {{- $vol := index $a 1 | dict "to" }}
            {{- if gt (len $a) 2 }}
              {{- $vol = index $a 2 | dict "mode" | merge $vol }}
            {{- end }}
            {{- if strings.HasPrefix "/" $from}}
              {{- $vol = dict "root" true | merge $vol }}
            {{- else if strings.HasPrefix "." $from | not }}
              {{- $vol = dict "pvc" true | merge $vol }}
            {{- end }}
            {{- $volumes = dict $from $vol | merge $volumes }}
          {{- end }}
          {{- $store = dict "volumes" $volumes | merge $store }}
        {{- end }}
        {{- $rel := dict
          "base" "dc"
          "store" $store }}
        {{- with .depends_on }}
          {{- $dep := . }}
          {{- if test.IsKind "map" . }}
            {{- $dep = . | keys }}
          {{- end }}
          {{- $rel = dict "dep" $dep | merge $rel }}
        {{- end }}
        {{- $s :=  merge $ (dict
          "chart" "app"
          "ns" $project
          "name" $_srv
          "release" (merge $rel $release))}}
        {{- template "release" $s }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}
