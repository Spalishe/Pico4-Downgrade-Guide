Guide how to downgrade Pico 4 in Linux using [edl](https://github.com/bkerler/edl)

---

# ⚠️ WARNING ⚠️

WARNING – USE AT YOUR OWN RISK

This tool directly flashing the firmware to your Pico 4 device by utilizing Qualcomm EDL mode (QFIL), a signed Firehose programmer, and related flashing utilities.

Flashing firmware always carries a risk of:

- Temporarly bricking your device (You can normally unbrick it with the utilities)
- Data loss (You have to perform a factory reset after the Downgrade)
- Boot failures
- Warranty voidance

Ensure that you fully understand the flashing process before proceeding. Do not disconnect the USB cable or power off the device during any operation. Flashing OS 5.4.0 can take up to 10 minutes (depends on your USB Speed, normally ~3 minutes)

---

# GUIDE

## Prerequisite

### ADB:
```
# Debian/Ubuntu/Mint/etc
sudo apt install adb
# Arch/Manjaro/etc
sudo pacman -S android-tools
```

### EDL:
```
# Debian/Ubuntu/Mint/etc
sudo apt install adb fastboot python3-dev python3-pip liblzma-dev git
sudo apt purge modemmanager
# Fedora/CentOS/etc
sudo dnf install adb fastboot python3-devel python3-pip xz-devel git
# Arch/Manjaro/etc
sudo pacman -S android-tools python python-pip git xz
sudo pacman -R modemmanager
# Gentoo (run as root!)
emerge -aq dev-util/android-tools dev-vcs/git dev-python/pip

# For systemd distros
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
# For OpenRC distros (run as root!)
rc-update del modemmanager default boot sysinit
rc-service modemmanager stop

git clone https://github.com/bkerler/edl.git # do NOT use --recurse-submodules
cd edl
git submodule update --init --recursive

# Autoinstall (run as root!)
./autoinstall.sh

# Manual install
chmod +x ./install-linux-edl-drivers.sh
bash ./install-linux-edl-drivers.sh
pip3 install .
```

NOTE: If you using Arch linux, you can skip this, installing [edl-git](https://aur.archlinux.org/packages/edl-git) with your favourite AUR helper tool:
```
yay -S edl-git
```

### FIRMWARE
Since firmware didn't fit into Git LFS, i had to push it to MEGA
Link: <https://mega.nz/file/O4YUVIzT#1nMOwnv_2IWvwDgikRoqwsP8ktIStX33AUYQmGTceyU>  
If link got exploded, you can contact me in discord (@spalishe)

You also can download original downgrader from [here](https://drive.google.com/file/d/1Ii5kvOR7aooE-sv-v3GCeCSk7OvGNSJ4/view?usp=sharing) and [here](http://corntube.net/index.php/s/fWTHAQ6Y4RWSz86)    (or [here](http://corntube.net/index.php/s/CdtS2jLDMYPcwj4) for CHINA version)  
Firmware will be located in /helper/FW_Downgrade.zip

**You need to move this archive to ./data/FW_Downgrade.zip**

## Repo
Clone this repository.
```
git clone https://github.com/Spalishe/Pico4-Downgrade-Guide
cd Pico4-Downgrade-Guide
```

## Reboot

Firstly reboot your helmet to EDL mode:
```
adb reboot edl
```
You can easily exit EDL just by holding power button for around 10 seconds.

## Backup

You probably want to make your helmet backup so you can easily restore it if you do something horribly wrong.
```
edl rl ./path/to/backup/ --skip=userdata,cache --loader=prog_firehose_ddr.elf --memory=ufs
```
Output folder will have a size around 13G, so prepare your space.

You can later restore this backup by casting
```
edl wl ./path/to/backup/ --loader=prog_firehose_ddr.elf --memory=ufs
```

## Install

Run sh:
```
./install.sh
```

Script will give you instructions, be kind to follow those.

## UNBRICKING

There is a chance that you somehow broke something.  
**Those scripts will only work if you have backup.**

### GPT
You can test your GPT table by casting
```
edl printgpt --memory=ufs --loader=data/prog_firehose_ddr.elf
```
If you getting empty table, it means your GPT table got corrupted or smth else happened to it.
```
./UNBRICK/gpt_restore.sh
```
Script waits to all backup data to be placed in ./backup/  
Script must be run in this same directory.

### BOOT ISSUE
If you successfully patched all the things, but your bootloader just sits and does nothing and after little while shuts down this is it.
```
./UNBRICK/bootloader.sh
```
Script waits to all backup data to be placed in ./backup/  
Script must be run in this same directory.

# LICENSE

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](https://github.com/Spalishe/Pico4-Downgrade-Guide/blob/main/LICENSE) file for details.
