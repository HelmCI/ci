{{- define "context" }}
# find entry point and merge with all dependencies
{{ $K    := .K }}
{{ $src  := .src }}

_debug: # to print the merge order

# search modules
{{/* {{ $modules := file.ReadDir "." | flatten | coll.JQ `map(select(startswith(".") | not)) | sort` }} */}} # WAIT: 3.11.8 -> 4.0.0 https://github.com/helmwave/helmwave/blob/main/go.mod#L10 https://docs.gomplate.ca/functions/coll/#colljq 
{{ $modules := coll.Slice }}
{{ $chart_modules := coll.Slice }}
{{ range file.ReadDir "." | sort }}
  {{ if file.IsDir . }} # (. | strings.HasPrefix "." | not)
    {{ $module := tmpl.Exec "fileName" . }}
    {{ if filepath.Join . $src      | file.Exists }}
      {{ $modules = $modules              | append $module }}  
    {{ end }}
    {{ if filepath.Join . "charts"  | file.Exists }}
      {{ $chart_modules = $chart_modules  | append $module }}  
    {{ end }}
  {{ end }}
{{ end }}
  - "MODULES SRC:   {{ $modules }}"
  - "MODULES CHART: {{ $chart_modules }}"
  - "Merge context in order:"

# make contexts map {context: file}
{{ $contexts := dict }}
{{ range file.ReadDir $src }}
  {{ $contexts = dict (tmpl.Exec "fileName" .) (filepath.Join $src .) | merge $contexts }}
{{ end }}

# search additional contexts
{{ range $_, $module := $modules }}
  {{ $path := filepath.Join . $src }}
  {{ range file.ReadDir $path }}
    {{ $file := filepath.Join $path . }}
    {{ if file.IsDir $file | not }} # extra check
      {{ $contexts = dict (tmpl.Exec "fileName" .) $file | merge $contexts }}
    {{ end }}
  {{ end }}
{{ end }}

{{ $all := path.Join $src "_.yml" | tmpl.Exec "readFileExists" | yaml }}
  - "COMMON  STORE:  file://./{{     $all._status }}"
{{ $env := tmpl.Exec "readFileExists" ".env.yml" | yaml }} 
  - "COMMON  SECRET: file://./{{     $env._status }}"
{{ $env_ctx := print ".env-" $K ".yml" | tmpl.Exec "readFileExists" | yaml }} 
  - "CONTEXT SECRET: file://./{{ $env_ctx._status }}"

{{ $context := merge $env_ctx $env $all (dict "modules" $modules) }} # merge found common dependencies

# find all dependencies from context to merge
{{ $file := index $contexts $K }} # get entry point by name of current kubernetes context
{{ $test := print `entrypoint "` $file `" NOT exists` }}
{{ file.Exists $file | assert (print "CONTEXT file://./" $src "/" $K ".yml NOT exists!") }}
{{ with $file | readFile | yaml }}
  {{ $deps := dict }} 
  {{ range $dep := .deps }}
    {{ $dep_file := filepath.Join $src "lib" (print $dep ".yml") }}
    {{ if file.Exists $dep_file | not }} # search in modules
      {{ range $modules }}
        {{ $dep_file = filepath.Join . $src "lib" (print $dep ".yml") }}
        {{ if file.Exists $dep_file }}
          {{ break }}
        {{ end }}
      {{ end }}
    {{ end }}
    {{ $deps = merge ($dep_file | tmpl.Exec "readFileExists" | yaml) $deps }}
  - "DEPS:           file://./{{ $deps._status }}" # print dependency from entry point
  {{ end }}
  - "CONTEXT:        file://./{{ $file }} <- {{ $K }}" # print entry point
  {{ $context = merge . $deps $context }}
{{ end }}  

# make charts map {chart:{module:"ci...",values:[]}}
{{ $charts := dict }}
{{ range $_, $module := $chart_modules }}
  {{ $path := filepath.Join . "charts" }}
  {{ if file.Exists $path }}
    {{ range file.ReadDir $path }}
      {{ if filepath.Join "charts" . | file.Exists | not }}
        {{ $charts = dict "module" $module | dict . | merge $charts }}
      {{ end }}
    {{ end }}
  {{ end }}
{{ end }}
{{ range $chart, $chart_values := $context.chart }}
  {{ $charts = dict "values" $chart_values | dict $chart | merge $charts }}
{{ end }}
{{ $context = dict "charts" $charts | merge $context }}
  - "NS: {{ $context.namespace | keys }}" # print namespaces

# RETURN merged context:
{{ $context | toYaml }}

{{ end -}}
