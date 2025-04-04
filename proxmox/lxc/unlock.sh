#!/bin/bash

# Copyright (c) 2025 MootComb
# Author: MootComb
# License: Apache License 2.0
# https://github.com/MootComb/Skripts/blob/main/LICENSE
# Source: https://github.com/MootComb/Skripts

# Проверяем, установлены ли необходимые утилиты
if ! command -v pct &> /dev/null; then
    echo "Утилита pct не найдена! Убедитесь, что Proxmox установлен."
    exit 1
fi

if ! command -v dialog &> /dev/null; then
    echo "Утилита dialog не найдена! Убедитесь, что dialog установлен."
    exit 1
fi

# Получаем список всех LXC-контейнеров с их статусами
containers=$(pct list | awk 'NR>1 {print $1, $3, $4}')  # ID, имя, статус

# Проверяем, есть ли контейнеры
if [ -z "$containers" ]; then
    dialog --msgbox "Нет доступных LXC контейнеров!" 5 40
    exit 1
fi

# Создаем список для dialog
options=()
while read -r container_id container_name container_status; do
    if [[ "$container_status" == "locked" ]]; then
        options+=("$container_id" "$container_name (заблокирован)")
    fi
done <<< "$containers"

# Проверяем, есть ли заблокированные контейнеры
if [ ${#options[@]} -eq 0 ]; then
    dialog --msgbox "Нет заблокированных LXC контейнеров!" 5 40
    exit 1
fi

# Выводим список заблокированных контейнеров с помощью dialog
selected_container_id=$(dialog --title "Выберите LXC контейнер" --menu "Выберите контейнер для разблокировки:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

# Проверка на отмену
exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

# Разблокируем выбранный контейнер
pct unlock "$selected_container_id"
dialog --msgbox "Контейнер $selected_container_id разблокирован!" 5 40
