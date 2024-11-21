# Helmwave-CI

Read this in other languages: [English](README.md), [Русский](README.ru.md)

This is a core module for managing the entire company infrastructure using nested system, application, and project modules. Each module includes all dependent modules via Git submodules or symlinks and can be used independently of the parent.

## Motivation

- Standardization of infrastructure by eliminating the need to use "Docker Compose," including on developers' machines.
  - All typical tasks should be as simple to execute, such as mounting files and directories.
- The ability to completely eliminate duplication of common configuration parameters for any releases on any target clusters.
  - A single commit should describe the state of the entire infrastructure.
- The ability to reuse all configurations easily between related and unrelated projects and clusters.
- Enable developers to combine all their work on a single environment.

## Key Features

- Dependency only on a single [binary file](https://github.com/helmwave/helmwave) and optionally some Makefiles.
- Implementation of an example fractal modular pattern for creating a personal monorepo using vanilla Git.
- Kubernetes (k8s) is all you need.

## Example of Module Reuse

```sh
ci-all-my
  .ci-env # (optional Git submodule for secrets)
  ci # (Git submodule)
    <- possible deploy demo
  ci-all-work-1 # (Git submodule)
    .ci-env # (../.ci-env optional symlink for secrets)
    ci # (Git submodule)
    ci-lib-external-1 # (Git submodule)
    ci-lib-internal-1
    ci-project-external-1 # (Git submodule)
      ci # (Git submodule)
      ci-lib-external-1 # (Git submodule)
      <- possible deploy only this project (can be used by external clients)
    ci-project-internal-1
      ci # (../ci symlink)
      ci-lib-internal-1 # (../ci-lib-internal-1 symlink)
      ci-lib-external-1 # (../ci-lib-external-1 symlink)
      <- possible deploy only this project (for testing to prepare it for conversion to external)
    <- possible reuse of all work-1 projects
  ci-all-work-2 ...
  ci-my-hobby1 ...
  ci-* # (ci-all-*/ci* symlink)
  <- possible deploy all
```

## File Structure of Each Module

- For Helmwave:
  - [helmwave.yml.tpl](helmwave.yml.tpl) - entry point with engine import
  - [helmwave*.yml](helmwave.example.yaml) - these are the results of [generating](https://docs.helmwave.app/0.41.x/cli/#yml) into [release list](https://docs.helmwave.app/0.41.x/yaml/)
  - ci* - any sub [modules](#Modules) (*/{src|charts})
  - charts/* - [dumps](bin/chart.mk) from [make chart_add_example](charts.ini)
  - src/*.yml - entry points for different k8s [contexts](src/local.yml)
    - src/lib/*.yml - context modules
- [bin - Makefiles](bin/bin.md)
  - [bin/watch](bin/watch.md)

```sh
ci # core submodule with helmwave engine
  helmwave.yml.tpl # entry point with engine import
  charts # helm chart vendoring
  src 
    _.yml # common context module forced to be connected
    _/**/<file> # static files for mounts
    chart/<chart>/<val>.tpl # values for chart releases
    lib
      <chart>/<val>.tpl # values for chart releases for all namespaces
      <ctx>.yml # any context modules
    ns/<ns>/<chart>/<val>.tpl # values for chart releases in a specific namespace
    ctx/<ctx>/<ns>/<chart>/<val>.tpl # values for chart releases in a specific namespace and context
    <ctx>.yml # entry points for different k8s contexts
ci-project1/<ci>
ci-project2/<ci>
.env # for safe defaults HELMWAVE_*
.env.yml # common secret
.env-<ctx>.yml # context secret
helmwave.yml.tpl # entry point with engine import
```

# k3d example

```sh
k3d cluster create local-ci -v "$PWD:$PWD@server:0" -p 80:80@loadbalancer --k3s-arg "--disable=traefik,local-storage,metrics-server@server:0" # 14.4s
helmwave up # 1.3m
curl http://localhost/api/nginx/
curl http://localhost/nginx-raw/

k3d cluster delete local-ci # 725ms
```

## TODO:

- [ ] Add first sample modules (infra, mon).
- [ ] Add k3d automation.
- [ ] Add Kubespray automation.
- [ ] Add GitLab secrets management example.
- [ ] Add examples for many real work patterns.