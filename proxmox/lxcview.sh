#!/bin/bash

# Получаем список всех контейнеров LXC
containers=$(lxc list -c n --format csv)

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
config_file="/var/lib/lxc/$selected_container/config"
if [ -f "$config_file" ]; then
    nano "$config_file"
else
    dialog --msgbox "Конфигурационный файл не найден." 5 40
fi
