#!/bin/bash

# Проверяем, установлены ли необходимые утилиты
if ! command -v pct &> /dev/null; then
    echo "Утилита pct не найдена. Убедитесь, что Proxmox установлен."
    exit 1
fi

if ! command -v dialog &> /dev/null; then
    echo "Утилита dialog не найдена. Убедитесь, что dialog установлен."
    exit 1
fi

# Получаем список всех контейнеров LXC в Proxmox
containers=$(pct list | awk 'NR>1 {print $1}')

# Проверяем, есть ли контейнеры
if [ -z "$containers" ]; then
    dialog --msgbox "Нет доступных контейнеров LXC." 5 40
    exit 1
fi

# Создаем массив контейнеров
IFS=$'\n' read -r -d '' -a container_array <<< "$containers"

# Создаем список для dialog
options=()
for container in "${container_array[@]}"; do
    options+=("$container" "$container")
done

# Выводим список контейнеров с помощью dialog
selected_container=$(dialog --title "Выберите LXC контейнер" --menu "Выберите контейнер для редактирования:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

# Проверка на отмену
exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

# Открываем конфигурационный файл выбранного контейнера в nano
config_file="/etc/pve/lxc/$selected_container.conf"
if [ -f "$config_file" ]; then
    nano "$config_file"
else
    dialog --msgbox "Конфигурационный файл не найден." 5 40
fi
