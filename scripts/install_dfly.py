#!/usr/bin/env python3
#
# Python Pexpect Script, to remote control the DragonFly OS Installation inside a VM via the serial console
#
# Created by: Diederik de Groot (2018)

import sys
import pexpect
import time
class LogAdapter(object):
    def __init__(self, logger):
        self.logger = logger
    def write(self, data):
        data = data.replace('\r\n','\n').replace('\r','\n').replace('\n\n', '\n');
        if data:  # only non-blank
           self.logger.write(data)
    def flush(self):
        pass 
        
cmd = "qemu-system-x86_64 "
cmd += "-smp 4,sockets=1,cores=4,threads=2,maxcpus=4 "
cmd += "-enable-kvm "
cmd += "-cdrom DragonFly-x86_64-LATEST-ISO.iso "
cmd += "-device virtio-scsi-pci,id=scsi1 -device scsi-hd,drive=drive0,bus=scsi1.0 -drive file=image.img,if=none,format=qcow2,id=drive0 "
cmd += "-m 2048 -device e1000,netdev=net1 -netdev user,id=net1,hostfwd=tcp::10022-:22 "
cmd += "-boot order=c,menu=off,splash-time=0 "
cmd += "-no-reboot "
cmd += "-nographic "
cmd += "-serial mon:stdio"
print("Starting: ", cmd)
logger=LogAdapter(sys.stdout);
df = pexpect.spawn(cmd, encoding='utf-8', timeout=1200, logfile=logger)
df.expect("Escape to loader prompt")
df.expect("Booting in 8 seconds")
df.send("\x1b")		# send the esc key
print("\nSent ESC")
df.expect("OK")
df.sendline("set kernel_options=-Ch")
df.expect("OK")
df.sendline("set console=comconsole")
df.expect("OK")
df.logfile = None	# Suppress twirl ("|/\/") logging
df.sendline("boot")
print("\n\nBooting DragonFlyBSD (Stand-By)...")
df.expect("The DragonFly Project.")
df.logfile = logger	# Reinstate logging
df.expect("login:")
df.sendline("root")
time.sleep(1)
df.send('\r')
df.sendline("sh")
df.expect("#")
df.sendline("export PS1='>>> '")
df.expect(">>> ")
df.expect(">>> ")
df.sendline('dhclient em0')
df.expect(">>> ")
df.sendline('sleep 3')
df.expect(">>> ")
df.sendline('ifconfig em0')
df.expect('>>> ')
df.sendline("curl -s https://raw.githubusercontent.com/dkgroot-ldc/ldc_dragonfly_ci/master/scripts/install_dfly.sh -o install_dfly.sh")
df.expect(">>> ")
df.sendline("chmod a+x ./install_dfly.sh")
df.expect(">>> ")
df.sendline("./install_dfly.sh")
df.expect(">>> ")
df.sendline("sync")
if df.isalive():
    df.sendline('halt')
    df.expect("The operating system has halted.")
    df.expect("Please press any key to reboot.")
    df.send("y")
    df.close()
