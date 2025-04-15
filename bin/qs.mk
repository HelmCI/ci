qs_init:
	cd .. &&\
		curl -LO https://raw.githubusercontent.com/HelmCI/ci-infra/refs/heads/main/Makefile &&\
		curl -LO https://raw.githubusercontent.com/HelmCI/ci-infra/refs/heads/main/helmwave.yml.tpl
