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
	$(GIT) clone -b dragonfly-ltsmaster https://github.com/dkgroot-ldc/ldc.git bootstrap
	$(GIT) -C bootstrap/runtime clone -b dragonfly-ltsmaster https://github.com/dkgroot-ldc/phobos.git
	$(GIT) -C bootstrap/runtime clone -b ldc-ltsmaster https://github.com/dkgroot-ldc/druntime.git
	cd bootstrap/runtime/druntime; $(GIT) checkout -b unittest
	cd bootstrap/runtime/druntime; $(GIT) pull origin dragonfly-ltsmaster ldc-ltsmaster_dragonflybsd ldc-ltsmaster_posix  --commit -q --squash;
	$(GIT) -C bootstrap/tests/d2 clone -b dragonfly-ltsmaster https://github.com/dkgroot-ldc/dmd-testsuite.git
	touch $@

build_ldc: clone_bootstrap
	[ -d bootstrap/build ] || mkdir bootstrap/build
	cd bootstrap/build; cmake -G Ninja -DLLVM_CONFIG=/usr/local/bin/llvm-config38 ..
	cd bootstrap/build; ninja -j$(NCPU)
	touch $@

druntime_unittest: build_ldc
	cd bootstrap/build; ninja -j$(NCPU) druntime-ldc-unittest-debug druntime-ldc-unittest

phobos_unittest: build_ldc
	cd bootstrap/build; ninja -j$(NCPU) phobos2-ldc-unittest-debug phobos2-ldc-unittest

run_tests: build_ldc
	cd bootstrap/build; ctest -V -R --output-on-failure "llvm-ir-testsuite|ldc2-unittest|lit-tests"

run_testsuite: build_ldc
	cd bootstrap/build; ctest -j$(NCPU) --output-on-failure -E "dmd-testsuite|llvm-ir-testsuite"
	
build_bootstrap: build_ldc
