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
	@echo "  IMAGE   Docker image name (default: devcontainers-base:local)"
	@echo "  GH_PAT  Limited-scope GitHub Personal Access Token for gh CLI auth (optional)"

build:
	devcontainer build \
		--workspace-folder . \
		--image-name $(IMAGE)

test:
	./test.sh $(IMAGE)
