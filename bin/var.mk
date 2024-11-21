var--%:
	@echo $* = $($*)
# BASH_VERSION:
# 	echo $$$@

# https://stackoverflow.com/questions/10858261/how-to-abort-makefile-if-variable-not-set
# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
var_check_defined = \
	$(strip $(foreach 1,$1, \
		$(call var__check_defined,$1,$(strip $(value 2)))))
var__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))$(if $(value @), \
				required by target `$@')))
var-need-%:
	@:$(call var_check_defined, $*)

var_os = $(shell uname)
ifeq ($(var_os), Darwin)
var_ln = ln -svhw
else
var_ln = ln -sv
endif

