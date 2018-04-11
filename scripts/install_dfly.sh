#!/bin/sh
#
# Automatically setup dragonfly os with simple defaults
# 
# Free after : https://github.com/DragonFlyBSD/DragonFlyBSD/blob/master/nrelease/root/README
#
# Created by: Diederik de Groot (2018)
#set -uexo pipefail
#set -ux
set -e

disk=da0
rootdev=da0s1a
swapdev=da0s1b
hostname=dfly.travis.com
#rootpassword="dmd"
username="dmd"
fullname="dlang dmd compiler"
#password="dmd"
# OPTIONAL STEP: If your disk is already partitioned and you
# have a spare primary partition on which you want to install
# DragonFly, skip this step.  However, sometimes old boot
# blocks or cruft in the boot area can interfere with the
# initialization process.  A cure is to zero out the start of
# the disk before running fdisk.  Replace 'da0' with the choosen disk.
#
# WARNING: This COMPLETELY WIPES and repartitions your hard drive.
#
echo -e "\nWiping disk..."
echo "________________________________________________________________________"
dd if=/dev/zero of=/dev/${disk} bs=32k count=16
echo -e "\nPartitioning Disk..."
echo "________________________________________________________________________"
fdisk -IB ${disk} >/dev/null 2>/dev/null

# If you didn't zero the disk as above, but have a spare slice
# whose partition type you want to change to DragonFly, use fdisk(8).

# This installs boot blocks onto the HD and verifies their
# installation.  See note just above the 'reboot' below for
# things to try if it does not boot from your HD.  If you
# already have a multi-OS bootloader installed you can skip
# this step.
#
echo -e "\nConfigure boot (timeout=1)..."
echo "________________________________________________________________________"
boot0cfg -t 1 -B ${disk} 2>/dev/null
boot0cfg -v ${disk} 2>/dev/null

# This creates an initial label on the chosen slice of the HD.  If
# you have problems booting you could try wiping the first 32 blocks
# of the slice with dd and then reinstalling the label.  Replace
# 'da0s1' with the chosen slice.
#
# dd if=/dev/zero of=/dev/da0s1 bs=32k count=16
echo -e "\nCreating disklabel..."
echo "________________________________________________________________________"
disklabel64 -w ${disk}s1 auto 2>/dev/null
disklabel64 -B ${disk}s1 2>/dev/null

# Edit the label.  Create various standard partitions.  The typical
# configuration is:
#
# UFS (fstype 4.2BSD):
#	da0s1a	768m		This will be your /
#	da0s1b	4096m		This will be your swap
#	da0s1c			(leave alone)
#	da0s1d	512m		This will be your /var
#	da0s1e	512m		This will be your /tmp
#	da0s1f	8192m		This will be your /usr (min 4096m)
#	da0s1g	*		All remaining space to your /home
#
# HAMMER (fstype HAMMER):
#	da0s1a  768m		This will be your /boot; UFS
#       da0s1b	4096m		This will be your swap
#	da0s1d	*		All remaining space to your /; HAMMER
#
# An example disklabel can be found in /etc/disklabel.da0s1.
disklabel64 ${disk}s1 > /tmp/label
cat << EOF >> /tmp/label
  a:     *       0       4.2BSD
  b:     1500m   *       swap
EOF
disklabel -R ${disk}s1 /tmp/label

# Newfs (format) the various file systems.
#
# UFS:
# Softupdates is not normally enabled on the root file system because
# large kernel or world installs/upgrades can run it out of space due
# to softupdate's delayed bitmap freeing code.
#
echo -e "\nCreating UFS filesystem..."
echo "________________________________________________________________________"
newfs -U /dev/${rootdev}
swapon /dev/${swapdev}

# Mount the file systems.
#
# UFS:
echo -e "\nMounting disk on /mnt..."
mount /dev/${rootdev} /mnt

# UFS & HAMMER:
# Copy the CD onto the target.  cpdup won't cross mount boundaries
# on the source (e.g. the TMPFS remounts) or destination, so it takes
# a few commands.
#
# Note that /etc contains the config files used for booting from the
# CD itself, and /etc.hdd contains those for booting off a
# hard disk.  So it's the latter that you want to copy to /mnt/etc.
#
echo -e "\nCopying filsystem (standby this takes a while):"
echo "________________________________________________________________________"
echo -e "\nCopying root directory to /mnt:"
cpdup -x -v / /mnt  | while read line; do COUNT=$(( COUNT+1 ));if test $COUNT -eq 100 ; then echo -n .; COUNT=0;fi;done
echo -e "\nCopying var directory to /mnt/var:"
cpdup -x -v /var /mnt/var  | while read line; do COUNT=$(( COUNT+1 ));if test $COUNT -eq 100 ; then echo -n .; COUNT=0;fi;done
echo -e "\nCopying etc directory to /mnt/etc:"
cpdup -x -v /etc.hdd /mnt/etc  | while read line; do COUNT=$(( COUNT+1 ));if test $COUNT -eq 100 ; then echo -n .; COUNT=0;fi;done
echo -e "\nCopying usr directory to /mnt/usr:"
cpdup -x -v /usr /mnt/usr  | while read line; do COUNT=$(( COUNT+1 ));if test $COUNT -eq 100 ; then echo -n .; COUNT=0;fi;done

chflags -R nohistory /mnt/tmp
chflags -R nohistory /mnt/var/tmp
chflags -R nohistory /mnt/var/crash
chflags -R nohistory /mnt/usr/obj

# Cleanup.  Also, with /tmp a partition it is usually reasonable
# to make /var/tmp a softlink to /tmp.
#
echo -e "\nSetting up system:"
echo "________________________________________________________________________"
echo -e "\nCreating /tmp directory..."
chmod 1777 /mnt/tmp
rm -rf /mnt/var/tmp
ln -s /tmp /mnt/var/tmp

# Edit /mnt/etc/fstab to reflect the new mounts.  An example fstab
# file based on the above parameters exists as /mnt/etc/fstab.example
# which you can rename to /mnt/etc/fstab.
#
echo -e "\nCreating /etc/fstab file..."
cat <<EOF > /mnt/etc/fstab
/dev/${rootdev}		/               ufs     rw              1       1
proc                    /proc           procfs  rw              0       0
tmpfs			/tmp		tmpfs	rw		0	0
/dev/${swapdev}		none		swap	sw		0	0
EOF

# Save out your disklabel just in case.  It's a good idea to save
# it to /etc so you can get at it from your backups.  You do intend
# to backup your system, yah? :-)  (This isn't critical but it's a
# good idea).
#
echo -e "\nBacking up disklabel..."
disklabel da0s1 > /mnt/etc/disklabel.da0s1

# Remove or edit /mnt/boot/loader.conf so the kernel does not try
# to obtain the root file system from the CD, and remove the other
# cruft that was sitting on the CD that you don't need on the HD.
#
echo -e "\nCleaning up root fs..."
rm /mnt/boot/loader.conf
rm /mnt/boot.catalog
rm -R /mnt/README* /mnt/autorun* /mnt/index.html /mnt/dflybsd.ico /mnt/etc.hdd;

echo -e "\nSetting up boot loader..."
cat <<EOF > /mnt/boot/loader.conf
kernel_options="-Ch"
console="comconsole"
autoboot_delay="2"
rootdev="disk0s1a"
vfs.root.mountfrom="ufs:${rootdev}"
EOF

echo -e "\nSetting up rc.conf..."
ifc=$(route -n get default | fgrep interface | awk '{ print $2; }')
cat > /mnt/etc/rc.conf << EOF
ifconfig_${ifc}="DHCP"
sshd_enable="YES"
dntpd_enable="YES"
hostname="${hostname}"
dumpdev="/dev/${disk}s1b"
nfs_reserved_port_only="YES"
nfs_client_enable="YES"
rpc_umntall_enable="NO"
EOF

echo -e "\nSetting up sshd..."
sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /mnt/etc/ssh/sshd_config;
sed -i -e 's/PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config;
sed -i -e 's/PermitEmptyPasswords.*/PermitEmptyPasswords yes/' /mnt/etc/ssh/sshd_config;
echo -e "\nPermitRootLogin yes" >> /mnt/etc/ssh/sshd_config
echo -e "\nPermitEmptyPasswords yes" >> /mnt/etc/ssh/sshd_config

echo -e "\nSetting up pkg:"
echo "________________________________________________________________________"
mkdir -p /mnt/usr/local/etc/pkg/repos
curl -s https://raw.githubusercontent.com/dkgroot-ldc/ldc_dragonfly_ci/master/scripts/df-latest.conf -o /mnt/usr/local/etc/pkg/repos/df-latest.conf
# Temporarily fixup ABI Setting
# echo 'ABI="dragonfly:5.2:x86:64";' >> /mnt/usr/local/etc/pkg.conf
cp /etc/resolv.conf /mnt/etc;
chroot /mnt pkg upgrade -y

echo -e "\nInstalling packages..."
echo "________________________________________________________________________"
chroot /mnt pkg install -y gcc6 gmake bash gettext llvm38 clang38 cmake ninja libconfig sudo

echo -e "\nFinishing system:"
echo "________________________________________________________________________"
echo -e "\nSetting up sudo..."
sed -i -e 's/.*%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /mnt/usr/local/etc/sudoers;

echo -e "\nSetting up user "${username}"..."
chroot /mnt pw useradd -n ${username} -d /home/${username} -G wheel -s /usr/local/bin/bash -c "${fullname}" -m -w none
chroot /mnt pw usermod -n root -s /usr/local/bin/bash
chown 1001:1001 /mnt/home/${username};

echo -e "\nSetting up bash shell..."
curl -s https://raw.githubusercontent.com/dkgroot-ldc/ldc_dragonfly_ci/master/scripts/inputrc -o /mnt/usr/local/etc/inputrc
curl -s https://raw.githubusercontent.com/dkgroot-ldc/ldc_dragonfly_ci/master/scripts/bash.bashrc -o /mnt/usr/local/etc/bash.bashrc
cp /mnt/usr/local/etc/bash.bashrc /mnt/root/.bashrc
cp /mnt/usr/local/etc/bash.bashrc /mnt/home/${username}/.bashrc
curl -s https://raw.githubusercontent.com/dkgroot-ldc/ldc_dragonfly_ci/master/scripts/profile -o /mnt/usr/local/etc/profile
cp /mnt/usr/local/etc/profile /mnt/root/.profile
cp /mnt/usr/local/etc/profile /mnt/home/${username}/.profile
chroot /mnt pkg clean -y

echo -e "\nFinished installing DragonFlyBSD:"
echo "________________________________________________________________________"
echo -e "\nRebooting..."
#WARNING: Do not just hit reset; the kernel may not have written out
#all the pending data to your HD.  Either unmount the HD partitions
#or type halt or reboot.
#halt
#!!export The operating system has halted.
#!!expect Please press any key to reboot.
#!!send y
