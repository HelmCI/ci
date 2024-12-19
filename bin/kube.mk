KUBE_CURRENT_CONTEXT = $(shell kubectl config current-context)

kubectx-get_current: # kubectx -c
	@echo $(KUBE_CURRENT_CONTEXT) 
kubectx-set:
	kubectx $(CONTEXT)
	make kubectx-get_current
