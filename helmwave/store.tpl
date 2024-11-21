{{- define "store" }}
## Trigger additional parameters of the side
{{ $kube     := .K }}
{{ $src      := .src }}
{{ $context  := .context }}

{{ $store  := $context.store }}
{{ $db_map := $context.namespace.gd.db }} # for custom pattern - release generation
{{ $_      := filepath.Join $src "_" }}   # path to static file assets

# make registry hostProxy
{{ $hostProxy := or $store.registry.hostProxy $store.registry.host }}

# make ingress-controller vars
{{ $ingress := $store.ingress}}
{{ $ingress_url := print $ingress.sheme "://" $ingress.host }}
{{ $ingress_host := "" }} 
{{ if not $store.ingress.allHosts }} 
  {{ $ingress_host = $store.ingress.host }} 
{{ end }}

# make keycloak vars
{{ $oidc_url := $ingress_url }}
{{ $oidc := $store.oidc }}
{{ with $oidc.host }}
  {{ $oidc_url = print $ingress.sheme "://" . }}
{{ end }}        
{{ with $oidc.route }}
  {{ $oidc_url = print $oidc_url "/" . }}
{{ end }}

# RETURN store
{{ merge (dict 
      "_" $_
      "_modules" $context.modules
      "kube" $kube
      "oidc" (dict 
        "url" $oidc_url )
      "registry" (dict
        "hostProxy" $hostProxy )
      "ingress" (dict
        "url" $ingress_url
        "host"  $ingress_host
        "host0" $ingress.host )
      "db_map" $db_map
    ) $store
  | toYaml }}

{{ end -}}
