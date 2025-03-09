#!/bin/bash

# Функция для выполнения команд с или без sudo
run_command() {
    if command -v sudo &> /dev/null; then
        sudo "$@"
    else
        if [[ $EUID -eq 0 ]]; then
            "$@"
        else
            echo "Этот скрипт требует прав root. Пожалуйста, запустите его от имени root или установите sudo."
            exit 1
        fi
    fi
}

# Запросить у пользователя размер zram
read -p "Введите размер zram (например, 8G, 1G и т.д.): " ZRAM_SIZE

# Загрузка модуля zram
run_command modprobe zram

# Установка размера zram
echo $ZRAM_SIZE | run_command tee /sys/block/zram0/disksize

# Создание области подкачки
run_command mkswap /dev/zram0

# Активация подкачки
run_command swapon /dev/zram0

# Запросить у пользователя, хочет ли он добавить скрипт в автозапуск
read -p "Хотите добавить этот скрипт в автозапуск? (y/n): " ADD_TO_STARTUP

if [[ "$ADD_TO_STARTUP" == "y" ]]; then
    # Создание файла .desktop для автозапуска
    DESKTOP_FILE="$HOME/.config/autostart/setup_zram.desktop"
    
    mkdir -p "$HOME/.config/autostart"
    
    echo "[Desktop Entry]" > "$DESKTOP_FILE"
    echo "Type=Application" >> "$DESKTOP_FILE"
    echo "Exec=$HOME/setup_zram.sh" >> "$DESKTOP_FILE"
    echo "Hidden=false" >> "$DESKTOP_FILE"
    echo "NoDisplay=false" >> "$DESKTOP_FILE"
    echo "X-GNOME-Autostart-enabled=true" >> "$DESKTOP_FILE"
    echo "Name=Setup ZRAM" >> "$DESKTOP_FILE"
    
    echo "Скрипт добавлен в автозапуск."
fi

# Создание файла /etc/rc.local, если он не существует
if [ ! -f /etc/rc.local ]; then
    echo "#!/bin/bash" | run_command tee /etc/rc.local
    echo "modprobe zram" | run_command tee -a /etc/rc.local
    echo "echo $ZRAM_SIZE > /sys/block/zram0/disksize" | run_command tee -a /etc/rc.local
    echo "mkswap /dev/zram0" | run_command tee -a /etc/rc.local
    echo "swapon /dev/zram0" | run_command tee -a /etc/rc.local
    run_command chmod +x /etc/rc.local
fi

# Создание службы systemd для rc.local
if [ ! -f /etc/systemd/system/rc-local.service ]; then
    echo "[Unit]" | run_command tee /etc/systemd/system/rc-local.service
    echo "Description=/etc/rc.local Compatibility" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "ConditionPathExists=/etc/rc.local" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "[Service]" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "Type=forking" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "ExecStart=/etc/rc.local start" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "TimeoutSec=0" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "StandardOutput=journal" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "RemainAfterExit=yes" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "[Install]" | run_command tee -a /etc/systemd/system/rc-local.service
    echo "WantedBy=multi-user.target" | run_command tee -a /etc/systemd/system/rc-local.service
fi

# Включение и запуск службы rc-local
run_command systemctl enable rc-local
run_command systemctl start rc-local

echo "ZRAM настроен с размером $ZRAM_SIZE и будет активирован при загрузке."
