SHELL=/bin/bash

# to see all colors, run
# bash -c 'for c in {0..255}; do tput setaf $c; tput setaf $c | cat -v; echo =$c; done'
# the first 15 entries are the 8-bit colors

BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
WHITE        := $(shell tput -Txterm setaf 7)

RESET := $(shell tput -Txterm sgr0)

.PHONY: ci help

.DEFAULT_GOAL := help

ci:
	@echo "${BLUE}Executing CI checkings...${RESET}"
	@echo ""
	mix compile --warning-as-errors
	mix test
	mix credo --strict
	mix format --check-formatted
	mix dialyzer
	@echo ""
	@echo "${BLUE}Done, all passed!${BLUE}"

help:
	@echo ""
	@echo "make ci - to run CI tests"
	@echo "make help - show this"
	@echo ""
