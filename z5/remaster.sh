#!/bin/bash
#need for work: 
#   Squashfs tools
#   XZ
#   cpio
#   iso tools (mkisofs)
#   xorriso (libisoburn)
#   syslinux
#   usual GNU tools


set -e
#/home/mtbuser/vizor/z5/ISO/install-amd64-minimal-20220214T095322Z.iso
if [ $# -ne 1 ]; then
	echo "Usage: $0 image.iso"
	exit 1
fi

mnt="$(pwd)"/mount
src="$(pwd)"/sorc
mISO="$(pwd)"/modISO
oSQFS="$(pwd)"/sqfs-old
mSQFS="$(pwd)"/sqfs-mod
oinitrd="$(pwd)"/oinitrd
ninitrd="$(pwd)"/ninitrd

#renice -n 19 $$

#echo "mount ISO image..."
rm -rf $mnt $src $mISO
mkdir $mnt $src $mISO
mount -oloop,ro "$1" $mnt/
cp -a $mnt/* $src/
umount $mnt
#rm -rf $mnt
cp -ax --reflink=always $src/. $mISO


#echo "Extracting squashfs..."
rm -rf $oSQFS $mSQFS
mkdir $oSQFS $mSQFS
unsquashfs -f -d $oSQFS/ $src/image.squashfs
echo -n > $src/image.squashfs
cp -ax --reflink=always $oSQFS/. $mSQFS


#echo "Extracting initrd..."
rm -rf $oinitrd $ninitrd
mkdir $oinitrd $ninitrd
( cd $oinitrd; unxz < ../$src/isolinux/gentoo.igz | cpio -idv )
echo -n > $src/isolinux/gentoo.igz
cp -ax --reflink=always $oinitrd/. $ninitrd


#supported
#cp: failed to clone '/home/mtbuser/vizor/z5/sqfs-mod/./var/db/pkg/virtual/libintl-0-r2/IUSE_EFFECTIVE' from '/home/mtbuser/vizor/z5/sqfs-old/./var/db/pkg/virtual/libintl-0-r2/IUSE_EFFECTIVE': Operation not supported
#cp: failed to clone '/home/mtbuser/vizor/z5/sqfs-mod/./var/db/pkg/virtual/libintl-0-r2/KEYWORDS' from '/home/mtbuser/vizor/z5/sqfs-old/./var/db/pkg/virtual/libintl-0-r2/KEYWORDS': Operation not supported