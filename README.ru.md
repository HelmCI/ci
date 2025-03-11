# HelmwaveCI

На других языках: [English](README.md), [Русский](README.ru.md)

Это основной модуль для управления всей инфраструктурой компании с использованием вложенных модулей, приложений и проектов. Каждый модуль включает все зависимые модули через Git submodules или симлинки и может использоваться независимо от родительского.

## Мотивация

- Стандартизация инфраструктуры путем исключения необходимости использования "Docker Compose", в том числе на компьютерах разработчиков.
  - Все типичные задачи должны быть просты в исполнении, например, монтирование файлов и директорий.
- Возможность полностью исключить дублирование общих параметров конфигурации для любых релизов на любых целевых кластерах.
  - Один коммит должен описывать состояние сразу всех управляемых зависимых и не зависмых инфраструктур.
- Возможность легко повторно использовать все конфигурации между связанными и несвязанными проектами и кластерами.
- Дать разработчикам возможность объединить всю свою работу в одной среде.

## Ключевые особенности

- Зависимость только от одного [исполняемого файла](https://github.com/helmwave/helmwave) и, при необходимости, Makefiles.
- Реализация примера фрактального модульного паттерна для создания персонального монорепозитория с использованием vanilla Git.

## Пример повторного использования модулей

```sh
ci-all-my
  .ci-env # (опциональный Git submodule для секретов)
  ci # (Git submodule)
    <- тут можно деплоить демо
  ci-all-work-1 # (Git submodule)
    .ci-env # (../.ci-env опциональный симлинк для секретов)
    ci # (Git submodule)
    ci-lib-external-1 # (Git submodule)
    ci-lib-internal-1
    ci-project-external-1 # (Git submodule)
      ci # (Git submodule)
      ci-lib-external-1 # (Git submodule)
      <- тут можно деплоить только  проект external-1 (может использоваться внешними клиентами)
    ci-project-internal-1
      ci # (../ci симлинк)
      ci-lib-internal-1 # (../ci-lib-internal-1 симлинк)
      ci-lib-external-1 # (../ci-lib-external-1 симлинк)
      <- тут можно деплоить только этот internal-1 (например для тестирования перед конвертацией во внешний проект)
    <- тут можно переиспользовать все проекты work-1
  ci-all-work-2 ...
  ci-my-hobby1 ...
  ci-* # (ci-all-*/ci* симлинк)
  <- тут возможен деплой всего
```

## Структура файлов каждого модуля

- Для Helmwave:
  - [helmwave.yml.tpl](helmwave.yml.tpl) - точка входа с импортом движка
  - [helmwave*.yml](helmwave.example.yaml) - результат [генерации](https://docs.helmwave.app/0.41.x/cli/#yml) в [список релизов](https://docs.helmwave.app/0.41.x/yaml/)
  - ci* - любые подмодули [modules](#Modules) (*/{src|charts})
  - charts/* - [дампы](bin/chart.mk) из [make chart_add_example](charts.ini)
  - src/*.yml - точки входа для различных k8s [контекстов](src/local.yml)
    - src/lib/*.yml - модули контекстов
- [bin - Makefiles](bin/bin.md)
  - [bin/watch](bin/watch.md)

```sh
ci # core submodule with helmwave engine
  helmwave.yml.tpl # точка входа с импортом движка
  charts # helm chart дампы
  src
    _.yml # общий модуль для всех контекстов
    _/**/<file> # статические файлы для монтирования
    chart/<chart>/<val>.tpl # параметры для релизов чарта
    lib
      <chart>/<val>.tpl # параметры для релизов чарта для всех пространств имен
      <ctx>.yml # модули контекстов
    ns/<ns>/<chart>/<val>.tpl # параметры для релизов чарта в конкретном пространстве имен
    ctx/<ctx>/<ns>/<chart>/<val>.tpl # параметры для релизов чарта в конкретном пространстве имен и контексте
    <ctx>.yml # точки входа для различных контекстов k8s
ci-project1/<ci>
ci-project2/<ci>
.env # для безопасных настроек по умолчанию HELMWAVE_*
.env.yml # общие секреты
.env-<ctx>.yml # секреты контекста
helmwave.yml.tpl # точка входа с импортом движка
```

# Пример k3d

```sh
k3d cluster create local-ci -v "$PWD:$PWD@server:0" -p 80:80@loadbalancer --k3s-arg "--disable=traefik,local-storage,metrics-server@server:0" # 13.1s
helmwave up # 58.5s
curl http://localhost/api/openresty/
curl http://localhost/api/nginx/
curl http://localhost/nginx-raw/

k3d cluster delete local-ci # 725ms
```

## TODO:

- [x] Добавить первый пример модуля - [**infra**](https://github.com/HelmCI/ci-infra).
- [x] Добавить второй пример модуля - [**mon**](https://github.com/HelmCI/ci-mon).
- [ ] Добавить автоматизацию k3d.
- [ ] Добавить автоматизацию Kubespray.
- [ ] Добавить пример управления секретами GitLab.
- [ ] Добавить примеры для множества реальных рабочих паттернов.
