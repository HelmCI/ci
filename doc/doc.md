# Документация

По-простому задача системы — генерировать [файл списка релизов](../helmwave.example.yaml). Пройдемся по его структуре. Вначале мы видим: 
```yml
## Rich pattern "current cluster by tags":
``` 
Здесь начинается результат генерации по [основному паттерну](../helmwave/src.tpl). Ниже есть примеры других, никак не связанных между собой, паттернов ["raw"](../helmwave/raw.tpl) и ["simple"](../helmwave/simple.tpl):
```yml
## Simple pattern "multycluster by tags":
## Example raw releases:
```
Но они менее интересны, так что вернемся к основному. К разговору о паттернах можно упомянуть, что внутри основного можно разными способами встраивать другие расширения. Например, системное расширение ["docker-compose"](../helmwave/compose.tpl) и пример прикладного расширения ["release generation from Store"](../helmwave/db.tpl).

## Логика работы основного паттерна (модули)

Для начала разберем понятие модуля — это произвольная папка в корне, у которой есть подпапки src и/или chart. Модули имеют ту же структуру, что и корневая папка, таким образом она тоже модуль. В реальности отчуждаемые модули удобно делать Git-сабмодулями, остальные проектные — оставлять в текущем репозитории до момента необходимости отчуждения.

Итак, все найденные при сборке модули для дебага печатаем так, в соответствии с их содержимым:
```yml
# MODULES SRC:     [ci ci-infra]
# MODULES CHART:   [ci ci-infra]
# MODULES COMPOSE: [ci]
```
Дальше все компоненты системы будут искаться в этих модулях, ровно в этом порядке с сортировкой по имени модуля. И компонент будет браться первый встретившийся, с приоритетом к текущему корневому модулю. Значит, в нем можно всё переопределить, что было найдено в подчинённых модулях. Модули, несмотря на свою фрактальную структуру, обрабатываются только на один уровень от корня. Если нужно учитывать более глубоко вложенный модуль, мы просто поднимаем его на первый уровень симлинком. Чтобы симлинки не загромождали дубликатами файлов результаты поиска в IDE, мы просто отключаем их обработку — например, в VS Code это одна галочка.

## Поиск всех компонентов по модулям

Первым делом мы [находим точку входа](../helmwave/context.tpl), равную имени текущего кубового **контекста**, среди кандидатов: 
```*/src/*.yml```
Эти файлы имеют справочное поле:
```yml
kind: context
```
В дебаге это печатается так:
```yml
# CONTEXT:        file://./../src/k3d-local-ci.yml <- k3d-local-ci
```
Все имена файлов выводим в таком виде, чтобы ссылки были кликабельными, в частности в VS Code.
Имя текущего контекста может быть переопределено в переменной окружения **K=..**.

Далее в найденном **контексте** смотрим все зависимости, например:
```yml
deps:
  - system
  - infra
  - mon
  - mon-homer
  - demo-wp
  - demo-optional
```
которые отображаются в дебаге в:
```yml
# DEPS:           file://./../src/lib/system.yml <- exists
# DEPS:           file://./../ci-infra/src/lib/infra.yml <- exists
# DEPS:           file://./../src/lib/mon.yml <- exists
# DEPS:           file://./../src/lib/mon-homer.yml <- exists
# DEPS:           file://./../ci/src/lib/demo-wp.yml <- exists
# DEPS:           file://./../src/lib/demo-optional.yml <- NOT exists
```
Поиск идет по шаблону ```*/src/lib/*.yml```
Здесь мы видим, что одна зависимость не была найдена и была пропущена. Также можно обратить внимание: зависимости были найдены в разных модулях. Эти зависимости нужны для того, чтобы смерджить их с файлом контекста именно в таком порядке, с приоритетом к контексту — таким образом они являются своего рода **плагинами**, из которых можно гибко собирать целевое решение.
Эти файлы имеют справочное поле:
```yml
kind: lib
```
Также есть три общие фиксированные зависимости:
```yml
# COMMON  STORE:  file://./../src/_.yml <- exists
# COMMON  SECRET: file://./.env.yml <- NOT exists
# CONTEXT SECRET: file://./.env-k3d-local-mon.yml <- NOT exists
```
Они тоже вмердживаются в контекст с меньшим приоритетом в указанном порядке перед основными зависимостями.
```sh
src/_.yml # общая зависимость для всех контекстов | kind: all
.env.yml # общие секреты для всех контекстов      | kind: .env
.env-<ctx>.yml # секреты текущего контекста       | kind: .env
```
Два последних, очевидно, в [.gitignore](../.gitignore), и их можно хранить, например, в переменных gitlab-ci, для деплоя:
```yml
deploy-dev1:
  stage: deploy
  script:
    - cp $ENV .env.yml
    - cp $ENV_DEV1 .env-dev1.yml
    - cp $KUBE_CONFIG_DEV1 /root/.kube/config
    - helmwave up -t dev1
```

## Глобальная стора

В смердженном контексте содержимое ключа **store** копируется в глобальную стору и [обогащается](../helmwave/store.tpl) системными полями:
```yml
.store: &store
  _: src/_
  _modules:
      - ci
      - ci-infra
  ...
```
- Где **_** используется для хорошей практики абстракции от фиксированного пути — для размещения там статических файлов, которые необходимы обычно для маунта через секреты и конфигмапы.
- А **_modules** необходимы обычно для динамического поиска статики по модулям
- Также генерируется часть системных полей для ключей **ingress:** и **registry:**, но в будущем планируется перенести это в опционно подключаемые плагины.

Во все релизы глобальная стора подключается средствами YAML:
```yml
releases:
  ...
    store:
      <<: *store
      ...
```

## Релизы

Разберем формирование релизов на [этом](../src/lib/demo-nginx.yml) примере:
```yml
kind: lib
chart: # general values for all chart releases
  app:
    - general       # file://./../src/chart/general.tpl
    - volume-tz-msk # file://./../src/chart/app/volume-tz-msk.tpl
namespace:
  demo:
    # ns_name: remap
    chart:
      busybox:
        secrets:
      app:
        nginx:
          deps:
            - _api # http://localhost/api/nginx/
        openresty:
          deps:
            - _api # http://localhost/api/openresty/
            - _image
          store:
            image: openresty/openresty
          v: 1.21.4.1-0-alpine
```
Первый релиз **secrets** для чарта **busybox** в неймспейсе **demo** из примера отображается в:
```yml
## YAML Anchors for reuse:
.z:
  - &default
    context: k3d-local-ci
    create_namespace: true
    pending_release_strategy: rollback # rollback
    timeout: 30m # 5m
    wait: true
    offline_kube_version: 1.31.5
releases:
#  NS: demo
#   CHART: busybox
  - <<: *default # RELEASE: "secrets"
    namespace: demo
    name: secrets
    chart:
      name: charts/busybox
      skip_dependency_update: true
    tags: [k3d-local-ci, demo, secrets, demo@secrets]
    values:
      - src/lib/busybox/secrets.tpl # file://./../src/lib/busybox/secrets.tpl
      # file://./../src/ns/demo/busybox/secrets.tpl
      # file://./../src/context/k3d-local-ci/demo/busybox/secrets.tpl
    store:
      <<: *store
      __: src/_
      name: secrets
  ...
```
Релиз получает теги:
 - secrets = имя релиза
 - demo@secrets = имя релиза уточнённое до неймспейса
 - demo = "гипертег" имени неймспейса
 - k3d-local-ci = "гипертег" имени контекста

"Гипертеги" можно отключить, указав в неймспейсе или релизе ключ:
```yml
manual: true
```
Разберем подробнее самое важное для следующего этапа прожига темплейтов вэлюсов релизов:
```yml
    values:
      - src/lib/busybox/secrets.tpl # file://./../src/lib/busybox/secrets.tpl
      # file://./../src/ns/demo/busybox/secrets.tpl
      # file://./../src/context/k3d-local-ci/demo/busybox/secrets.tpl
```
Здесь видно, что была успешная попытка поиска ```[Модули]/src/lib/<Чарт>/<Релиз>.tpl```. Другими словами, нашли параметры по умолчанию для релизов с таким именем для нужного чарта и для любых неймспейсов.
Далее — неуспешная попытка поиска более конкретного ```[Модули]/src/ns/<Неймспейс>/<Чарт>/<Релиз>.tpl```. Это то же самое, но уже для конкретного неймспейса.
И в конце — самый частный случай ```[Модули]/src/context/<Контекст>/<Неймспейс>/<Чарт>/<Релиз>.tpl```.

Для другого релиза список поиска будет шире:
```yml
#   CHART: app
  - <<: *default # RELEASE: "openresty"
    namespace: demo
    name: openresty
    chart:
      name: charts/app
      skip_dependency_update: true
    tags: [k3d-local-ci, demo, openresty, demo@openresty]
    values:
      - src/chart/general.tpl # file://./../src/chart/general.tpl
      # file://./../src/chart/app/general.tpl
      # file://./../src/chart/volume-tz-msk.tpl
      - src/chart/app/volume-tz-msk.tpl # file://./../src/chart/app/volume-tz-msk.tpl
      - src/lib/app/_api.tpl # file://./../src/lib/app/_api.tpl
      # file://./../src/ns/demo/app/_api.tpl
      # file://./../src/context/k3d-local-ci/demo/app/_api.tpl
      - src/lib/app/_image.tpl # file://./../src/lib/app/_image.tpl
      # file://./../src/ns/demo/app/_image.tpl
      # file://./../src/context/k3d-local-ci/demo/app/_image.tpl
      # file://./../src/lib/app/openresty.tpl
      - src/ns/demo/app/openresty.tpl # file://./../src/ns/demo/app/openresty.tpl
      # file://./../src/context/k3d-local-ci/demo/app/openresty.tpl
    store:
      <<: *store
      __: src/_
      image: openresty/openresty
      name: openresty
      v: 1.21.4.1-0-alpine
```
Здесь мы сначала искали общие параметры чарта:
```yml
chart: # general values for all chart releases
  app:
    - general
```
И нашли, причём в глобальных параметрах для всех чартов.
Потом искали:
```yml
chart: # general values for all chart releases
  app:
    - volume-tz-msk
```
И тоже нашли, но уже в общих параметрах конкретного чарта.
Потом начали искать зависимости релиза:
```yml
          deps:
            - _api # http://localhost/api/openresty/
            - _image
```
И нашли обе в "библиотечных" параметрах чарта.
В конце уже стандартный поиск, как в прошлом релизе, привёл нас только к параметрам этого релиза, определённым только для данного неймспейса.

## Следующие шаги

Мы разобрали не большую, но критичную часть возможностей движка. Дальнейшие детали, возможно, имеет смысл отражать в режиме [вопросов и ответов](https://t.me/helmci).

## Вопросы и ответы

- В чём разница между модулем и паттерном?
  - **паттерн** — способ генерации YAML-списка релизов, выше упоминаются несколько паттернов, рассмотрим их немного подробнее:
    - ["raw"](../helmwave/raw.tpl) позволяет писать релизы вручную [в файле](../src/raw/_.tpl)
    - ["simple - multycluster by tags"](../helmwave/simple.tpl) опирается на максимально простую структуру файлов в папке **'src/simple/*'**, чуть более продвинуто, чем ["apps per namespace"](https://docs.helmwave.app/0.41.x/examples/apps-per-ns/)
    - ["main (src) - current cluster by tags"](../helmwave/src.tpl) — этот паттерн, собственно, имеет поддержку модульности и описан подробнее выше
      - он имеет подпаттерны расширения:
        - системное расширение ["docker-compose"](../helmwave/compose.tpl)
          - [пример использования](quick_start.md) в своём репозитории (модуле)
          - [демо-пример для wordpress](../src/dc/demo-wp/docker-compose.yml) в модуле "ci"
            - [пример подключения](../src/lib/demo-wp.yml) с переопределениями для произвольных частей
          - [рабочий пример для homer](https://github.com/HelmCI/ci-mon/tree/main/src/dc/homer) в модуле "ci-mon"
            - [пример подключения](https://github.com/HelmCI/ci-mon/blob/main/src/lib/mon-homer.yml)
              - возможность переопределения для произвольных частей сделана для возможности [автообновления](https://github.com/HelmCI/ci-mon/blob/main/bin/homer.mk) из источника
        - и пример прикладного расширения ["release generation from Store"](../helmwave/db.tpl) в будущем будет вынесен из движка, когда будет реализована возможность подключения своих плагинов к нему в своих модулях. К слову, сейчас есть такая возможность, но требует много копипасты из движка
  - **модуль** — папка, которую можно, в частности, превратить в самодостаточный Git-сабмодуль
    - два особенно выделенных модуля:
      - это корень нашего репозитория — его содержимое имеет максимальный приоритет
      - модуль "ci" является обязательной зависимостью у всех модулей и сам, в свою очередь, не имеет зависимостей
    - в остальном все модули идентичны по функционалу и структуре и полностью независимы и автономны — это позволяет выносить их в отдельные репозитории с сохранением их работоспособности без изменений
