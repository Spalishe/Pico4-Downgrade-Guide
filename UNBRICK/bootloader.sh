#!/bin/bash

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
	echo "ERROR: Run this script with sudo."
	exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$BASE_DIR/backup/lun0"
FIREHOSE_FILE="$BASE_DIR/data/prog_firehose_ddr.elf"

for cmd in edl lsusb; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "ERROR: '$cmd' is missing."
		exit 1
	fi
done

if [[ ! -d "$BACKUP_DIR" ]]; then
	echo "ERROR: Backup folder not found:"
	echo "  $BACKUP_DIR"
	exit 1
fi

if [[ ! -f "$FIREHOSE_FILE" ]]; then
	echo "ERROR: Firehose loader not found:"
	echo "  $FIREHOSE_FILE"
	exit 1
fi

for file in misc.bin picocfg.bin metadata.bin persist.bin; do
	if [[ ! -f "$BACKUP_DIR/$file" ]]; then
		echo "ERROR: Missing file:"
		echo "  $BACKUP_DIR/$file"
		exit 1
	fi
done

echo "======================================================"
echo "         Pico 4 Boot Config Restore Tool"
echo "======================================================"
echo

if ! lsusb | grep -qi "05c6:9008"; then
	echo "ERROR: No Qualcomm 9008 device found."
	echo "Boot the headset into EDL mode and try again."
	exit 1
fi

echo "Device detected."
echo
echo "This will restore:"
echo "  misc"
echo "  picocfg"
echo "  metadata"
echo "  persist"
echo

read -rp "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
	echo "Cancelled."
	exit 0
fi

cd "$BACKUP_DIR"

write_partition() {
	local part="$1"
	local file="$2"

	if ! lsusb | grep -qi "05c6:9008"; then
		echo "ERROR: Device disconnected."
		exit 1
	fi

	echo "Writing $part..."

	edl w "$part" "$file" \
		--lun=0 \
		--loader="$FIREHOSE_FILE" \
		--memory=ufs

	echo "$part done."
	echo
}

write_partition misc misc.bin
write_partition picocfg picocfg.bin
write_partition metadata metadata.bin
write_partition persist persist.bin

echo "Restore complete."
echo
echo "Reconnect the headset and try a normal boot."
