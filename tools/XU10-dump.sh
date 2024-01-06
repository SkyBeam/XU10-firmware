#!/bin/bash

# Offsets see https://opensource.rock-chips.com/wiki_Boot_option#Boot_from_SD.2FTF_Card

INPUT_DEVICE="/dev/mmcblk0"

echo "Do you want to dump from '${INPUT_DEVICE}'?"
echo "Press 'y' to continue, any other key will abort."
read ANSWER

if [[ "${ANSWER}" != 'y' ]]; then
	echo "Aborting."
	exit 1
fi

# idbloader.img: block 64-383, Byte 0x7E00 (32256) to 0x2FC53 (195667) = 163412 Bytes
# uboot.img: block 16384-, Byte 0x80000 (8388608) to 0xC16F80 (12676992) = 4288000 Bytes
# -> 4MB uboot.img: block 16384, Byte 0x80000 (8388608) to 0xc00000 (12582912) = 4194304 Bytes (4MB)
# trust.img: block 32768, Byte 0xc00000 (12582912) to 0xE16F83 (14774147) = 2191235 Bytes
# -> 4MB trust.img: block 32768, Byte 0xc00000 (12582912) to 0x1000000 (16777216) = 4194304 Bytes (4MB)

echo "Dumping IDB loader."
dd if="${INPUT_DEVICE}" of="XU10-idbloader.img" skip=64 count=319

echo "Dumping U-Boot."
dd if="${INPUT_DEVICE}" of="XU10-uboot.img" skip=16384 count=8192

echo "Dumping Trust."
dd if="${INPUT_DEVICE}" of="XU10-trust.img" skip=24576 count=8192
