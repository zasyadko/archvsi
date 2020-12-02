## About
This script was originally created for personal use. Performs a basic installation of Arch Linux on a computer using an EFI bootloader. Requires a whole disk for the system, which will be divided into boot and primary partitions.

## How to use

1. Get latest Arch Linux image from https://www.archlinux.org/download/
2. Boot with a bootable device, how to do it is described here https://wiki.archlinux.org/index.php/USB_flash_installation_medium
3. Download script from https://zasyadko.github.io/archvsi/archvsi.sh
```sh
wget https://zasyadko.github.io/archvsi/archvsi.sh
```
4. You can change the list of packages to install inside the script in the "Install packages" section
```sh
arch-chroot /mnt <<EOF
pacman -Sy --noconfirm {your package list here}
EOF
```
5. Start a script
```sh
sh archvsi.sh
```
6. Follow the instructions on the screen
7. After finishing the installation process, restart your computer
```sh
shutdown -r now
```
Profit!
