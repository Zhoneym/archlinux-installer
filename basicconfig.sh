#!/bin/bash

root=$1
boot=$2

set -e

color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        yellow)
            echo -e "\033[33m$2\033[0m"
        ;;
    esac
}

config_base(){
    color yellow "The hostname will be set to Arch-Linux"
    echo 'Arch-Linux' > /etc/hostname
    color yellow "Change your root passwd"
    passwd
}

config_locale(){
    color yellow "Please choose your locale time"
    select TIME in `ls /usr/share/zoneinfo`;do
        if [ -d "/usr/share/zoneinfo/$TIME" ];then
            select time in `ls /usr/share/zoneinfo/$TIME`;do
                ln -sf /usr/share/zoneinfo/$TIME/$time /etc/localtime
                break
            done
        else
            ln -sf /usr/share/zoneinfo/$TIME /etc/localtime
            break
        fi
        break
    done
    hwclock --systohc --utc
    color yellow "Choose your language"
    select LANG in "en_US.UTF-8" "zh_CN.UTF-8";do
        echo "$LANG UTF-8" > /etc/locale.gen
        locale-gen
        echo LANG=$LANG > /etc/locale.conf
        break
    done
}

install_grub(){
    if (mount | grep efivarfs > /dev/null 2>&1);then
        pacman -S --noconfirm grub efibootmgr dosfstools -y
        rm -f /sys/firmware/efi/efivars/dump-*
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Linux
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        pacman -S --noconfirm grub
        fdisk -l
        color yellow "Input the disk you want to install grub (/dev/sdX"
        read TMP
        grub-install --target=i386-pc $TMP
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

add_user(){
    pacman -S --noconfirm sudo
    echo 'root ALL=(ALL:ALL) ALL' > /etc/sudoers
    echo '%sudo ALL=(ALL:ALL) ALL' >> /etc/sudoers
    echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
    echo '@includedir /etc/sudoers.d' >> /etc/sudoers

}

install_graphic(){
    color yellow "What is your video graphic card?"
    select GPU in "VirtualBox" "Hyper-V" "VMware";do
        case $GPU in
            "VirtualBox")
                pacman -S --noconfirm virtualbox-guest-utils -y
                systemctl enable vboxservice.service
                break
            ;;
            "Hyper-V")
                pacman -S --noconfirm hyperv xf86-video-fbdev -y
                break
            ;;
            "VMware")
                pacman -S --noconfirm open-vm-tools gtkmm3 -y
                pacman -S --noconfirm xf86-video-vmware -y
                pacman -S --noconfirm xf86-input-vmmouse -y
                systemctl enable vmtoolsd.service
                systemctl enable vmware-vmblock-fuse.service
                break
            ;;
            *)
                color red "Error ! Please input the correct num"
            ;;
        esac
    done
}


install_app(){
    sed -i '/archlinuxcn/d' /etc/pacman.conf
    echo -e "[archlinuxcn]\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
    pacman -Sy
    pacman -S --noconfirm archlinuxcn-keyring
    pacman -S --noconfirm networkmanager xorg-server wqy-zenhei wqy-microhei wqy-microhei-lite wqy-bitmapfont ruby lolcat yay zsh vim nano git wget openssh noto-fonts-emoji p7zip
    pacman -S --noconfirm ufw unrar cmake go llvm lldb podman cni-plugins cockpit cockpit-podman podman-docker
    systemctl enable ufw.service
    systemctl enable NetworkManager
    systemctl enable sshd
}


clean(){
    sed -i 's/\%wheel ALL=(ALL) NOPASSWD: ALL/\# \%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
}

main(){
    config_base
    install_grub
    add_user
    install_graphic
    install_app
    pacman -S --noconfirm cups ghostscript gsfonts gutenprint noto-fonts-cjk  xorg-mkfontscale -y
    pacman -S --noconfirm python-pip hugo -y
    pacman -S --noconfirm zstd lib32-zstd -y
    wget https://codeberg.org/Zhoneym/archlinux-installer/raw/branch/main/genfstab && mv genfstab /usr/bin/genfstab
    chmod a+x /usr/bin/genfstab
    config_locale
    color yellow "Done , Thanks for your using"
}

main
