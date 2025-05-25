# Define supported distributions
SUPPORTED_DISTROS := debian11 debian12 ubuntu2004 ubuntu2404
DEFAULT_DISTRO := debian11

.PHONY: molecule-test molecule-test-all lint help check-prereqs $(addprefix molecule-test-,$(SUPPORTED_DISTROS)) test

help:
	@echo "Available targets:"
	@echo "  molecule-test              - Run molecule cluster tests with default distro ($(DEFAULT_DISTRO))"
	@echo "  test                       - Alias for molecule-test"
	@echo "  molecule-test-all          - Run molecule tests against all supported distributions"
	@echo "  molecule-test-<distro>     - Run molecule tests against specific distribution"
	@echo "  lint                       - Run ansible-lint"
	@echo "  help                       - Show this help message"
	@echo ""
	@echo "Supported distributions:"
	@for distro in $(SUPPORTED_DISTROS); do \
		echo "  - $$distro"; \
	done
	@echo ""
	@echo "Examples:"
	@echo "  make test                             # Test with $(DEFAULT_DISTRO)"
	@echo "  make molecule-test                    # Test with $(DEFAULT_DISTRO)"
	@echo "  make molecule-test-ubuntu2004         # Test with Ubuntu 20.04"
	@echo "  make molecule-test-all                # Test all distributions"

molecule-test: check-prereqs
	@echo "Running molecule tests with default distribution: $(DEFAULT_DISTRO)"
	./run-tests.sh $(DEFAULT_DISTRO)

# Convenience alias
test: molecule-test

molecule-test-all: check-prereqs
	@echo "Running molecule tests against all supported distributions..."
	@failed_distros=""; \
	for distro in $(SUPPORTED_DISTROS); do \
		echo ""; \
		echo "=== Testing with $$distro ==="; \
		if ! ./run-tests.sh $$distro; then \
			failed_distros="$$failed_distros $$distro"; \
		fi; \
	done; \
	if [ -n "$$failed_distros" ]; then \
		echo ""; \
		echo "❌ Tests failed for distributions:$$failed_distros"; \
		exit 1; \
	else \
		echo ""; \
		echo "✅ All distribution tests completed successfully!"; \
	fi

# Individual distribution targets
molecule-test-debian11: check-prereqs
	@echo "Running molecule tests with Debian 11"
	./run-tests.sh debian11

molecule-test-debian10: check-prereqs
	@echo "Running molecule tests with Debian 10"
	./run-tests.sh debian10

molecule-test-ubuntu2004: check-prereqs
	@echo "Running molecule tests with Ubuntu 20.04"
	./run-tests.sh ubuntu2004

molecule-test-centos8: check-prereqs
	@echo "Running molecule tests with CentOS 8"
	./run-tests.sh centos8

lint:
	ansible-lint

# A target that allows to check for prerequisites
check-prereqs:
	@echo "Checking prerequisites..."
	@command -v ansible >/dev/null 2>&1 || { echo "Ansible is not installed"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "Docker is not installed"; exit 1; }
	@echo "All prerequisites are installed"
