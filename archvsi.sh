#!/bin/bash

# -----------------------------------------------------------------------------
# Init params

DRIVE="/dev/sda"
echo "Drive for install? (default /dev/sda)"
read IN
if [ ! "$IN" = "" ]; then
    if [ ! -e "$IN" ]; then
        echo "device '$IN' does not exist"
        exit
    fi
    DRIVE=$IN
fi
BOOTDEV="$DRIVE"1
SYSDEV="$DRIVE"2

NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
MYHOSTNAME=$NEW_UUID
echo "Enter host name: (default '$MYHOSTNAME')"
read IN
if [ ! "$IN" = "" ]; then
   MYHOSTNAME=$IN
fi

MYUSERNAME="user"
echo "Enter user name: (default '$MYUSERNAME')"
read IN
if [ ! "$IN" = "" ]; then
   MYUSERNAME=$IN
fi

MYUSERPASSWORD="1234567890"
echo "Enter user password: (default '$MYUSERPASSWORD')"
read IN
if [ ! "$IN" = "" ]; then
   MYUSERPASSWORD=$IN
fi

# -----------------------------------------------------------------------------
# Update the system clock

timedatectl set-ntp true

# -----------------------------------------------------------------------------
# Create partitions

(echo g; echo n; echo 1; echo ""; echo "+512M"; echo t; echo 1; echo w) | fdisk $DRIVE --wipe always
mkfs.fat -F32 $BOOTDEV

(echo n; echo 2; echo ""; echo ""; echo w) | fdisk $DRIVE --wipe always
mkfs.ext4 $SYSDEV

# -----------------------------------------------------------------------------
# Mount

mount $SYSDEV /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount $BOOTDEV /mnt/boot/efi

# -----------------------------------------------------------------------------
# Get actual mirrorlist

pacman -Sy --noconfirm reflector
reflector --verbose -l 200 -p https --sort rate --save /etc/pacman.d/mirrorlist

# -----------------------------------------------------------------------------
# Install essential packages

pacstrap /mnt base linux linux-firmware

# -----------------------------------------------------------------------------
# Fstab

genfstab -U /mnt >> /mnt/etc/fstab

# -----------------------------------------------------------------------------
# Base config

arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$MYHOSTNAME" > /etc/hostname
echo "" >> /etc/pacman.conf
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
mkinitcpio -P
EOF

# -----------------------------------------------------------------------------
# Install packages

arch-chroot /mnt <<EOF
pacman -Sy --noconfirm base-devel bash-completion xf86-video-amd xf86-video-vesa mesa lib32-mesa htop chromium efibootmgr gimp git gnome gnome-extra gnome-tweaks go graphviz grub libreoffice-fresh lshw mariadb nano nmon nodejs npm ntfs-3g openssh os-prober php remmina sudo transmission-gtk unrar vlc
EOF

# -----------------------------------------------------------------------------
# Create user
arch-chroot /mnt <<EOF
useradd -m $MYUSERNAME
echo "$MYUSERNAME:$MYUSERPASSWORD" | chpasswd
echo "$MYUSERNAME  ALL=(ALL) ALL" >> /etc/sudoers
EOF

# -----------------------------------------------------------------------------
# Enable services

arch-chroot /mnt <<EOF
systemctl enable gdm
systemctl enable NetworkManager.service
systemctl enable bluetooth
systemctl enable sshd
EOF

# -----------------------------------------------------------------------------
# Install grub

arch-chroot /mnt <<EOF
grub-install --recheck $DRIVE
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# -----------------------------------------------------------------------------
# End

echo "ALL DONE!!! Ready to reboot..."
