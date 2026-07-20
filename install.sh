#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
	echo "ERROR: running not as root."
	exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$BASE_DIR/data"
FLASH_ZIP="$DATA_DIR/FW_Downgrade.zip"
FLASH_DIR="$DATA_DIR/flash"
FIREHOSE_FILE="$DATA_DIR/prog_firehose_ddr.elf"
PASSWORD="socibzsv83nc7"

# Добавлен lsusb в список зависимостей
for cmd in adb unzip edl lsusb; do
	if ! command -v $cmd &>/dev/null; then
		echo "ERROR: Tool '$cmd' not installed."
		exit 1
	fi
done

echo "================================================================="
echo "                    Pico 4 Downgrader OS 5.4.0                   "
echo "================================================================="
echo ""

RUN_FROM_EDL=0

if lsusb | grep -qi "05c6:9008"; then
	# Device in EDL
	echo "Qualcomm 9008 (EDL) device detected immediately on USB bus!"
	echo ""
	echo "In EDL, we cant read the OEM status from Android."
	echo "Please select your helmet firmware type manually:"
	echo "1) Retail / Normal (nonOEM)"
	echo "2) OEM version (OEM)"
	echo ""
	read -p "Enter choice (1 or 2): " USER_EDL_CHOICE

	if [ "$USER_EDL_CHOICE" = "1" ]; then
		SOURCE_FOLDER="nonOEM/Flash"
		echo "Selected: nonOEM"
	elif [ "$USER_EDL_CHOICE" = "2" ]; then
		SOURCE_FOLDER="OEM/Flash"
		echo "Selected: OEM"
	else
		echo "ERROR: Invalid choice. Exiting."
		exit 1
	fi
	RUN_FROM_EDL=1
fi

if [ $RUN_FROM_EDL -eq 0 ]; then
	echo "Searching for Pico 4 via ADB..."
	ADB_DEVICE=$(adb devices | grep -w "device" | awk '{print $1}' | head -n 1)

	if [ -z "$ADB_DEVICE" ]; then
		echo "ERROR: Pico 4 not found."
		echo "Be sure that 'USB Debugging' enabled in system options."
		echo "Helmet must be in normal mode or already manually forced to EDL."
		exit 1
	fi

	INTERNAL_VERSION=$(adb -s "$ADB_DEVICE" shell getprop ro.pvr.internal.version | tr -d '\r\n')
	if [[ ! "${INTERNAL_VERSION,,}" == *"phoenix"* ]]; then
		echo "ERROR: Unsupported device: $INTERNAL_VERSION"
		exit 1
	fi
	echo "Found Pico 4 ($INTERNAL_VERSION)"

	OEM_STATE=$(adb -s "$ADB_DEVICE" shell getprop ro.oem.state | tr -d '\r\n')
	OEM_STATE="${OEM_STATE,,}"

	if [ "$OEM_STATE" = "true" ]; then
		SOURCE_FOLDER="OEM/Flash"
		echo "OEM STATE: true"
	else
		SOURCE_FOLDER="nonOEM/Flash"
		echo "OEM STATE: false"
	fi
fi

echo ""
echo "Unpacking 5.4.0 Flash..."
rm -rf "$FLASH_DIR"
mkdir -p "$FLASH_DIR"

unzip -P "$PASSWORD" -o "$FLASH_ZIP" "$SOURCE_FOLDER/*" -d "$FLASH_DIR"

mv "$FLASH_DIR/$SOURCE_FOLDER"/* "$FLASH_DIR/"
rm -rf "$FLASH_DIR/OEM" "$FLASH_DIR/nonOEM"

echo "Flash copied to $FLASH_DIR"

echo ""
echo "⚠️ WARNING ⚠️: NEXT STEP WILL CHANGE YOUR OS STATE ENTIRELY"
echo "IT IS STRONGLY RECOMMENDED TO CREATE A FULL BACKUP BEFORE CONTINUING."
echo "PROCEED AT YOUR OWN RISK."
read -p "Type 'YES' to continue: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
	echo "Declined by user"
	exit 0
fi

if [ $RUN_FROM_EDL -eq 0 ]; then
	echo ""
	echo "Rebooting Pico 4 to EDL..."
	adb -s "$ADB_DEVICE" reboot edl

	echo "Awaiting for reboot (30 seconds for timeout)..."
	TIMEOUT=60
	COUNT=0
	FOUND=0

	while [ $COUNT -lt $TIMEOUT ]; do
		if lsusb | grep -qi "05c6:9008"; then
			FOUND=1
			break
		fi
		sleep 0.5
		COUNT=$((COUNT + 1))
	done

	if [ $FOUND -eq 0 ]; then
		echo "ERROR: Device Qualcomm 9008 not appeared after reboot."
		echo "Make sure cable is fixed and try to restart script."
		exit 1
	fi
fi

echo ""
echo "Starting patching process."
echo "DO NOT DISCONNECT CABLE WHILE PATCHING!"
echo "-----------------------------------------------------------------"

cd "$FLASH_DIR"

FLASH_FILES=$(ls lun*_*.bin 2>/dev/null || true)

if [ -z "$FLASH_FILES" ]; then
	echo "ERROR: no files in flash folder (lunX_*.bin)"
	exit 1
fi

for file in $FLASH_FILES; do
	LUN_NUM=$(echo "$file" | cut -d'_' -f1 | sed 's/lun//')
	PART_NAME=$(echo "$file" | cut -d'_' -f2- | sed 's/\.bin//')

	echo "Write partition [$PART_NAME] to LUN $LUN_NUM..."
	echo "File: $file"

	edl w "$PART_NAME" "$FLASH_DIR/$file" --lun="$LUN_NUM" --loader="$FIREHOSE_FILE" --memory=ufs

	echo "Partition [$PART_NAME] write SUCCESS."
	echo "-----------------------------------------------------------------"
done

echo ""
echo "Exit from EDL..."
edl reset

echo ""
echo "YOUR OS VERSION IS DOWNGRADED."
echo "!!! THE DEVICE WILL NOT BOOT. YOU MUST PERFORM A FACTORY RESET BEFORE IT CAN BOOT. !!!"
echo ""
echo "HOLD THE POWER BUTTON FOR 10 SECONDS UNTIL YOUR DEVICE REBOOTS."
echo "IT SHOULD REBOOT INTO RECOVERY, WHERE YOU CAN CHOOSE BETWEEN 'TRY AGAIN' AND 'FACTORY DATA RESET'"
echo ""
echo "IF IT DOESN'T BOOT INTO RECOVERY AUTOMATICALLY, FOLLOW THESE STEPS TO FORCE RECOVERY MODE:"
echo "USING ADB: RUN 'adb reboot recovery'. WHEN YOU SEE THE ANDROID ROBOT, PRESS POWER + VOLUME UP."
echo "MANUALLY: (When adb isn't available)"
echo "1. SHUT DOWN THE DEVICE."
echo "2. PRESS THE POWER BUTTON WHILE HOLDING THE VOLUME UP BUTTON."
echo "3. AFTER THE ANDROID ROBOT APPEARS, PRESS AND HOLD THE POWER BUTTON, THEN PRESS THE VOLUME UP BUTTON AGAIN."
