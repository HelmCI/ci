{{- define "db" }}
{{- with .db_map }}
## Custom pattern "release generation from Store":
  {{- $release := . }}
  {{- range $_db, $db := .name }}
#   DB: {{$_db}}
    {{- range $role, $host := .role }}
      {{- $role = print "db-" $role }}
      {{- $s :=  merge $ (dict
        "ns" "gd"
        "chart" "app"
        "template" "db"
        "name" (print $role "-" $_db)
        "release" (merge
            (dict "dep" (coll.Slice 
                    (index (or $release.dep dict) $host) 
                    "cm-oidc")
                  "store" (merge (dict 
                      "role"  $role
                      "host"  (print $host ".db")
                      "db"    (dict
                          "name" $_db 
                          "bd"   $db.bd
                          "cron" $db.cron)
                    ) $release.store ))
            $release )) }}
      {{- template "release" $s }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}
