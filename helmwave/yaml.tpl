{{- define "yaml" -}}
## YAML Anchors for reuse:
.z:
  - &demo # example yaml sugar
    namespace: demo
  - &default
    context: {{ $.K }}
    create_namespace: true
    pending_release_strategy: uninstall # rollback
    timeout: 30m # 5m
    wait: true
    offline_kube_version: 1.30.4
{{- end -}}
