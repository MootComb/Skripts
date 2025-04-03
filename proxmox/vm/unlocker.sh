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

# Получаем список всех виртуальных машин с их статусами
vms=$(qm list | awk 'NR>1 {print $1, $2, $3}')  # ID, имя, статус

# Проверяем, есть ли виртуальные машины
if [ -z "$vms" ]; then
    dialog --msgbox "Нет доступных виртуальных машин!" 5 40
    exit 1
fi

# Создаем список для dialog
options=()
while read -r vm_id vm_name vm_status; do
    if [[ "$vm_status" == "locked" ]]; then
        options+=("$vm_id" "$vm_name (заблокирована)")
    fi
done <<< "$vms"

# Проверяем, есть ли заблокированные виртуальные машины
if [ ${#options[@]} -eq 0 ]; then
    dialog --msgbox "Нет заблокированных виртуальных машин!" 5 40
    exit 1
fi

# Выводим список заблокированных виртуальных машин с помощью dialog
selected_vm_id=$(dialog --title "Выберите виртуальную машину" --menu "Выберите виртуальную машину для разблокировки:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

# Проверка на отмену
exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

# Разблокируем выбранную виртуальную машину
qm unlock "$selected_vm_id"
dialog --msgbox "Виртуальная машина $selected_vm_id разблокирована!" 5 40
