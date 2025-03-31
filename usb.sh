#!/bin/bash

# Функция для вывода списка LXC контейнеров
list_lxc_containers() {
    echo "Список LXC контейнеров:"
    pct list | awk 'NR>1 {print $1, $2}'
}

# Функция для проверки и выбора контейнера
select_container() {
    read -p "Введите ID контейнера, который хотите использовать: " CT_ID
    if pct status $CT_ID &>/dev/null; then
        echo "Вы выбрали контейнер с ID: $CT_ID"
    else
        echo "Контейнер с ID $CT_ID не найден."
        exit 1
    fi
}

# Функция для вывода списка USB устройств
list_usb_devices() {
    echo "Список USB устройств:"
    lsblk -o NAME,SIZE,MOUNTPOINT | grep -i usb
}

# Функция для выбора и монтирования USB устройства
select_and_mount_usb() {
    read -p "Введите имя устройства для монтирования (например, sda1): " USB_DEVICE
    if ! mount | grep -q "/dev/$USB_DEVICE"; then
        read -p "Хотите смонтировать /dev/$USB_DEVICE? (y/n): " MOUNT_CONFIRM
        if [[ $MOUNT_CONFIRM == "y" ]]; then
            mkdir -p /mnt/$USB_DEVICE
            mount /dev/$USB_DEVICE /mnt/$USB_DEVICE
            echo "/dev/$USB_DEVICE смонтировано в /mnt/$USB_DEVICE"
        else
            echo "Устройство не смонтировано."
        fi
    else
        echo "/dev/$USB_DEVICE уже смонтировано."
    fi
}

# Функция для проброса диска в LXC контейнер
pass_disk_to_container() {
    read -p "Хотите пробросить диск в LXC контейнер? (y/n): " PASS_CONFIRM
    if [[ $PASS_CONFIRM == "y" ]]; then
        # Остановка контейнера
        pct stop $CT_ID

        # Добавление точки монтирования
        pct set $CT_ID -mp0 local-lvm:10,mp=/data

        # Получение идентификаторов блочных устройств
        LV_ID=$(lvdisplay | grep -E "LV Name" | awk '{print $3}' | grep "vm-$CT_ID-disk" | head -n 1)
        BLOCK_ID=$(lsblk -o NAME | grep "$LV_ID" | awk '{print $1}')

        # Создание скрипта монтирования
        echo '#!/bin/sh' > /var/lib/lxc/$CT_ID/mount-hook.sh
        echo "mknod -m 777 \${LXC_ROOTFS_MOUNT}/dev/sda1 b $(ls -l /dev/$BLOCK_ID | awk '{print $5, $6}')" >> /var/lib/lxc/$CT_ID/mount-hook.sh
        chmod a+x /var/lib/lxc/$CT_ID/mount-hook.sh

        # Добавление хука в конфигурацию LXC
        echo "lxc.hook.autodev: /var/lib/lxc/$CT_ID/mount-hook.sh" >> /etc/pve/lxc/$CT_ID.conf

        # Запуск контейнера
        pct start $CT_ID
        echo "Диск проброшен в контейнер $CT_ID."
    else
        echo "Диск не проброшен."
    fi
}

# Основной процесс
list_lxc_containers
select_container
list_usb_devices
select_and_mount_usb
pass_disk_to_container
