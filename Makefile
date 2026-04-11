IMAGE ?= devcontainers-base:local
BUILD_ARGS ?=
ifdef GITHUB_TOKEN
BUILD_ARGS += --build-arg GITHUB_TOKEN=$(GITHUB_TOKEN)
endif

.PHONY: build test help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build  Build the devcontainer image (IMAGE=$(IMAGE))"
	@echo "  test   Run tests against the built image"
	@echo "  help   Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  IMAGE         Docker image name (default: devcontainers-base:local)"
	@echo "  GITHUB_TOKEN  Limited-scope GitHub token for gh CLI auth (optional)"

build:
	devcontainer build \
		--workspace-folder . \
		--image-name $(IMAGE) \
		$(BUILD_ARGS)

test:
	./test.sh $(IMAGE)
