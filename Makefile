MAKEFILE_PATH		:= $(realpath $(firstword $(MAKEFILE_LIST)))
GIT_ROOT		:= $(shell dirname $(MAKEFILE_PATH))
VENV_ROOT		:= $(GIT_ROOT)/.venv

PACKAGE_NAME		:= yourpackagename
MAIN_CLI_NAME		:= your-package-name
REQUIREMENTS_FILE	:= development.txt

PACKAGE_PATH		:= $(GIT_ROOT)/$(PACKAGE_NAME)
REQUIREMENTS_PATH	:= $(GIT_ROOT)/$(REQUIREMENTS_FILE)
MAIN_CLI_PATH		:= $(VENV_ROOT)/bin/$(MAIN_CLI_NAME)
export VENV		?= $(VENV_ROOT)

######################################################################
# Phony targets (only exist for typing convenience and don't represent
#                real paths as Makefile expects)
######################################################################

# default target when running `make` without arguments
all: $(MAIN_CLI_PATH)

# creates virtualenv
venv: $(VENV)

# updates pip and setuptools to their latest version
develop: $(VENV)/bin/python $(VENV)/bin/pip

# installs the requirements and the package dependencies
setup: $(MAIN_CLI_PATH)

# Convenience target to ensure that the venv exists and all
# requirements are installed
dependencies: develop setup

# Run all tests, separately
tests: unit functional  # runs all tests

# -> unit tests
unit: | $(VENV)/bin/nosetests  # runs only unit tests
	@$(VENV)/bin/nosetests --cover-erase tests/unit

# -> functional tests
functional:| $(VENV)/bin/nosetests  # runs functional tests
	@$(VENV)/bin/nosetests tests/functional

# run main command-line tool
run: | $(VENV)/bin/python
	@$(MAIN_CLI_PATH) --help

# Pushes release of this package to pypi
push-release:  # pushes distribution tarballs of the current version
	$(VENV)/bin/twine upload dist/*.tar.gz

# Prepares release of this package prior to pushing to pypi
build-release:
	rm -rf ./dist  # remove local packages
	$(VENV)/bin/twine check dist/*.tar.gz
	$(VENV)/bin/python setup.py build sdist

# Convenience target that runs all tests then builds and pushes a release to pypi
release: tests build-release push-release
	$(MAKE) build-release
	$(MAKE) push-release

# Convenience target to delete the virtualenv
clean:
	@rm -rf .venv

# Convenience target to format code with black with PEP8's default
# 80 character limit per line
black: $(VENV)/bin/black
	@$(VENV)/bin/black -l 80 $(PACKAGE_PATH) tests

##############################################################
# Real targets (only run target if its file has been "made" by
#               Makefile yet)
##############################################################

# creates virtual env if necessary and installs pip and setuptools
$(VENV): $(REQUIREMENTS_PATH)  # creates $(VENV) folder if does not exist
	echo "Creating virtualenv in $(VENV_ROOT)" && python3 -mvenv $(VENV)

# installs pip and setuptools in their latest version, creates virtualenv if necessary
$(VENV)/bin/python $(VENV)/bin/pip: # installs latest pip
	@test -e $(VENV)/bin/python || $(MAKE) $(VENV)
	@test -e $(VENV)/bin/pip || $(MAKE) $(VENV)
	@echo "Installing latest version of pip and setuptools"
	@$(VENV)/bin/pip install -U pip setuptools

 # installs latest version of the "black" code formatting tool
$(VENV)/bin/black: | $(VENV)/bin/pip
	$(VENV)/bin/pip install -U black

# installs this package in "edit" mode after ensuring its requirements are installed
$(MAIN_CLI_PATH): | $(VENV) $(VENV)/bin/pip $(VENV)/bin/python $(REQUIREMENTS_PATH)
	$(VENV)/bin/pip install --force-reinstall -r $(REQUIREMENTS_PATH)
	$(VENV)/bin/pip install -e .

# ensure that REQUIREMENTS_PATH exists
$(REQUIREMENTS_PATH):
	@echo "The requirements file $(REQUIREMENTS_PATH) does not exist"
	@echo ""
	@echo "To fix this issue:"
	@echo "  edit the variable REQUIREMENTS_NAME inside of the file:"
	@echo "  $(MAKEFILE_PATH)."
	@echo ""
	@exit 1

###############################################################
# Declare all target names that exist for convenience and don't
# represent real paths, which is what Make expects by default:
###############################################################

.PHONY: \
	all \
	black \
	build-release \
	clean \
	dependencies \
	develop \
	push-release \
	release \
	setup \
	run \
	tests \
	unit \
	functional \
	tdd-functional \
	tdd-unit
