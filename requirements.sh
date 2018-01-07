#!/usr/bin/env bash
#
# Make sure all required software is available
#
# Created by: Diederik de Groot (2018)
set -uexo pipefail

sudo apt-get update -q
sudo apt install -y qemu-kvm curl pbzip2
