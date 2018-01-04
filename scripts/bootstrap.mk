# Build DMD Bootrap
# Created by: Diederik de Groot (2018)

GIT:=git
GITUSER:=dkgroot
QUIET:=
BUILD:=debug
MODEL:=64
NCPU:=4
INSTALL_DIR:=$(shell pwd)/bootstrap/install

.PHONY: all

all: test_ldc

clone_bootstrap:
	$(GIT) clone -b ltsmaster https://github.com/ldc-developers/ldc.git bootstrap
	$(GIT) -C bootstrap/runtime clone -b ldc-ltsmaster https://github.com/dkgroot-ldc/druntime.git
	cd bootstrap/runtime/druntime; $(GIT) checkout -b unittest
	cd bootstrap/runtime/druntime; $(GIT) pull origin dragonfly-ltsmaster ldc-ltsmaster_dragonflybsd ldc-ltsmaster_posix  --commit -q --squash;
	$(GIT) -C bootstrap/runtime clone -b ldc-ltsmaster https://github.com/ldc-developers/phobos.git
	$(GIT) -C bootstrap/tests/d2 clone -b dragonfly-ltsmaster https://github.com/dkgroot-ldc/dmd-testsuite.git
	touch $@

build_ldc_cmake: clone_bootstrap
	[ -d bootstrap/build ] || mkdir bootstrap/build
	cd bootstrap/build; cmake -G Ninja -DLLVM_CONFIG=/usr/local/bin/llvm-config38 ..
	touch $@

build_ldc_ninja: build_ldc_cmake
	cd bootstrap/build; ninja -j$(NCPU)
	touch $@

druntime_unittest: build_ldc_ninja
	cd bootstrap/build; ninja -j$(NCPU) druntime-ldc-unittest-debug druntime-ldc-unittest

phobos_unittest: build_ldc_ninja
	cd bootstrap/build; ninja -j$(NCPU) phobos2-ldc-unittest-debug phobos2-ldc-unittest

run_tests: build_ldc_ninja
	cd bootstrap/build; ctest -V -R --output-on-failure "llvm-ir-testsuite|ldc2-unittest|lit-tests"
	cd bootstrap/build; ctest -j$(NCPU) --output-on-failure -E "dmd-testsuite|llvm-ir-testsuite"
	
build_bootstrap: clone_bootstrap build_ldc_cmake build_ldc_ninja

test_bootstrap: druntime_unittest phobos_unittest run_tests
