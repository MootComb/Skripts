#!/bin/bash

# Проверяем, установлены ли необходимые утилиты
if ! command -v qm &> /dev/null; then
    echo "Утилита qm не найдена! Убедитесь, что Proxmox VE установлен."
    exit 1
fi

if ! command -v dialog &> /dev/null; then
    echo "Утилита dialog не найдена! Убедитесь, что dialog установлен."
    exit 1
fi

# Получаем список всех виртуальных машин в Proxmox VE с их именами
vms=$(qm list | awk 'NR>1 {print $1, $2}')

# Проверяем, есть ли виртуальные машины
if [ -z "$vms" ]; then
    dialog --msgbox "Нет доступных виртуальных машин!" 5 40
    exit 1
fi

# Создаем список для dialog
options=()
while read -r vm_id vm_name; do
    options+=("$vm_id" "$vm_name")
done <<< "$vms"

# Выводим список виртуальных машин с помощью dialog
selected_vm_id=$(dialog --title "Выберите виртуальную машину" --menu "Выберите виртуальную машину для редактирования:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

# Проверка на отмену
exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

# Открываем конфигурационный файл выбранной виртуальной машины в nano
config_file="/etc/pve/qemu-server/$selected_vm_id.conf"
if [ -f "$config_file" ]; then
    nano "$config_file"
else
    dialog --msgbox "Конфигурационный файл не найден!" 5 40
fi
