#!/bin/bash

# Определяем, доступна ли команда sudo
SUDO=$(command -v sudo)

# Функция для проверки, является ли введенное значение числом
is_number() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Используем dialog для ввода количества секунд
while true; do
    # Отображаем диалоговое окно для ввода
    delay=$(dialog --stdout --inputbox "Введите количество секунд для задержки перед запуском:" 0 0)

    # Если пользователь нажал "Отмена" или "ESC", выходим из скрипта
    if [ $? -ne 0 ]; then
        echo "Отмена. Скрипт завершен."
        exit 1
    fi

    # Проверяем, является ли введенное значение числом
    if is_number "$delay"; then
        dialog --msgbox "Вы ввели корректное количество секунд: $delay" 6 40
        break
    else
        dialog --msgbox "Ошибка: Введите целое число." 6 40
    fi
done

# Изменяем значение GRUB_TIMEOUT в файле /etc/default/grub
$SUDO sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$delay/" /etc/default/grub

# Обновляем конфигурацию GRUB
$SUDO update-grub

# Выводим сообщение об успешном завершении
dialog --msgbox "Задержка перед запуском установлена на $delay секунд. Конфигурация GRUB обновлена." 8 50
