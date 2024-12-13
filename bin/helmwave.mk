helmwave_pwd := $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))

helmwave_plan = tmp/.$K
helmwave_plan_new = $(helmwave_plan)-new

helmwave_no_log = helmwave --log-level=warning # fatal
helmwave_yml_args = --templater=gomplate -f helmwave-$K.yml
helmwave_yml_cmd = helmwave --log-timestamps yml $(helmwave_yml_args)
helmwave_build_args = --yml -p $(helmwave_plan)
helmwave_build = $(helmwave_no_log) build $(helmwave_build_args) $(helmwave_yml_args)
helmwave_graph_cmd = 
helmwave_yml:
	$(helmwave_yml_cmd)
helmwave_dump:
	$(helmwave_build)
helmwave_dump_context:
	$(helmwave_build) -t $K
helmwave_dump_changed:
	$(helmwave_build) 2>&1 | grep --color=auto -E 'has changed:|FATAL|WARNING' ||:
helmwave_dump_offline:
	$(helmwave_build) --diff-mode=none
helmwave_list:
	$(helmwave_no_log) list $(helmwave_build_args) $(helmwave_yml_args) --build=false
helmwave_diff:
	$(helmwave_no_log) diff live --plandir=$(helmwave_plan_new) 
helmwave_graph:
	helmwave graph --dependencies $(helmwave_build_args)

helmwave_completion_fish: # https://github.com/helmwave/helmwave/issues/1048
	cp $(helmwave_pwd)/helmwave.fish ~/.config/fish/functions/helmwave.fish

helmwave_test: helmwave_yml helmwave_dump helmwave_dump_context helmwave_dump_changed helmwave_dump_offline helmwave_graph helmwave_list
