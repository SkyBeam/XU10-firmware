#!/bin/bash

# Offsets see https://opensource.rock-chips.com/wiki_Boot_option#Boot_from_SD.2FTF_Card

OUTPUT_DEVICE="/dev/mmcblk0"

echo "Do you want to write to '${OUTPUT_DEVICE}'?"
echo "WARNING: This might destroy all your data if any partion is residing in first 16MB of the device!"
echo "Press 'y' to continue, any other key will abort."
read ANSWER

if [[ "${ANSWER}" != 'y' ]]; then
	echo "Aborting."
	exit 1
fi

echo "Writing IDB loader."
dd if="XU10-idbloader.img" of="${OUTPUT_DEVICE}" seek=64

echo "Writing U-Boot."
dd if="XU10-uboot.img" of="${OUTPUT_DEVICE}" seek=16384

echo "Writing Trust."
dd if="XU10-trust.img" of="${OUTPUT_DEVICE}" seek=24576
