#!/bin/bash

# Обработка сигнала SIGINT (Ctrl+C)
trap 'echo -e "\nВы прервали выполнение скрипта."; exit 0' SIGINT

# Проверка наличия sudo
SUDO=$(command -v sudo || echo "")

# Файл для хранения настроек ZRAM
ZRAM_CONFIG="/etc/zram_config.conf"

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

# Проверка существующих настроек ZRAM
if [ -f "$ZRAM_CONFIG" ]; then
    # Загрузка текущих настроек
    source "$ZRAM_CONFIG"
    
    # Отображение текущих настроек
    dialog --msgbox "Текущие настройки ZRAM:\nРазмер: $ZRAM_SIZE\nАвтозапуск: $(if [ "$ADD_TO_AUTOSTART" -eq 1 ]; then echo "Включен"; else echo "Выключен"; fi)" 10 50
    
    # Запрос на удаление настроек ZRAM
    if dialog --yesno "Хотите удалить настройки zram?" 7 40; then
        # Удаление конфигурационного файла
        rm -f "$ZRAM_CONFIG"
        echo "Настройки ZRAM удалены."

        # Удаление ZRAM из текущего сеанса, если он существует
        if [ -e /dev/zram0 ]; then
            $SUDO swapoff /dev/zram0  # Отключение ZRAM
            $SUDO modprobe -r zram     # Удаление модуля ZRAM
            echo "ZRAM удален из текущего сеанса."
        fi

        # Удаление systemd сервиса, если он существует
        if [ -f /etc/systemd/system/zram_setup.service ]; then
            $SUDO systemctl stop zram_setup.service
            $SUDO systemctl disable zram_setup.service
            $SUDO rm -f /etc/systemd/system/zram_setup.service
            $SUDO systemctl daemon-reload
        fi
        exit 1
    else
        dialog --msgbox "Продолжаем выполнение скрипта." 6 30
    fi
fi

# Запрос размера zram
while true; do
    dialog --inputbox "Введите размер zram (например, 8G, 512M):" 8 40 2> /tmp/zram_size
        # Создание systemd сервиса
        echo -e "[Unit]\nDescription=ZRAM Setup\n\n[Service]\nType=oneshot\nExecStart=/bin/bash -c 'modprobe zram && echo \$ZRAM_SIZE > /sys/block/zram0/disksize && mkswap /dev/zram0 && swapon /dev/zram0'\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target" | $SUDO tee /etc/systemd/system/zram_setup.service > /dev/null
        
        # Включение сервиса
        $SUDO systemctl enable zram_setup.service
    fi
    
    dialog --msgbox "ZRAM успешно настроен!" 6 30
    exit 0  # Остановка выполнения скрипта после успешной настройки
else
    dialog --msgbox "Вы прервали выполнение скрипта." 6 30
    exit 0
fi

# Удаление временного файла
rm -f /tmp/zram_size
