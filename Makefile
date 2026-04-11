IMAGE ?= devcontainers-base:local

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
		--image-name $(IMAGE)

test:
	./test.sh $(IMAGE)
