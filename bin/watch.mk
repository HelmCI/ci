watchexec = watchexec -e tpl,mk,js,yml -i 'tmp/**' -i 'helmwave-*' \
	--print-events --fs-events=modify
watch_auto_yml = false
watch_prefix =

watch_diff:
	$(watchexec) --timings -- ' date ;\
		$(helmwave_build) --diff-mode=none --yml=$(watch_auto_yml) \
			-p $(helmwave_plan_new) ;\
		$(helmwave_no_log) diff plan \
			--plandir2="$(watch_prefix)$(helmwave_plan)" \
			--plandir1="$(helmwave_plan_new)" '

watch_diff_yml: watch_auto_yml=true
watch_diff_yml: watch_diff

watch_diff_parent: watch_prefix=../
watch_diff_parent: watch_diff

watch_build:
	$(watchexec) --timings -- ' date ;\
		$(helmwave_build) --skip-unchanged --yml '
watch_yml:
	$(watchexec) --timings -- '$(helmwave_yml_cmd)'
watch_debug:
	$(watchexec) -- date

watch_need_W:
	@:$(call var_check_defined, W, need watch tags W=)
watch_offline: watch_need_W
	HELMWAVE_TAGS=$W $(MAKES) helmwave_dump_offline watch_diff_yml
watch: watch_need_W
	HELMWAVE_TAGS=$W $(MAKES) helmwave_dump					watch_diff_yml
watch_context:
	HELMWAVE_TAGS=$K $(MAKES) helmwave_dump					watch_diff_yml

watch_graph: watch_need_W
	HELMWAVE_TAGS=$W \
	$(watchexec) --timings -- ' date ;\
		$(helmwave_graph_cmd) '
