#!/usr/bin/env bash
#
# if the cache contains the latest dragonfly timestamp and the vm has already been build, then use it
# otherwise download the latest iso, create an image fs and setup a complete dragonfly OS in a kvm accelerated vmm
# the installation of the os is controlled via a python-pexpect script
#
# Created by: Diederik de Groot (2018)

if [ -d $SEMAPHORE_CACHE_DIR ]; then
      pushd $SEMAPHORE_CACHE_DIR
      curl -s http://ftp.tu-clausthal.de/pub/DragonFly/snapshots/df_timestamp.txt -o df_timestamp.txt
      if [ ! -f prev_timestamp.txt ] || [ ! -z "`diff df_timestamp.txt prev_timestamp.txt`" ]; then
            [ -f image.qcow ] && rm image.qcow
            sudo apt install -y python3-cairo python3-gi python3-gi-cairo python3-sqlalchemy python3-psutil python3-pip
            sudo pip3 install pexpect
            curl -s http://ftp.tu-clausthal.de/pub/DragonFly/snapshots/x86_64/DragonFly-x86_64-LATEST-ISO.iso.bz2 -o - |pbzip2 -d -c - >DragonFly-x86_64-LATEST-ISO.iso
            qemu-img create -f qcow2 image.img 10G
            ls -sl --block-size 1 image.img
            sudo ../scripts/install_dfly.py;
            ls -sl --block-size 1 image.img
            cp df_timestamp.txt prev_timestamp.txt;
            echo "DragonFly has been installed"
            rm DragonFly-x86_64-LATEST-ISO.iso
      else
            echo "Latest version of DragonFly is already installed, no need to reinstall, using cached version"
      fi
      popd
fi
