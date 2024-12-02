# check on all contexts/clusters at once

## examples from real world

```sh
HELMWAVE_TAGS=minio,minio-ingress make all_dump &| grep -E 'audio|tmp/|changed:|FATAL|WARNING'
```
