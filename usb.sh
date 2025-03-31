#!/bin/bash

# Функция для получения списка LXC контейнеров
get_lxc_containers() {
    # Получаем список контейнеров с помощью qm list
    qm list | awk 'NR>1 {print $1, $2}' | tr '\n' ' '
}

# Функция для получения списка дисков
get_disks() {
    # Получаем список дисков из директории /mnt
    ls /mnt | grep -E '^disk[0-9]+$' | tr '\n' ' '
}

# Получаем список контейнеров
containers=($(get_lxc_containers))
# Получаем список дисков
disks=($(get_disks))

# Проверяем, есть ли контейнеры и диски
if [ ${#containers[@]} -eq 0 ]; then
    dialog --msgbox "Нет доступных LXC контейнеров." 5 40
    exit 1
fi

if [ ${#disks[@]} -eq 0 ]; then
    dialog --msgbox "Нет доступных дисков." 5 40
    exit 1
fi

# Выбор контейнера
container=$(dialog --title "Выбор LXC контейнера" --menu "Выберите контейнер:" 15 50 ${#containers[@]} "${containers[@]}" 3>&1 1>&2 2>&3)
exit_status=$?
if [ $exit_status != 0 ]; then
    exit 1
fi

# Выбор диска
disk=$(dialog --title "Выбор диска" --menu "Выберите диск:" 15 50 ${#disks[@]} "${disks[@]}" 3>&1 1>&2 2>&3)
exit_status=$?
if [ $exit_status != 0 ]; then
    exit 1
fi

# Разрешаем доступ к диску для контейнера
# Здесь вы можете добавить команду для монтирования диска или изменения конфигурации контейнера
# Например, если вы хотите добавить диск в конфигурацию контейнера:
# echo "lxc.mount.entry = /mnt/$disk mnt/$disk none bind 0 0" >> /etc/lxc/$container.conf

dialog --msgbox "Доступ к диску $disk разрешен для контейнера $container." 5 40

exit 0
