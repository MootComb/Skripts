#!/bin/bash

# Функция для получения списка LXC контейнеров
get_lxc_containers() {
    echo "Список LXC контейнеров:"
    pct list | awk 'NR>1 {print $1, $2}' # Выводим ID и имя контейнера
}

# Функция для получения списка USB устройств
get_usb_devices() {
    echo "Список USB устройств:"
    lsblk -o NAME,SIZE,MOUNTPOINT | grep -E 'usb|disk' | awk '{print $1, $2, $3}'
}

# Функция для проброса диска в LXC контейнер
attach_disk_to_lxc() {
    local lxc_id=$1
    local disk=$2
    pct set $lxc_id -mp0 /dev/$disk
    echo "Диск /dev/$disk проброшен в LXC контейнер $lxc_id."
}

# Получаем список LXC контейнеров
get_lxc_containers
read -p "Выберите ID LXC контейнера: " lxc_id

# Проверяем, существует ли контейнер
if ! pct status $lxc_id &>/dev/null; then
    echo "Контейнер с ID $lxc_id не найден."
    exit 1
fi

# Получаем список USB устройств
get_usb_devices
read -p "Введите имя USB устройства для проброса (например, sdb1): " usb_device

# Проверяем, примонтировано ли устройство
mountpoint=$(lsblk -o NAME,MOUNTPOINT | grep $usb_device | awk '{print $2}')
if [ -n "$mountpoint" ]; then
    echo "Устройство /dev/$usb_device уже примонтировано в $mountpoint."
else
    echo "Устройство /dev/$usb_device не примонтировано."
    read -p "Хотите примонтировать устройство? (y/n): " mount_choice
    if [ "$mount_choice" == "y" ]; then
        sudo mount /dev/$usb_device /mnt
        echo "Устройство /dev/$usb_device примонтировано в /mnt."
    fi
fi

# Спрашиваем, хотите ли вы пробросить диск в LXC контейнер
read -p "Хотите пробросить диск /dev/$usb_device в LXC контейнер $lxc_id? (y/n): " attach_choice
if [ "$attach_choice" == "y" ]; then
    attach_disk_to_lxc $lxc_id $usb_device
else
    echo "Диск не был проброшен в контейнер."
fi
