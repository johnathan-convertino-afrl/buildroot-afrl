#!/bin/sh
# args from BR2_ROOTFS_POST_SCRIPT_ARGS
# $2    board name
. ${BR2_CONFIG}
set -e

#from pluto
grep -qE '^::sysinit:/bin/mount -t debugfs' ${TARGET_DIR}/etc/inittab || \
sed -i '/hostname/a\
::sysinit:/bin/mount -t debugfs none /sys/kernel/debug/' ${TARGET_DIR}/etc/inittab

grep -q /dev/mmcblk0p2 ${TARGET_DIR}/etc/fstab || echo "/dev/mmcblk0p2 /mnt/rootfs ext4 defaults 0 2" >> ${TARGET_DIR}/etc/fstab

mkdir -p ${TARGET_DIR}/mnt/rootfs
