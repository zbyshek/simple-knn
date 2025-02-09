SHELL := bash
PROJECT := $(shell cat PROJECT)
VERSION := $(shell cat VERSION)
AUTHOR := "Alexey Mazurenko"

BUILD_FOLDER := build
SRC_FOLDER := .
BIN_FOLDER := bin
VENV := venv
DEPS := requirements.txt
TARGET := simple_knn_C
ifeq ($(OS),Windows_NT)
    ACTIVATE_DIR = "$(VENV)/Scripts"
    ACTIVATE = "$(ACTIVATE_DIR)/activate"
	PYTHON = python
    RELEASE_FOLDER := $(BUILD_FOLDER)/Release
	PYD_FILES = $(shell find $(RELEASE_FOLDER) -name "*.pyd")
else
    ACTIVATE_DIR = "$(VENV)/bin"
    ACTIVATE = "$(ACTIVATE_DIR)/activate"
	PYTHON = python3
    RELEASE_FOLDER := $(BUILD_FOLDER)/$(SRC_FOLDER)
	PYD_FILES = $(shell find $(RELEASE_FOLDER) -name "*.so")
endif
APP_RELEASE_DIR := release
PKG_FOLDER := pkg
PY_MODULE_FOLDER := $(PKG_FOLDER)/$(PROJECT)
SETUP_IN = python/setup.py.in
SETUP_OUT = $(PKG_FOLDER)/setup.py
INIT_IN = python/__init__.py.in
INIT_OUT = $(PY_MODULE_FOLDER)/__init__.py

### Functions ###########
# Add newline to the top of the file if it is not there
# $1 - newline
# $2 - filename
define add_newline_to_file
	if [ "$$(head -n 1 $(2))" != "$(1)" ]; then \
	  echo "$(1)" | cat - $(2) > temp.txt && mv temp.txt $(2); \
	fi
endef

## Print variables ###########
.PHONY: print_variables
print_variables:
	@echo "PROJECT is $(PROJECT)"
	@echo "VERSION is $(VERSION)"
	@echo "AUTHOR is $(AUTHOR)"
	@echo "RELEASE_FOLDER is $(RELEASE_FOLDER)"
	@echo "CPP_TEST_FOLDER is $(CPP_TEST_FOLDER)"
	@echo "CPP_LIB_FOLDER is $(CPP_LIB_FOLDER)"
	@echo "CPP_DLL_FOLDER is $(CPP_DLL_FOLDER)"
	@echo "LIB_FILES is $(LIB_FILES)"
	@echo "DLL_FILES is $(DLL_FILES)"
	@echo "APP_RELEASE_DIR is $(APP_RELEASE_DIR)"
	@echo "BIN_FOLDER is $(BIN_FOLDER)"

## Dependencies ###########
update_deps:
	@echo "Update_requirements"
	@if [ -d "$(VENV)" ]; then \
    	pip freeze > $(DEPS); \
		$(call add_newline_to_file, --extra-index-url https://download.pytorch.org/whl/cu124, $(DEPS)); \
		sed -i '/^$(PROJECT)/d' $(DEPS); \
	fi
.PHONY: uninstall_deps ## Uninstall dependencies from the virtual environment
uninstall_deps:
	@echo "Uninstalling dependencies"
	@if [ -d "$(VENV)" ]; then \
		source $(ACTIVATE) && pip uninstall -y -r $(DEPS); \
	fi


## Build targets ###########
.PHONY: build_venv ## Build virtual environment
build_venv:
	@if [ -d "$(VENV)" ]; then \
		echo "Virtual environment '$(VENV)' already exists, skipping creation."; \
	else \
		echo "Building virtual environment '$(VENV)'..."; \
		$(PYTHON) -m venv $(VENV); \
		source $(ACTIVATE) && \
			python -m pip install --upgrade pip && \
			pip install -r $(DEPS) && \
			pip install wheel; \
	fi

.PHONY: create_setup
create_setup:
	@echo "Generating $(SETUP_OUT) from $(SETUP_IN)"
	@mkdir -p $(dir $(SETUP_OUT))
	sed \
		-e 's|@PROJECT@|$(PROJECT)|g' \
		-e 's|@VERSION@|$(VERSION)|g' \
		-e 's|@AUTHOR@|$(AUTHOR)|g' \
		$(SETUP_IN) > $(SETUP_OUT)

.PHONY: create_init
create_init:
	@echo "Copying $(INIT_OUT) from $(INIT_IN)"
	@mkdir -p $(dir $(INIT_OUT))
	cp $(INIT_IN) $(INIT_OUT)

.PHONY: copy_pyds
copy_pyds:
	@echo "Copying .pyd files from $(RELEASE_FOLDER) to $(PY_MODULE_FOLDER)"
	@mkdir -p $(PY_MODULE_FOLDER)
	@for file in $(PYD_FILES); do \
		echo "Copying $$file to $(PY_MODULE_FOLDER)"; \
		cp $$file $(PY_MODULE_FOLDER); \
	done

.PHONY: build
build: build_venv
	@echo "Runnning CMake"
	@cmake -S . -B build
	@cmake --build $(BUILD_FOLDER) --config Release --target $(TARGET) -j 18

.PHONY: build_py_package
build_py_package: build_venv build create_setup create_init copy_pyds
	@echo "Building python package"
	@source $(ACTIVATE) && cd $(PKG_FOLDER) && $(PYTHON) setup.py bdist_wheel

## Release ###########
.PHONY: release
release: clean build_py_package
	@echo "Collecting artifacts..."
	@if [ -d $(APP_RELEASE_DIR) ]; then \
		echo "Cleanup $(APP_RELEASE_DIR) folder"; \
		rm -rf $(APP_RELEASE_DIR); \
	fi
	@mkdir -p $(APP_RELEASE_DIR)
	@echo "Cleaning up build directories..."
	@mkdir -p $(APP_RELEASE_DIR)/$(PROJECT)-$(VERSION)
	@cp -r $(PKG_FOLDER)/dist/* $(APP_RELEASE_DIR)/$(PROJECT)-$(VERSION)
	$(MAKE) clean
	@echo "Release process for version $(VERSION) completed successfully!"
	@echo "Release artifacts are located in the $(APP_RELEASE_DIR)/$(PROJECT)-$(VERSION) directory."

## Clean targets ###########
.PHONY: clean
clean:
	@echo "Cleaning up"
	@if [ -d $(PKG_FOLDER) ]; then rm -rf $(PKG_FOLDER); fi
	@if [ -d $(BUILD_FOLDER) ]; then rm -rf $(BUILD_FOLDER); fi
	@if [ -d dist ]; then rm -rf dist; fi
	@if [ -d diff_surfel_rasterization.egg-info ]; then rm -rf diff_surfel_rasterization.egg-info; fi