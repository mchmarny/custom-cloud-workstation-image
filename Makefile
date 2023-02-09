VERSION   ?=$(shell cat app/.version)

all: help

version: ## Prints the current demo app version
	@echo $(VERSION)
.PHONY: version

push: ## Pushes all outstanding changes to the remote repository
	git add --all
	git commit -m 'demo'
	git push --all
.PHONY: push

tag: ## Creates release tag
	git tag -s -m "demo version bump to $(VERSION)" $(VERSION)
	git push origin $(VERSION)
.PHONY: tag

tagless: ## Delete the current release tag 
	git tag -d $(VERSION)
	git push --delete origin $(VERSION)
.PHONY: tagless

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk \
		'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
