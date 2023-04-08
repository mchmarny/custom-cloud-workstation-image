VERSION   ?=$(shell cat .version)
REGISTRY  ?=us-west1-docker.pkg.dev/cloudy-build/custom-cloud-workstation-image
IMAGE     ?=ws-dev

all: help

.PHONY: version
version: ## Prints the current demo app version
	@echo $(VERSION)

.PHONY: build
build: ## Build container image
	docker build -t $(REGISTRY)/$(IMAGE):$(VERSION) -t latest .

.PHONY: push
push: ## Pushes container image to the registry
	docker image push --all-tags $(REGISTRY)/$(IMAGE)

.PHONY: run
run: ## Run previously built container image
	docker container run --rm -it $(REGISTRY)/$(IMAGE):$(VERSION)

.PHONY: tag
tag: ## Creates release tag
	git tag -s -m "demo version bump to $(VERSION)" $(VERSION)
	git push origin $(VERSION)

.PHONY: tagless
tagless: ## Delete the current release tag 
	git tag -d $(VERSION)
	git push --delete origin $(VERSION)

.PHONY: help
help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk \
		'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
