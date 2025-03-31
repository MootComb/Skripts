#!/bin/bash

# Функция для получения списка LXC контейнеров
get_lxc_containers() {
    echo "Доступные LXC контейнеры:"
    pct list | awk 'NR>1 {print $1, $2}' # Пропускаем заголовок
}

# Функция для проверки примонтированных и не примонтированных дисков
get_usb_devices() {
    echo "Не примонтированные USB устройства:"
    lsblk -o NAME,SIZE,MOUNTPOINT | grep -E 'disk' | grep -v 'part' | grep -v '/mnt' | awk '$3 == "" {print $1, $2}'
}

# Функция для монтирования диска
mount_disk() {
    local disk=$1
    local mount_point="/mnt/$disk"
    mkdir -p $mount_point
    mount /dev/$disk $mount_point
    echo "$disk $mount_point" >> /etc/fstab
    echo "Диск $disk смонтирован в $mount_point и добавлен в /etc/fstab."
}

# Функция для разрешения доступа к диску в LXC контейнере
grant_disk_access() {
    local container_id=$1
    local disk=$2
    pct set $container_id -mp0 /dev/$disk
    echo "Доступ к диску $disk разрешен для LXC контейнера $container_id."
}

# Основной скрипт
get_lxc_containers
read -p "Выберите ID LXC контейнера: " container_id

get_usb_devices
read -p "Введите имя не примонтированного диска для монтирования (например, sdb): " disk_to_mount

mount_disk $disk_to_mount

# Список всех дисков
echo "Все диски:"
lsblk

read -p "Хотите ли вы разрешить доступ к диску $disk_to_mount в LXC контейнере $container_id? (y/n): " answer
if [[ $answer == "y" ]]; then
    grant_disk_access $container_id $disk_to_mount
else
    echo "Доступ к диску не был разрешен."
fi
