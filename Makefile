.PHONY: test molecule-test lint help

help:
	@echo "Available targets:"
	@echo "  test         - Run a basic test on localhost"
	@echo "  molecule-test - Run molecule cluster tests"
	@echo "  lint         - Run ansible-lint"
	@echo "  help         - Show this help message"

test:
	ansible-playbook -i localhost, -c local tests/test.yml --check

molecule-test:
	./run-tests.sh

lint:
	ansible-lint

# Sample targets for deploying to real hosts
deploy-all:
	ansible-playbook -i inventory/production wireguard.yml

deploy-test:
	ansible-playbook -i tests/inventory tests/test.yml

# A target that allows to check for prerequisites
check-prereqs:
	@echo "Checking prerequisites..."
	@command -v ansible >/dev/null 2>&1 || { echo "Ansible is not installed"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "Docker is not installed"; exit 1; }
	@echo "All prerequisites are installed"
