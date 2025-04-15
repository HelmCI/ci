# Quick Start

## Воспользуемся патерном docker-compose

```sh
k3d cluster delete local-ci
k3d cluster create local-ci -v "$PWD:$PWD@server:0" -p 80:80@loadbalancer --k3s-arg "--disable=traefik,local-storage,metrics-server@server:0"

mkdir -p tmp/test
cd tmp/test

# git submodule add -- https://github.com/HelmCI/ci
ln -s ../../ci
# make -sC ci qs_init -n
# cd ci && make qs_init && cd -
curl -LO https://raw.githubusercontent.com/HelmCI/ci-infra/refs/heads/main/Makefile
curl -LO https://raw.githubusercontent.com/HelmCI/ci-infra/refs/heads/main/helmwave.yml.tpl
mkdir -p src/dc/wp/
cp ci/src/dc/demo-wp/docker-compose.yml src/dc/wp/
cp ci/.env .
echo "\
namespace:
  wp:
    compose:
" >  src/k3d-local-ci.yml

helmwave up
```
