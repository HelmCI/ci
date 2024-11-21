# LiveReload examples

Below are examples of how can be used [automation](watch.mk):

```sh
brew info watchexec
HELMWAVE_TAGS=core K=local make helmwave_dump watch_diff # build offline & switch context
T=core/0 make watch_build # live & filter yml
T=core/0 make watch_yml   # debug store
K=local make helmwave_yml   # refresh store
make watch W=demo # live debug
```
