SHELL := /bin/bash

ifndef LIGO
LIGO=docker run -u $(id -u):$(id -g) --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:next
endif
# ^ use LIGO en var bin if configured, otherwise use docker

project_root=--project-root .
# ^ required when using packages

help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

compile = $(LIGO) compile contract $(project_root) ./src/$(1) -o ./compiled/$(2) $(3)
# ^ compile contract to michelson or micheline

test = $(LIGO) run test $(project_root) ./test/$(1)
# ^ run given test file

compile: ## compile contract
	@if [ ! -d ./compiled ]; then mkdir ./compiled ; fi
	@$(call compile,main.mligo,multisig.tz)
	@$(call compile,main.mligo,multisig.json,--michelson-format json)

lambda-compile: ## compile a lambda (F=./lambdas/change_keys.mligo make lambda-compile)
# ^ helper to compile lambda from a file, used during development of lambdas
ifndef F
	@echo 'please provide an init file (F=)'
else
	@$(LIGO) compile expression $(project_root) cameligo lambda_ --init-file $(F)
	# ^ the lambda is expected to be bound to the name 'lambda_'
endif

lambda-hash: ## get packed lambda expression and hash (F=./lambdas/change_keys.mligo make lambda-hash)
# ^ helper to get packed lambda and hash
ifndef F
	@echo 'please provide an init file (F=)'
else
	@echo 'Packed:'
	@$(LIGO) run interpret $(project_root) 'Bytes.pack(lambda_)' --init-file $(F)
	@echo "Hash (sha256):"
	@$(LIGO) run interpret $(project_root) 'Crypto.sha256(Bytes.pack(lambda_))' --init-file $(F)
endif

clean: ## clean up
	@rm -rf compiled

deploy: ## deploy
	@if [ ! -f ./scripts/metadata.json ]; then cp scripts/metadata.json.dist \
        scripts/metadata.json ; fi
	@npx ts-node ./scripts/deploy.ts

install: ## install dependencies
	@if [ ! -f ./.env ]; then cp .env.dist .env ; fi
	@$(LIGO) install
	@npm i

.PHONY: test
test: ## run tests (SUITE=propose make test)
ifndef SUITE
	@$(call test,default.test.mligo)
	@$(call test,propose.test.mligo)
	@$(call test,endorse.test.mligo)
	@$(call test,execute.test.mligo)
else
	@$(call test,$(SUITE).test.mligo)
endif

lint: ## lint code
	@npx eslint ./scripts --ext .ts

sandbox-start: ## start sandbox
	@./scripts/run-sandbox

sandbox-stop: ## stop sandbox
	@docker stop sandbox
