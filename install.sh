#!/bin/bash

# Color
color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        green)
            echo -e "\033[32m$2\033[0m"
        ;;
        purple)
            echo -e "\033[35m$2\033[0m"
        ;;
    esac
}

curl -O https://ghproxy.com/https://raw.githubusercontent.com//archlinux-installer/main/pacman.conf && mv pacman.conf /etc/pacman.conf
echo 'Server = https://opentuna.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
pacman -Sy
pacman -S --noconfirm wget -y
pacman -S --noconfirm archlinux-keyring -y

partition(){
    if (echo $1 | grep '/' > /dev/null 2>&1);then
        other=$1
    else
        other=/$1
    fi

    fdisk -l
    color green "Input the partition (/dev/sdaX or /dev/nvme0...."
    read OTHER
    color green "Format it ? y)yes ENTER)no"
    read tmp

    if [ "$other" == "/boot" ];then
        boot=$OTHER
    fi

    if [ "$tmp" == y ];then
        umount $OTHER > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in 'ext2' "ext3" "ext4" "btrfs" "xfs" "jfs" "fat" "swap";do
            case $type in
                "ext2")
                    mkfs.ext2 $OTHER
                    break
                ;;
                "ext3")
                    mkfs.ext3 $OTHER
                    break
                ;;
                "ext4")
                    mkfs.ext4 $OTHER
                    break
                ;;
                "btrfs")
                    mkfs.btrfs $OTHER -f
                    break
                ;;
                "xfs")
                    mkfs.xfs $OTHER -f
                    break
                ;;
                "jfs")
                    mkfs.jfs $OTHER
                    break
                ;;
                "fat")
                    mkfs.fat -F32 $OTHER
                    break
                ;;
                "swap")
                    swapoff $OTHER > /dev/null 2>&1
                    mkswap $OTHER -f
                    break
                ;;
                *)
                    color red "Error ! Please input the num again"
                ;;
            esac
        done
    fi

    if [ "$other" == "/swap" ];then
        swapon $OTHER
    else
        umount $OTHER > /dev/null 2>&1
        mkdir -p /mnt$other
        mount $OTHER /mnt$other
    fi
}

prepare(){
    fdisk -l
    color green "Do you want to adjust the partition ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        color green "Input the disk (/dev/sdX or /dev/nvme0.."
        read TMP
        cfdisk $TMP
    fi
    color green "Input the ROOT(/) mount point:"
    read ROOT
    color green "Format it ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        umount $ROOT > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in "ext4" "btrfs" "xfs" "jfs";do
            umount $ROOT > /dev/null 2>&1
            if [ "$type" == "btrfs" ];then
                mkfs.$type $ROOT -f
            elif [ "$type" == "xfs" ];then
                mkfs.$type $ROOT -f
            else
                mkfs.$type $ROOT
            fi
            break
        done
    fi
    mount $ROOT /mnt
    color green "Do you have another mount point ? if so please input it, such as : /boot /home and swap or just ENTER to skip"
    read other
    while [ "$other" != '' ];do
        partition $other
        color green "Still have another mount point ? input it or just ENTER"
        read other
    done
}

install(){
    pacman -Sy
    pacstrap -i /mnt base base-devel net-tools btrfs-progs linux-firmware linux-firmware-qcom linux-firmware-qlogic linux-firmware-whence linux-firmware-nfp linux-firmware-bnx2x linux-firmware-liquidio linux-firmware-marvell linux-firmware-mellanox linux-zen linux-zen-docs linux-zen-headers
    genfstab -U -p /mnt > /mnt/etc/fstab
}

config(){
    wget https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/config.sh -O /mnt/root/config.sh
    curl -O https://ghproxy.com/https://raw.githubusercontent.com/Zhoneym/archlinux-installer/main/pacman.conf && mv pacman.conf /mnt/etc/pacman.conf
    chmod +x /mnt/root/config.sh
    arch-chroot /mnt /root/config.sh $ROOT $boot
}

prepare
install
config
