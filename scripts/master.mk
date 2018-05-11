# Build DMD Master
# Created by: Diederik de Groot (2018)

GIT:=git
GITUSER:=dkgroot
QUIET:=
BUILD:=debug
MODEL:=64
NCPU:=4
BOOTSTRAP_DMD:=$(shell pwd)/bootstrap/build/bin/ldmd2
INSTALL_DIR:=$(shell pwd)/master

.PHONY: all

#all: master_dmd.tar.bz2

clone_master:
	$(GIT) clone https://github.com/ldc-developers/ldc.git master
	cd master ; $(GIT) submodule update --init --recursive
	python -m pip install lit
	touch $@

build_ldc_cmake_ninja: clone_master
	[ -d master/build ] || mkdir master/build
	cd master/build; cmake -G Ninja -DLLVM_CONFIG=/usr/local/bin/llvm-config50 -DBUILD_SHARED_LIB=ON -DBUILD_SHARED_LIBS=ON -DD_COMPILER=$(BOOTSTRAP_DMD) ..
	touch $@

build_ldc_cmake_make: clone_master
	[ -d master/build ] || mkdir master/build
	export DMD=$(BOOTSTRAP_DMD)
	cd master/build; cmake -DLLVM_CONFIG=/usr/local/bin/llvm-config50 -DBUILD_SHARED_LIB=ON -DBUILD_SHARED_LIBS=ON -DD_COMPILER=$(BOOTSTRAP_DMD) .. 
	touch $@

build_ldc_ninja: build_ldc_cmake_ninja
	cd master/build; ninja -j$(NCPU)
	touch $@

build_ldc_make: build_ldc_cmake_make
	cd master/build; make -j$(NCPU)
	touch $@

druntime_unittest_ninja: build_ldc_ninja
	cd master/build; ninja -j$(NCPU) druntime-ldc-unittest-debug druntime-ldc-unittest

phobos_unittest_ninja: build_ldc_ninja
	cd master/build; ninja -j$(NCPU) phobos2-ldc-unittest-debug phobos2-ldc-unittest

druntime_unittest_make: build_ldc_make
	cd master/build; make -j$(NCPU) druntime-ldc-unittest-debug druntime-ldc-unittest

phobos_unittest_make: build_ldc_make
	cd master/build; make -j$(NCPU) phobos2-ldc-unittest-debug phobos2-ldc-unittest

run_tests: 
	cd master/build; ctest -V -R --output-on-failure "llvm-ir-testsuite|ldc2-unittest|lit-tests"
	cd master/build; ctest -j$(NCPU) --output-on-failure -E "dmd-testsuite-debug|llvm-ir-testsuite-debug"

build_ninja: build_ldc_ninja
build_make: build_ldc_make
test_ninja: druntime_unittest_ninja phobos_unittest_ninja run_tests
test_make: druntime_unittest_make phobos_unittest_make run_tests
