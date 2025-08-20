#!/bin/bash

clear
echo -e "Step #1. Identify the RAID device and partitions\n"
cat /proc/mdstat

echo -e "Verify the partitions and their corresponding mount points\n"
lsblk

echo -e "Step #2. Unmount the RAID partition(s) (if mounted)"
echo -n "Enter the RAID mount partition that need to remove: "; read RAID_MOUNT
sudo umount $RAID_MOUNT

echo -e "\n Step #3. Stop the RAID device \n"
echo -n "Enter the raid number [ex: md127]: "; read RAID_NUMBER
sudo mdadm --stop /dev/$RAID_NUMBER

echo -e "\n Step #4. Remove the RAID device from configuration \n"
sudo mdadm --remove /dev/$RAID_NUMBER

echo -e "Step #5. Zero out the superblocks \n"
echo -n "Enter the drive with RAID to remove [ex: sda1]: "; read RAID_DRIVE
sudo mdadm --zero-superblock /dev/$RAID_DRIVE

echo -e "\n Verify and Cleanup \n"
cat /proc/mdstat

# Check for error
if [[ $? -ne 0 ]]; then
  echo -e "\n RAID cleanup failed, encountered error/problem..."
else
  echo -e "\n All RAID drive(s) were cleanup successfully, thanks!!!"
fi