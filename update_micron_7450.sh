#!/bin/bash
# auth: acd
# build date: 07152026
# revision: 1

clear

# Prequisite tools needed
printf "\n%s\n\n" "Checklist of sw tools needed:"
printf "\t%s" "1. nvme-cli_2.16-1_amd64.deb or the latest"
printf "\n\t%s" "2. Micron_7450_E2MU300_release.ubi"
printf "\n\n"

read -r -p "Continue? (y/n): " reply
if [[ ! "$reply" == [yY] ]]; then
  echo "Exiting now ..."
  exit 0
fi

# Ensure nvme-cli command is installed
# Note: This lines are only for USB installation method 
##############################
# Check if there's network connection
printf "\n%s\n\n" "Checking for network connection ..."
NETWORK_STATUS=$(ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && echo "Online" || echo "Offline")
if [[ $NETWORK_STATUS == "Online" ]]; then
  sudo apt update
  sudo apt install nvme-cli
else
  sudo dpkg -i nvme-cli_2.16-1_amd64.deb
  sudo apt-get install -f
fi
##############################

# Ensure script is run as root
printf "\n%s\n\n" "Checking if user is root ..."
echo 
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo)."
  exit 1
fi

# Configuration
# Path to your downloaded Micron 7450 firmware binary (e.g., Micron_7450_E2MU300_release.ubi)
PWD=$(pwd)
F="Micron_7450_E2MU300_release.ubi"
FW_FILE="${PWD}/$F"

# Check if firmware file exists
printf "\n%s\n\n" "Checking if firmware $F file exist"
if [ ! -f "$FW_FILE" ]; then
  echo "[-] Firmware file not found at $FW_FILE. Please update the FW_FILE path in the script."
  exit 1
fi

# Find all Micron 7450 devices and get their NVMe paths
# Note: "Micron 7450" is the standard controller string.
printf "\n%s\n\n" "Find all Micron 7450 drives ..."
mapfile -t TARGET_DRIVES < <(nvme list | grep -i "Micron 7450" | awk '{print $1}')

if [ ${#TARGET_DRIVES[@]} -eq 0 ]; then
  echo "[-] No Micron 7450 SSDs found in the system."
  exit 0
fi

echo "[+] Found ${#TARGET_DRIVES[@]} Micron 7450 drive(s)."

for DRIVE in "${TARGET_DRIVES[@]}"; do
  echo "[+] Processing drive: $DRIVE"
  
  # 1. Download the firmware to the controller
  echo "    * Downloading firmware..."
  nvme fw-download "$DRIVE" -f "$FW_FILE"
		  
  # 2. Commit the firmware to Slot 2 (Action 3: Commit and apply)
  echo "    * Committing firmware..."
  nvme fw-commit "$DRIVE" -s 2 -a 3
	        
  echo "    [+] Drive $DRIVE update completed."
done

echo "[+] Firmware update process finished. A cold power cycle (shutdown and reboot) of the host is recommended to finalize the activation."

