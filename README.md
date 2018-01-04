[![Build Status](https://semaphoreci.com/api/v1/dkgroot/dmd_dragonfly_ci/branches/master/badge.svg)](https://semaphoreci.com/dkgroot/dmd_dragonfly_ci)

# CI for D-lang dmd on DragonFly

- bootstrap dmd on dragonfly
  - using v2.068.1 branch for dmd
  - using dmd-cxx branch for druntime and phobos
- publish bootstrap_dmd.tar.bz2
- build dmd from master branch
- build druntime from master branch
- build phobos from master branch
- run druntime unittests
- run phobos unittests
- run dmd unittests
- run dmd integration tests
- publish master_dmd.tar.bz2
