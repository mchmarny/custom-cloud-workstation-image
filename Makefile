VERSION     ?=$(shell cat ./version)
REGISTRY    ?=us-docker.pkg.dev/cloudy-demos/ws-images
IMAGE_BASE  ?=code-go-dev-base
IMAGE_CODE  ?=code-go-dev-code

all: help

.PHONY: version
version: ## Prints the current demo app version
	@echo $(VERSION)

# base 
.PHONY: image-base
image-base: ## Build base container image
	docker image build \
		--platform linux/amd64 \
		-f base/Dockerfile \
		-t $(REGISTRY)/$(IMAGE_BASE):$(VERSION) -t latest \
		.
	docker image push --all-tags $(REGISTRY)/$(IMAGE_BASE)

.PHONY: run-base
run-base: ## Run previously built base container image
	docker container run --rm -it $(REGISTRY)/$(IMAGE_BASE):$(VERSION)

# code 
.PHONY: image-code
image-code: ## Build code container image
	docker image build \
		--platform linux/amd64 \
		-f code/Dockerfile \
		-t $(REGISTRY)/$(IMAGE_CODE):$(VERSION) -t latest \
		.
	docker image push --all-tags $(REGISTRY)/$(IMAGE_CODE)

.PHONY: run-code
run-code: ## Run previously built code container image
	docker container run --rm -it $(REGISTRY)/$(IMAGE_CODE):$(VERSION)

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
