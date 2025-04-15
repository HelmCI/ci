# Quick Start

## Поднимем тестовый кластер и подключим движек

```sh
k3d cluster create local-ci -v "$PWD:$PWD@server:0" -p 80:80@loadbalancer --k3s-arg "--disable=traefik,local-storage,metrics-server@server:0"

git submodule add -- https://github.com/HelmCI/ci

curl -LO https://raw.githubusercontent.com/HelmCI/ci-infra/refs/heads/main/helmwave.yml.tpl
cp ci/.env .
```

## Воспользуемся патерном docker-compose

```sh
mkdir -p src/dc/wp/
cp ci/src/dc/demo-wp/docker-compose.yml src/dc/wp/
echo "\
namespace:
  wp:
    compose:
" >  src/k3d-local-ci.yml

helmwave up
```
