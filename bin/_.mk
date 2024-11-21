SHELL := /usr/bin/env bash
MAKES := make --no-print-directory
DOCKER := docker # nerdctl

CONTEXT	= local # for kubectl
K ?= $(KUBE_CURRENT_CONTEXT)

# Newline for '$(subst $N,,$1)':
define N


endef

tmp src:
	@mkdir -p $@; echo create dir: $@
