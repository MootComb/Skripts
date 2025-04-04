#!/bin/bash

# Copyright (c) 2025 MootComb
# Author: MootComb
# License: Apache License 2.0
# https://github.com/MootComb/Skripts/blob/main/LICENSE
# Source: https://github.com/MootComb/Skripts

# Обработка комбинации клавиш (Ctrl+C)
trap 'echo -e "Вы прервали выполнение скрипта."; exit 0' SIGINT

# Проверка наличия sudo
SUDO=$(command -v sudo || echo "")

# Переменные для путей
ZRAM_CONFIG="/etc/MootComb/zram_config.conf"  # Файл для хранения настроек ZRAM
ZRAM_SETUP_SCRIPT="/usr/local/MootComb/zram_setup.sh"  # Временный скрипт для настройки ZRAM
SYSTEMD_SERVICE="/etc/systemd/system/zram_setup.service"  # Файл службы systemd

# Функция для установки dialog
install_dialog() {
    if command -v apt &> /dev/null; then
        $SUDO apt update && $SUDO apt install -y dialog || { echo "Ошибка установки dialog."; exit 1; }
    elif command -v pacman &> /dev/null; then
        $SUDO pacman -Sy --noconfirm dialog || { echo "Ошибка установки dialog."; exit 1; }
    else
        echo "Не удалось установить dialog. Пожалуйста, установите его вручную."
        exit 1
    fi
}

# Проверка, установлен ли dialog
if ! command -v dialog &> /dev/null; then
    echo "dialog не установлен. Устанавливаю..."
    install_dialog
fi

# Функция для проверки корректности ввода размера zram
is_valid_zram_size() {
    [[ $1 =~ ^[0-9]+[GgMm]$ ]] || [[ $1 =~ ^[0-9]+[GgMm][Bb]$ ]]
}

# Функция для завершения скрипта
close() {
    echo "Вы прервали выполнение скрипта."
    exit 0
}

# Проверка существующих настроек ZRAM
if [ -f "$ZRAM_CONFIG" ]; then
    # Загрузка текущих настроек
    source "$ZRAM_CONFIG"
    
    # Отображение текущих настроек
    dialog --msgbox "Текущие настройки ZRAM:\n\nРазмер: $ZRAM_SIZE\nАвтозапуск: $(if [ "$ADD_TO_AUTOSTART" -eq 0 ]; then echo "Включен"; else echo "Выключен"; fi)" 10 50
    
    # Запрос на удаление настроек ZRAM
    if dialog --yesno "Для продолжения, удалить настройки zram?" 7 40; then
        # Удаление конфигурационного файла
        $SUDO rm -f "$ZRAM_CONFIG"
        echo "Настройки ZRAM удалены."

        # Удаление ZRAM из текущего сеанса, если он существует
        if [ -e /dev/zram0 ]; then
            $SUDO swapoff /dev/zram0  # Отключение ZRAM
            $SUDO modprobe -r zram     # Удаление модуля ZRAM
            echo "ZRAM удален из текущего сеанса."
        fi
        
        # Удаление временного скрипта, если он существует
        if [ -f "$ZRAM_SETUP_SCRIPT" ]; then
            $SUDO rm -f "$ZRAM_SETUP_SCRIPT"
            echo "Временный скрипт ZRAM удален."
        fi
        
        # Удаление systemd сервиса, если он существует
        if [ -f "$SYSTEMD_SERVICE" ]; then
            $SUDO systemctl stop zram_setup.service
            $SUDO systemctl disable zram_setup.service
            $SUDO rm -f "$SYSTEMD_SERVICE"
            $SUDO systemctl daemon-reload
            echo "ZRAM удален из автозапуска."
        fi
    else
        close
    fi
fi

# Запрос размера zram
while true; do
    dialog --inputbox "Введите размер zram (например, 8G, 512M):" 8 40 2> /tmp/zram_size
    if [ $? -ne 0 ]; then
        close
    fi

    ZRAM_SIZE=$(< /tmp/zram_size)

    if is_valid_zram_size "$ZRAM_SIZE"; then
        break
    else
        dialog --msgbox "Некорректный ввод. Пожалуйста, введите размер в формате, например, 8G или 512M." 6 50
    fi
done

# Запрос добавления в автозапуск
dialog --yesno "Добавить zram в автозапуск?" 7 40
ADD_TO_AUTOSTART=$?

# Подтверждение запуска
dialog --yesno "Текущие настройки ZRAM:\n\nРазмер: $ZRAM_SIZE\nАвтозапуск: $(if [ $ADD_TO_AUTOSTART -eq 0 ]; then echo "Включен"; else echo "Выключен"; fi)\n\nВыполнить скрипт?" 10 50
RUN_SCRIPT=$?

# Если пользователь согласен запустить скрипт
if [ $RUN_SCRIPT -eq 0 ]; then
    echo "Настройка zram..."
    
    # Загрузка модуля zram
    $SUDO modprobe zram

    # Установка размера zram
    echo $ZRAM_SIZE | $SUDO tee /sys/block/zram0/disksize > /dev/null

    # Создание swap на zram
    $SUDO mkswap /dev/zram0
    $SUDO swapon /dev/zram0

    # Добавление в автозапуск, если выбрано
    if [ $ADD_TO_AUTOSTART -eq 0 ]; then
        # Сохранение настроек
        echo -e "ZRAM_SIZE=$ZRAM_SIZE\nADD_TO_AUTOSTART=$ADD_TO_AUTOSTART" | $SUDO tee $ZRAM_CONFIG > /dev/null
        
        # Создание systemd сервиса
        echo -e "[Unit]\nDescription=ZRAM Setup\n\n[Service]\nType=oneshot\nExecStart=$ZRAM_SETUP_SCRIPT\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target" | $SUDO tee "$SYSTEMD_SERVICE" > /dev/null
        
        # Создание временного скрипта для настройки ZRAM
        echo -e "#!/bin/bash\n\n# Загрузка модуля zram\nmodprobe zram\n\n# Чтение размера zram из конфигурационного файла\nZRAM_SIZE=\$(grep ZRAM_SIZE $ZRAM_CONFIG | cut -d'=' -f2)\necho \$ZRAM_SIZE > /sys/block/zram0/disksize\n\n# Создание swap на zram\nmkswap /dev/zram0\nswapon /dev/zram0" | $SUDO tee "$ZRAM_SETUP_SCRIPT" > /dev/null
        
        # Установка прав на выполнение для скрипта
        $SUDO chmod +x "$ZRAM_SETUP_SCRIPT"
        
        # Включение сервиса
        $SUDO systemctl enable zram_setup.service
    fi

    echo "ZRAM успешно настроен."
    exit 0  # Остановка выполнения скрипта после успешной настройки
else
    close
fi

# Удаление временного файла
rm -f /tmp/zram_size
