#!/bin/bash

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
	echo "ERROR: Run this script with sudo."
	exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$BASE_DIR/backup"
FIREHOSE_FILE="$BASE_DIR/data/prog_firehose_ddr.elf"

for cmd in edl lsusb find sed; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "ERROR: '$cmd' is missing."
		exit 1
	fi
done

if [[ ! -d "$BACKUP_DIR" ]]; then
	echo "ERROR: Backup folder not found:"
	echo "  $BACKUP_DIR"
	echo "You must be in repo root folder."
	exit 1
fi

if [[ ! -f "$FIREHOSE_FILE" ]]; then
	echo "ERROR: Firehose loader not found:"
	echo "  $FIREHOSE_FILE"
	echo "You must be in repo root folder."
	exit 1
fi

echo "======================================================"
echo "            Pico 4 GPT Restore Tool"
echo "======================================================"
echo

echo "Checking for Qualcomm 9008 device..."

if ! lsusb | grep -qi "05c6:9008"; then
	echo "ERROR: No Qualcomm 9008 device found."
	echo "Boot the headset into EDL mode and try again."
	exit 1
fi

echo "Device detected."
echo

echo "Looking for GPT backup files..."

mapfile -t GPT_FILES < <(
	find "$BACKUP_DIR" -type f -name "gpt_main*.bin" | sort
)

if [[ ${#GPT_FILES[@]} -eq 0 ]]; then
	echo "ERROR: No gpt_main*.bin files found."
	exit 1
fi

echo "Found:"
for file in "${GPT_FILES[@]}"; do
	echo "  $(basename "$file")"
done

echo
read -rp "Restore GPT tables now? Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
	echo "Cancelled."
	exit 0
fi

echo
echo "Starting restore..."
echo

for file_path in "${GPT_FILES[@]}"; do
	filename="$(basename "$file_path")"

	LUN_NUM="$(sed -n 's/.*main\([0-9]\+\).*/\1/p' <<<"$filename")"

	if [[ -z "$LUN_NUM" ]]; then
		echo "ERROR: Can't determine LUN from file:"
		echo "  $filename"
		exit 1
	fi

	if ! lsusb | grep -qi "05c6:9008"; then
		echo "ERROR: Device disconnected."
		exit 1
	fi

	echo "Writing GPT to LUN $LUN_NUM"
	echo "File: $filename"

	edl w gpt "$file_path" \
		--lun="$LUN_NUM" \
		--loader="$FIREHOSE_FILE" \
		--memory=ufs

	echo "LUN $LUN_NUM done."
	echo
done

echo "All GPT tables restored."
echo
echo "Reconnect the headset to start a new EDL session."
echo "After that you can continue with the firmware restore."
