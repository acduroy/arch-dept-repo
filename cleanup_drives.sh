#!/bin/bash

clear

# Display Usage()
display_usage() {
  echo "Please suppply the name of drive(s) to cleanup."
  echo -e "Sample drive's name to use: -> sda nvme1n1\n"
  echo -e "\nUsage: $0 [arguments] \n"
}

# if no argumentd supplied, display usage
if [  $# -eq 0 ]; then
  display_usage
  exit 1
fi


# List all drive(s) to clean
drive_count=$#; list_of_drives=("$@")
echo -e "Cleaning ${drive_count} drives .... ${list_of_drives[@]}\n"

# Define boot drive
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
BOOT_DISK=$(lsblk -no PKNAME "${ROOT_DEVICE}" | head -n 1)

for disk in "${list_of_drives[@]}"; do
  echo -e "cleaning up  ${disk} ...\n"

  TARGET_DRIVE="/dev/${disk}"

  # Get Drive capacity and offset bytes
  DRIVE_SIZE=$(blockdev --getsize64 /dev/sdb)
  OFFSET_BYTES=$((DRIVE_SIZE - 100 * 1024 * 1024))

  if [[ "${BOOT_DISK}" == "${TARGET_DRIVE##*/}" ]]; then
    echo -e "${TARGET_DRIVE} is the boot drive, will not clean this drive.\n"
  else
    echo -e "${TARGET_DRIVE} is NOT the boot drive, will proceed cleaning the drive.\n"
    sudo dd if=/dev/zero of=/dev/$disk bs=1M count=100 status=progress oflag=sync
    sudo dd if=/dev/zero of=/dev/$disk bs=1M count=100 seek=$((OFFSET_BYTES / 1024 / 1024)) status=progress oflag=sync
  fi
done

# Check for error
if [[ $? -ne 0 ]]; then
  echo -e "\nDrive cleanup failed, encountered error/problem..."
else
  echo -e "\nAll drive(s) were cleanup successfully, thanks!!!"
fi