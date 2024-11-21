helmwave_plan = tmp/.$K
helmwave_plan_new = $(helmwave_plan)-new

helmwave_fatal = helmwave --log-level=fatal
helmwave_yml_args = --templater=gomplate -f helmwave-$K.yml
helmwave_yml_cmd = helmwave --log-timestamps yml $(helmwave_yml_args)
helmwave_build_args = --yml -p $(helmwave_plan)
helmwave_build_fatal = $(helmwave_fatal) build $(helmwave_yml_args)
helmwave_build_offline = $(helmwave_build_fatal) --diff-mode=none
helmwave_graph_cmd = helmwave graph --dependencies $(helmwave_build_args)
helmwave_yml:
	$(helmwave_yml_cmd)
helmwave_dump:
	$(helmwave_build_fatal) $(helmwave_build_args)
helmwave_dump_changed:
	$(helmwave_build_fatal) $(helmwave_build_args) 2>&1 | grep --color=auto 'has changed:' ||:
helmwave_dump_offline:
	$(helmwave_build_offline) $(helmwave_build_args)
helmwave_list:
	$(helmwave_fatal) list $(helmwave_build_args) $(helmwave_yml_args) --build=false
helmwave_diff:
	$(helmwave_fatal) diff live --plandir=$(helmwave_plan_new) 
helmwave_graph:
	$(helmwave_graph_cmd)
