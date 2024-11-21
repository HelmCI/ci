KUBE_CURRENT_CONTEXT = $(shell kubectx -c)

kubectx-get_current:
	@echo $(KUBE_CURRENT_CONTEXT)
kubectx-set:
	kubectx $(CONTEXT)
	make kubectx-get_current
