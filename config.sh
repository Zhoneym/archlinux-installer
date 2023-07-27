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
        pacman -S --noconfirm grub efibootmgr dosfstools sbctl -y
        rm -f /sys/firmware/efi/efivars/dump-*
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Linux --modules= "tpm" --disable-shim-lock
        grub-mkconfig -o /boot/grub/grub.cfg
}


add_user(){
    color yellow "The username will be set to arch"
    useradd -m -g wheel arch
    color yellow "Set the passwd"
    passwd arch
    pacman -S --noconfirm sudo
    echo 'root ALL=(ALL:ALL) ALL' > /etc/sudoers
    echo '%sudo ALL=(ALL:ALL) ALL' >> /etc/sudoers
    echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
    echo '@includedir /etc/sudoers.d' >> /etc/sudoers

}

install_graphic(){
    color yellow "What is your video graphic card?"
    select GPU in "Intel" "Nvidia" "Nvidia-bumblebee" "AMD" "VirtualBox" "Hyper-V" "VMware";do
        case $GPU in
            "Intel")
                pacman -S --noconfirm xf86-video-intel intel-ucode mesa-libgl libva-intel-driver libvdpau-va-gl -y
                break
            ;;
            "Nvidia")
                bash -c "echo -e 'blacklist nouveau\noptions nouveau modeset=0' > /etc/modprobe.d/blacklist-nouveau.conf"
                pacman -S --noconfirm nvidia-dkms nvidia-utils -y
                break
            ;;
            "Nvidia-bumblebee")
                bash -c "echo -e 'blacklist nouveau\noptions nouveau modeset=0' > /etc/modprobe.d/blacklist-nouveau.conf"
                pacman -S --noconfirm bumblebee -y
                systemctl enable bumblebeed
                pacman -S --noconfirm nvidia-dkms -y
                break
            ;;
            "AMD")
                pacman -S --noconfirm xf86-video-ati amd-ucode mesa -y
                break
            ;;
            "VirtualBox")
                pacman -S --noconfirm virtualbox-guest-utils -y
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
    echo -e "[archlinuxcn]\nServer = https://opentuna.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
    pacman -Sy
    pacman -S --noconfirm archlinuxcn-keyring wget clang llvm lld cmake
    pacman -S --noconfirm networkmanager xorg-server pamac xournalpp notepadqq nodejs discord netease-cloud-music wqy-zenhei wqy-microhei wqy-microhei-lite wqy-bitmapfont neofetch ruby lolcat yay zsh vim nano git papirus-icon-theme openssh noto-fonts-emoji p7zip qt4
    pacman -S --noconfirm ibus ibus-rime rime-luna-pinyin
    pacman -S --noconfirm libreoffice-fresh libreoffice-fresh-zh-cn exfat-utils librecad gimp blender evince
    pacman -S --noconfirm telegram-desktop wireshark-qt gnome-todo ufw obs-studio inkscape unrar gnome-keyring libsecret libgnome-keyring qbittorrent go llvm lldb skypeforlinux-preview-bin anki aria2
    systemctl enable ufw.service
    color yellow "Install ClamAV and ClamTK"
    pacman -S --noconfirm clamav clamtk
    systemctl enable clamav-daemon.service
    systemctl enable clamav-daemon.socket
    systemctl enable clamav-clamonacc.service
    systemctl enable clamav-freshclam.service
    color yellow "Install KVM and QEMU y)YES ENTER)NO"
    read TMP
    if [ "$TMP" == "y" ];then
        pacman -S --noconfirm libvirt libvirt-glib libvirt-dbus edk2-armvirt edk2-ovmf edk2-shell ebtables dmidecode qemu qemu-arch-extra qemu-block-iscsi qemu-block-gluster bridge-utils gperftools virt-manager
        systemctl enable libvirtd.service
        systemctl enable virtlogd
        usermod -a -G kvm arch
    fi
    systemctl enable NetworkManager
    systemctl enable sshd
    color yellow "Install jetbrains IDE and Android-studio y)YES ENTER)NO" 
    read TMP
    if [ "$TMP" == "y" ];then
        pacman -S --noconfirm clion clion-jre clion-lldb clion-cmake clion-gdb android-studio goland goland-jre
    fi
    
    if [ "$GPU" == "Nvidia-bumblebee" ];then
        gpasswd -a arch bumblebee
    fi
}

install_desktop(){
    color yellow "Choose the desktop you want to use"
    select DESKTOP in "KDE" "GNOME" "Xfce" "None";do
        case $DESKTOP in
            "KDE")
                pacman -S plasma-meta kde-accessibility-meta kde-graphics-meta kde-multimedia-meta kde-network-meta kde-pim-meta kde-sdk-meta kde-system-meta kde-utilities-meta sddm
                systemctl enable sddm
                color yellow "Install Nvidia-OptimusManager (Nvidia-Prime)? y)YES ENTER)NO"
                read TMP
                if [ "$TMP" == "y" ];then
                    pacman -S --noconfirm bbswitch-dkms acpi_call-dkms create_ap xf86-video-intel intel-media-driver opencl-nvidia vulkan-intel lib32-opencl-nvidia lib32-vulkan-intel vulkan-icd-loader optimus-manager nvidia-prime nvidia-settings vdpauinfo libva-vdpau-driver libva-utils libvdpau lib32-libvdpau lib32-nvidia-cg-toolkit nvidia-cg-toolkit -y
                    systemctl enable optimus-manager.service
                    rm -f /etc/X11/xorg.conf
                    rm -f /etc/X11/xorg.conf.d/90-mhwd.conf
                fi
                rm -r /usr/share/kwin/decorations/kwin4_decoration_qml_plastik/
                break
            ;;
            "GNOME")
                pacman -S gnome gnome-terminal gnome-software-packagekit-plugin chrome-gnome-shell gnome-tweaks
                systemctl enable gdm
                color yellow "Install Nvidia-OptimusManager (Nvidia-Prime)? y)YES ENTER)NO"
                read TMP
                if [ "$TMP" == "y" ];then
                    pacman -S --noconfirm bbswitch-dkms acpi_call-dkms create_ap xf86-video-intel opencl-nvidia vulkan-intel vulkan-icd-loader optimus-manager nvidia-prime nvidia-settings vdpauinfo libva-vdpau-driver libva-utils -y
                    systemctl enable optimus-manager.service
                    rm -f /etc/X11/xorg.conf
                    rm -f /etc/X11/xorg.conf.d/90-mhwd.conf
                fi
                break
            ;;
            "Xfce")
                pacman -S xfce4 xfce4-goodies xfce4-terminal lightdm lightdm-gtk-greeter pulseaudio noto-fonts alsa-utils
                systemctl enable lightdm
                color yellow "Install Nvidia-OptimusManager (Nvidia-Prime)? y)YES ENTER)NO"
                read TMP
                if [ "$TMP" == "y" ];then
                    pacman -S --noconfirm bbswitch-dkms acpi_call-dkms create_ap xf86-video-intel opencl-nvidia vulkan-intel vulkan-icd-loader optimus-manager nvidia-prime nvidia-settings vdpauinfo libva-vdpau-driver libva-utils -y
                    systemctl enable optimus-manager.service
                    rm -f /etc/X11/xorg.conf
                    rm -f /etc/X11/xorg.conf.d/90-mhwd.conf
                fi
                break
            ;;
            "None")
                break
            ;;
            *)
                color red "Error ! Please input the correct num"
            ;;
        esac
    done
}

main(){
    config_base
    install_grub
    add_user
    install_graphic
    color yellow "Install Bluetooth? y)YES ENTER)NO"
    read TMP
    if [ "$TMP" == "y" ];then
        pacman -S --noconfirm bluez
        systemctl enable bluetooth
    fi
    install_app
    install_desktop
    pacman -S --noconfirm cups ghostscript gsfonts gutenprint noto-fonts-cjk  xorg-mkfontscale -y
    pacman -S --noconfirm python-pip github-desktop-bin hugo -y
    pacman -S --noconfirm steam ttf-liberation lib32-systemd proton wine boost wine-mono wine-gecko mangohud antimicrox gamemode gamescope lib32-gamemode libva-vdpau-driver vkd3d lib32-vkd3d lutris -y
    pacman -S --noconfirm zstd lib32-zstd -y
    pacman -S --noconfirm python-pytorch python-pylint python-scipy python-pynvim yapf python-numpy python-pandas python-django -y
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/49-nopasswd_global.rules && mv 49-nopasswd_global.rules /etc/polkit-1/rules.d/
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/.pam_environment && mv .pam_environment /home/arch/
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/.pam_environment && mv .pam_environment /etc/environment
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/99-kmscon.conf && mv 99-kmscon.conf /etc/fonts/conf.d/99-kmscon.conf
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/.xprofile && mv .xprofile /home/arch/
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/.xprofile && mv .xprofile /home/arch/.profile
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/genfstab && mv genfstab /usr/bin/genfstab
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/setsdk.sh && mv setsdk.sh /home/arch/setsdk.sh
    chmod a+x /usr/bin/genfstab
    chmod a+x /home/arch/setsdk.sh
    config_locale
    sbctl create-keys
    sbctl enroll-keys -m
    sed -i 's/SecureBoot/SecureB00t/' /boot/EFI/Linux/grubx64.efi
    sbctl sign -s /boot/EFI/Linux/grubx64.efi
    sbctl sign -s /boot/grub/x86_64-efi/core.efi
    sbctl sign -s /boot/grub/x86_64-efi/grub.efi
    sbctl sign -s /boot/vmlinuz-linux-zen
    color yellow "Done , Thanks for your using"
}

main
