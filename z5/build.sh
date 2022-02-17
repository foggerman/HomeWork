#!/bin/bash

set -e


mISO="$(pwd)"/modISO
mSQFS="$(pwd)"/sqfs-mod
ninitrd="$(pwd)"/ninitrd


if [ $# -ne 1 ]; then
	echo "Usage: $0 image.iso"
	exit 1
fi

if [ -e $1 ]; then
	echo "$1 already exists!"
	# TODO prompt for overwrite
	exit 1
fi

#renice -n 19 $$

#echo "Making squashfs..."
rm -f $mISO/image.squashfs
mksquashfs $mSQFS/ $mISO/image.squashfs


#echo "Making initrd..."
rm -f $mISO/isolinux/gentoo.igz
( 
	cd $ninitrd
	find . \
		| cpio --quiet --dereference -o -H newc \
		| xz -9 --check=crc32 \
		> ../$mISO/isolinux/gentoo.igz
)

#echo "Making ISO image..."
rm -f .wip.iso
(
	cd $mISO
	xorriso -as mkisofs \
		-D -R -J -joliet-long -l \
		-b isolinux/isolinux.bin \
		-c isolinux/boot.cat \
		-iso-level 3 -no-emul-boot -partition_offset 16 -boot-load-size 4 -boot-info-table \
		-isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
		-o ../.wip.iso .
)
mv .wip.iso $1
