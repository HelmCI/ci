ALL = local

all_echo:
	@echo $(ALL)
all_dump:
	@$(foreach i, $(ALL), $(MAKES) helmwave_dump K=$i;)
all_yml:
	@$(foreach i, $(ALL), $(MAKES) helmwave_yml	 K=$i;)

all_dump_context:
	@$(foreach i, $(ALL), HELMWAVE_TAGS=$i $(MAKES) helmwave_dump K=$i;)
all_dump_context_changed:
	@$(foreach i, $(ALL), HELMWAVE_TAGS=$i $(MAKES) helmwave_dump_changed K=$i;)
all_dump_changed:
	@$(foreach i, $(ALL), $(MAKES) helmwave_dump_changed K=$i;)
all_dump_context_image:
	@$(foreach i, $(ALL), echo $i; HELMWAVE_TAGS=$i $(MAKES) helmwave_dump K=$i |& grep image;)

all_up_context: all_dump_context
	@echo -e "All clusters will be $(RED)upgraded$(NORMAL)! Press enter to continue ..."; read
	@$(foreach i, $(ALL), K=$i helmwave up -t $i --skip-unchanged --yml --build ;)

all_up: var-need-HELMWAVE_TAGS all_dump 
	@echo -e "All clusters will be $(RED)upgraded$(NORMAL) with tags: $(HELMWAVE_TAGS)! Press enter to continue ..."; read
	@$(foreach i, $(ALL), K=$i helmwave up --skip-unchanged --yml --build --dependencies=false;)

all_kube_get_nodes:
	@$(foreach i, $(ALL), echo == $i ==:; kubectl get nodes --no-headers --context $i;)
