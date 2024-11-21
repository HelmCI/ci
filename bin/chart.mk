CHARTS_PATH = charts

chart_map = charts.ini
-include $(chart_map)

charts = $(notdir $(wildcard $(CHARTS_PATH)/*))
chart_first_word = $(word 2,$(subst --, ,$1))

define chart_pull_from_repo # (chart, repo_name, version) pull from repo 
	$(info helm search: $(shell helm search hub --list-repo-url --max-col-width 70 $1 | grep '$2' | head -c 100))
	$(info untar: $1:$3 from $2)
	rm -rf $(CHARTS_PATH)/$1 ||:
	helm pull $3 --untar -d $(CHARTS_PATH) $2/$1
endef

define chart_pull # (chart, repo_url, version) pull from url with tmp repo 
	$(info pull: $1:$3 from $2)
	helm repo add $@ $2
	$(call chart_pull_from_repo,$1,$@,$3)
	helm repo remove $@
endef

chart_pull_run = $(call chart_pull,$1,$(chart-$1)) # file://./../charts.ini <-- repos map
$(charts:%=chart--%):
	@echo $(call chart_pull_run,$(call chart_first_word,$@))

CHART ?=
CHART_REPO ?=
chart_add:
	@:$(call var_check_defined, CHART, 			example "minio" )
	@:$(call var_check_defined, CHART_REPO, example "https://charts.min.io" )
	mkdir -p $(CHARTS_PATH)/$(CHART)
	echo chart-$(CHART) = $(CHART_REPO) >> $(chart_map)
	@echo -e "CHART: $(RED)$(CHART)$(NORMAL) will be $(GREEN)updated$(NORMAL)! Press enter to continue ..."; read
	make chart--$(CHART)
chart_add_example:
	@echo make chart_add CHART=tempo CHART_REPO=https://grafana.github.io/helm-charts
