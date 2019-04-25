USERNAME=maguesse
NAME=$(shell basename $(CURDIR))

VERSION=0.1
TAG=tag

IMAGE=$(USERNAME)/$(NAME)

DOCKER = $(shell which docker)
DOCKER_BUILD_CONTEXT=.
DOCKER_FILE_PATH=Dockerfile

MAKEFLAGS += -rR
MAKEFLAGS += --no-print-directory
SHELL=/bin/bash
SUBDIRS = $(shell find . -mindepth 2 -name $(DOCKER_FILE_PATH) -exec dirname {} \;)
.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)
$(SUBDIRS):
	@$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: help
help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: pre-build docker-build post-build build

ifeq (,$(wildcard $(DOCKER_FILE_PATH)))
# No Dockerfile, nothing to build
BUILD_TARGETS =
else
BUILD_TARGETS = pre-build docker-build post-build
endif

build: $(SUBDIRS) $(BUILD_TARGETS) ## Build the container

pre-build:

post-build:

docker-build: $(DOCK)
	@echo Build image $(IMAGE):$(VERSION)
	@$(DOCKER) build --rm --force-rm $(DOCKER_BUILD_ARGS) -t $(IMAGE):$(VERSION) $(DOCKER_BUILD_CONTEXT) -f $(DOCKER_FILE_PATH)
	@echo Tag image $(IMAGE):latest
	@$(DOCKER) tag $(IMAGE):$(VERSION) $(IMAGE):latest


.PHONY: help clean purge

clean: $(SUBDIRS) ## Clean
	$(call docker-remove-image,$(IMAGE),$(VERSION))
	$(call docker-remove-image,$(IMAGE),latest)

prune: ## Purge
	-$(call docker-remove-dangling,image)
	-$(call docker-remove-dangling,volume)
	-$(call docker-remove-dangling,network)

## Utility functions

define docker-remove-image
@$(DOCKER) image inspect ${1}:${2} > /dev/null 2>&1;\
if [ $$? -eq 0 ]; \
then \
	echo Removing docker image ${1}:${2} ;\
	$(DOCKER) image rm ${1}:${2} ;\
fi
endef

define docker-remove-dangling
@echo Removing dangling ${1}s
@$(DOCKER) ${1} prune --force
endef
