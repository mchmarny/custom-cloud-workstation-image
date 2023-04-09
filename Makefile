VERSION     ?=$(shell cat ./version)
REGISTRY    ?=us-docker.pkg.dev/cloudy-demos/ws-images
IMAGE       ?=go-code

all: help

.PHONY: version
version: ## Prints the current demo app version
	@echo $(VERSION)

# base 
.PHONY: image
image: ## Build base container image
	docker image build \
		--platform linux/amd64 \
		-t $(REGISTRY)/$(IMAGE):$(VERSION) \
		-t $(REGISTRY)/$(IMAGE):latest \
		.
	docker image push $(REGISTRY)/$(IMAGE):$(VERSION)
	docker image push $(REGISTRY)/$(IMAGE):latest

.PHONY: run
run: ## Run previously built base container image
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
