Guide how to downgrade Pico 4 in Linux using [edl](https://github.com/bkerler/edl)

---

# ⚠️ Warning ⚠️

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

GUIDE WRITING WIP TAKE YOUR TIME PLEASE
