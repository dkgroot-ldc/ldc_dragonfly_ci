#!/usr/bin/env bash
#
# Start DragonFly in a kvm accelated VM
# Note: using a temporary snapshot (on top of the image.img). All changes
#       made during the dmd build process are discarded when qemu is finished.
# Push required scripts to DragonFly VM
#
# Created by: Diederik de Groot (2018)

echo "Starting DragonFly..."
sudo qemu-system-x86_64 \
    -smp 4,sockets=1,cores=4,threads=2,maxcpus=4 \
    -enable-kvm \
    -device virtio-scsi-pci,id=scsi1 -device scsi-hd,drive=drive0,bus=scsi1.0 -drive file=$SEMAPHORE_CACHE_DIR/image.img,if=none,format=qcow2,id=drive0 \
    -snapshot \
    -m 3072 -device e1000,netdev=net1 \
    -netdev user,id=net1,hostfwd=tcp::10022-:22 \
    -boot order=c,menu=off,splash-time=0 \
    -no-reboot -daemonize \
    -monitor tcp:127.0.0.1:4555,server,nowait -chardev socket,host=127.0.0.1,port=4556,id=gnc0,server,nowait  -device isa-serial,chardev=gnc0
echo "Waiting for DragonFly to finish booting..."
sleep 50
if [ ! `pidof qemu-system-x86_64` ]; then echo "qemu failed to start"; exit 1; fi
ssh-keyscan -p10022 -H localhost >> ~/.ssh/known_hosts 2>/dev/null
scp -P 10022 scripts/execute_return_exitcode.sh root@localhost:/root/
scp -P 10022 scripts/bootstrap.mk root@localhost:/root/
scp -P 10022 scripts/master.mk root@localhost:/root/
echo "DragonFly Started..."
