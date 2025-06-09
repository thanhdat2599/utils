#!/bin/bash

echo "🧼 Unmounting and wiping existing partitions..."
sudo umount /mnt/ssd_boot 2>/dev/null
sudo umount /mnt/ssd_root 2>/dev/null
sudo wipefs -a /dev/nvme0n1

echo "📦 Creating new partition table..."
sudo parted /dev/nvme0n1 --script mklabel msdos
sudo parted /dev/nvme0n1 --script mkpart primary fat32 1MiB 10241MiB
sudo parted /dev/nvme0n1 --script mkpart primary ext4 10241MiB 100%

echo "🧹 Formatting partitions..."
sudo mkfs.vfat -F32 /dev/nvme0n1p1
sudo mkfs.ext4 /dev/nvme0n1p2

echo "📁 Mounting SSD partitions..."
sudo mkdir -p /mnt/ssd_boot /mnt/ssd_root
sudo mount /dev/nvme0n1p1 /mnt/ssd_boot
sudo mount /dev/nvme0n1p2 /mnt/ssd_root

echo "📝 Cloning system (rootfs)... This may take a few minutes..."
sudo rsync -aAXv / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /mnt/ssd_root

echo "📝 Cloning boot partition..."
sudo rsync -aHAX --no-links /boot/ /mnt/ssd_boot/

echo "✏️ Modifying cmdline.txt on SSD..."
sudo mkdir -p /mnt/ssd_boot/firmware
echo "console=serial0,115200 console=tty1 root=/dev/nvme0n1p2 rootfstype=ext4 fsck.repair=yes rootwait quiet splash" | sudo tee /mnt/ssd_boot/firmware/cmdline.txt > /dev/null

echo "📦 Unmounting SSD partitions..."
sync
sudo umount /mnt/ssd_boot
sudo umount /mnt/ssd_root

echo "✅ DONE! Now power off, remove the SD card, and boot from SSD!"
