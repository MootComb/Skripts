#!/bin/bash

# Функция для вывода списка LXC контейнеров
list_lxc_containers() {
    echo "Список LXC контейнеров:"
    pct list | awk 'NR>1 {print $1, $2}'
}

# Функция для проверки и получения идентификатора контейнера
get_container_id() {
    read -p "Введите ID контейнера: " CT_ID
    if pct status $CT_ID &>/dev/null; then
        echo $CT_ID
    else
        echo "Контейнер с ID $CT_ID не найден."
        exit 1
    fi
}

# Функция для вывода списка дисков
list_disks() {
    echo "Список дисков:"
    lsblk -o NAME,SIZE,MOUNTPOINT | grep -v "loop" | grep -v "sr0"
}

# Функция для проверки и монтирования диска
mount_disk() {
    read -p "Введите путь к диску для монтирования: " DISK_PATH
    if ! mount | grep -q "$DISK_PATH"; then
        echo "Диск не смонтирован. Монтируем..."
        mkdir -p /mnt/temp_mount
        mount $DISK_PATH /mnt/temp_mount
        echo "Диск смонтирован в /mnt/temp_mount."
    else
        echo "Диск уже смонтирован."
    fi
}

# Функция для проброса диска в LXC контейнер
pass_disk_to_lxc() {
    read -p "Хотите пробросить диск в LXC контейнер? (y/n): " CHOICE
    if [[ "$CHOICE" == "y" ]]; then
        # Остановка контейнера
        pct stop $CT_ID

        # Добавление точки монтирования
        pct set $CT_ID -mp0 local-lvm:10,mp=/data

        # Получение идентификаторов блочных устройств
        LV_ID=$(lvdisplay | grep "LV Path" | awk '{print $3}' | grep "vm-$CT_ID-disk" | head -n 1)
        BLOCK_ID=$(lsblk -o NAME | grep -E "dm-|sd" | head -n 1)

        # Создание скрипта монтирования
        echo '#!/bin/sh' > /var/lib/lxc/$CT_ID/mount-hook.sh
        echo "mknod -m 777 \${LXC_ROOTFS_MOUNT}/dev/sda1 b $BLOCK_ID" >> /var/lib/lxc/$CT_ID/mount-hook.sh
        chmod a+x /var/lib/lxc/$CT_ID/mount-hook.sh

        # Добавление хука в конфигурацию LXC
        echo "lxc.hook.autodev: /var/lib/lxc/$CT_ID/mount-hook.sh" >> /etc/pve/lxc/$CT_ID.conf

        # Запуск контейнера
        pct start $CT_ID
        echo "Контейнер запущен с проброшенным диском."
    else
        echo "Проброс диска отменен."
    fi
}

# Основной процесс
list_lxc_containers
CT_ID=$(get_container_id)
list_disks
mount_disk
pass_disk_to_lxc
