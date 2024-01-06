# XU10-firmware
Firmware and tools related to XU10 gaming handheld

# Introduction
Here I am collecting some tools related to the XU10 gaming handheld.
This should not include any copyrighted data including ROM and BIOS files. Initial target was to extzract uboot and firmware loader from the included system SD-card in order to allow re-building an SD card in case your card is broken.
This repository might be helpful as well if you want to replace your SD card on your XU10 device with a larger one.

I am not fully sure if any of those binaries are violating any copyright but the binaries seem to be based on rg351v images also available in projects like AmberELEC. Also I am not providing any reverse engineered sources our modifications. Just dumping what exists on the SD-card shipped to you anyway.
If you claim any copyright on any of those files please contact me.

# Partition layout
The XU10 handheld is based on Rockchip RK3326 chipset. The default partition layout does look as follows :
```
Device     Boot   Start       End   Sectors   Size Id Type
/dev/sdf1  *      32768   4227071   4194304     2G  c W95 FAT32 (LBA)
/dev/sdf2       4227072   8388608   4161537     2G 83 Linux
/dev/sdf3       8421376 488554495 480133120 228.9G  7 HPFS/NTFS/exFAT
```
Partition 1: MAGICX (FAT32), boot, lba
Partition 2: STORAGE (ext4)
Partition 3: GAMES (exFAT)

As visible there is a 16MB block preceeding the first partition. As of [Rockchip documentation]((https://opensource.rock-chips.com/wiki_Boot_option#Boot_from_SD.2FTF_Card)https://opensource.rock-chips.com/wiki_Boot_option#Boot_from_SD.2FTF_Card) thesee 16MB contain the IDB loader, uboot and trust images. These images however differ from the ones used for RG351v devices. So I decided to dump them myself.

# Dumping Rockchip images
I found the idbloader to be 319 sectors in size on my device. The uboot and trust images are 4MB by speficiation even if the trust image was about 2MB on my device only I decided to do a full 4MB dump. So I could dump it using:
```
INPUT_DEVICE="/dev/mmcblk0"
dd if="${INPUT_DEVICE}" of="XU10-idbloader.img" seek=64 count=319
dd if="${INPUT_DEVICE}" of="XU10-uboot.img" seek=16384 count=8192
dd if="${INPUT_DEVICE}" of="XU10-trust.img" seek=24576 count=8192
```

I am including XU10-dump.sh to automate the process. Make sure to update the INPUT_DEVICE variable with the path to your SD-card (e.g. use /dev/sdX in case of an external USB cardreader).


# Backup your SD-card
You can simply create a copy of the contents of partition 1 (MAGICX) as well as partition 3 (GAMES) using Windows file explorer.
For partition 2 you need a Linux system or ext filesystem driver for Windows or any clone utility which can dump ext file systems. I used clonezilla to create a partition dump.

# Restore your SD-card
To restore your system you need an SD carrd with a minimumn size of 8GB. But to restore ROMs and make it any usable you anyway likely will prefer anything > 32GB. Or use a second SD card for games.
I do recommend to execute those steps in order.

## Restore bootloader
Simply use dd to write ibdloader, uboot and trust to the first 16MB of your new SD card.
```
OUTPUT_DEVICE="/dev/mmcblk0"
dd if="XU10-idbloader.img" of="${OUTPUT_DEVICE}" seek=64
dd if="XU10-uboot.img" of="${OUTPUT_DEVICE}" seek=16384
dd if="XU10-trust.img" of="${OUTPUT_DEVICE}" seek=24576
```
I am including XU10-mkboot.sh to automate the process.


## Create partitions
Create all 3 partitions using the scheme above. Make sure to leave 16MB of space and therefore do not overwrite ibdloader, uboot or trust blocks written to blocks up to 32768 in previous steps.
```
fdisk /dev/<device>
```
Create 3 primary partitions, set proper file system and set boot and lba flag for partition 1.
Partition 3 can simply use the remaining space on the SD-card.

## Restore partition contents
Copy contents of partition 1 (FAT32, MAGICX) and partition 3 (exFAT, GAMES) back on the SD card.
If you do not have a backup of those files you might have to get it from someone with a working SD card.

## Update partition UUID
The first partition (partition 1, FAT32, label MAGICX) needs to be know by the boot process (linux kernel) in order to load the system. You either can clone the OEM partition ID or you need to update the configuration.

### Cloning partition ID
THe OEM UUID for partition 1 (FAT32, label MAGICX) on my device was **2710-4045**. So if you want the system to be able to boot without modifications you need to set this ID. You can use _fatlabel_ tool to do this:
```
fatlabel -i /dev/devX1 27104045
```
For partition 2 (ext4, label STORAGE) the default UUID was **1f4a0cec-b70e-4225-8474-877cc0e54c97**. If you used clonezilla to create a dump you don't need to do anything as clonezilla restored partition will retain its UUID. If you just created a tarball of the partition contents or similar backup method then you need to update the UUID using _tune2fs_:
```
tune2fs -U 1f4a0cec-b70e-4225-8474-877cc0e54c97 /dev/devX2
```
Partition 3 (exFAT, label GAMES) as of my knowledge does not need s speicific UUID.

### Update configuration
Instead of "faking" the OEM filesystem UUIDs you can also update the configuration.
Open _extlinux/rk3326-rg351v-linux.dtb.conf_ using your favourite text editor and update the filesystem UUIDs. You can find the current UUIDs using _blkid_ command.
Update the UUIDs in the configuration file:
```
LABEL MAGICX
LABEL MAGICX
  LINUX /KERNEL
  FDT /rk3326-rg351v-linux.dtb
  APPEND oot=UUID=<inseert-partition-1-UUID> disk=UUID=<insert-partition-2-UUID> quiet console=ttyFIQ0 console=tty0 net.iframes=0 fbcon=rotate:0 ssh consoleblank=0 systemd.show_status=0 loglevel=0 panic=20
```

## Boot
Place your SD card in your XU10 device and power it on.

# Troubleshooting

## No boot splash
If your device does not show the MAGICX boot logo (actually logo.bmp on the MAGICX partition) on startup make sure to power off (long-press power button) or restet (small button right next to power button on the back) your device. If still no boot screen is shown make sure you properly flashed ibdloader, uboot and trust blocks.

## Failed to mount boot partition
If your device is showing the splash screen and then going black screen just to show a boot mount error after a minute then you might have failed to properly configure your FAT32 partition 1 (MAGICX). Make sure to either set it's UUID to **2710-4045** or update _rk3326-rg351v-linux.dtb.conf_ to include the correct UUID.
Also it happened to me once that an SD-card was broken. Check output of _dmesg_ to see any errors about defective blocks. Even if the card looks OK it might be broken. So try another SD-card.
