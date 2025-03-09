#!/bin/bash

# Проверка наличия dialog и установка, если он не установлен
if ! command -v dialog &> /dev/null; then
    echo "Пакет dialog не установлен. Устанавливаю его..."
    sudo apt update && sudo apt install -y dialog
    if [ $? -ne 0 ]; then
        echo "Ошибка при установке dialog. Пожалуйста, установите его вручную."
        exit 1
    fi
fi

# Запросить у пользователя размер zram
ZRAM_SIZE=$(dialog --inputbox "Введите размер zram (например, 8G, 1G и т.д.):" 8 40 3>&1 1>&2 2>&3 3>&-)

# Запросить у пользователя, добавлять ли в автозапуск
AUTOSTART=$(dialog --yesno "Хотите добавить zram в автозапуск?" 7 60; echo $?)

# Загрузка модуля zram
sudo modprobe zram

# Установка размера zram
echo $ZRAM_SIZE | sudo tee /sys/block/zram0/disksize

# Создание области подкачки
sudo mkswap /dev/zram0

# Активация подкачки
sudo swapon /dev/zram0

# Создание файла /etc/rc.local, если он не существует
if [ ! -f /etc/rc.local ]; then
    echo "#!/bin/bash" | sudo tee /etc/rc.local
    echo "modprobe zram" | sudo tee -a /etc/rc.local
    echo "echo $ZRAM_SIZE > /sys/block/zram0/disksize" | sudo tee -a /etc/rc.local
    echo "mkswap /dev/zram0" | sudo tee -a /etc/rc.local
    echo "swapon /dev/zram0" | sudo tee -a /etc/rc.local
    sudo chmod +x /etc/rc.local
fi

# Создание службы systemd для rc.local
if [ ! -f /etc/systemd/system/rc-local.service ]; then
    echo "[Unit]" | sudo tee /etc/systemd/system/rc-local.service
    echo "Description=/etc/rc.local Compatibility" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "ConditionPathExists=/etc/rc.local" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "[Service]" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "Type=forking" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "ExecStart=/etc/rc.local start" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "TimeoutSec=0" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "StandardOutput=journal" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "RemainAfterExit=yes" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "[Install]" | sudo tee -a /etc/systemd/system/rc-local.service
    echo "WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/rc-local.service
fi

# Включение и запуск службы rc-local, если пользователь выбрал автозапуск
if [[ $AUTOSTART -eq 0 ]]; then
    sudo systemctl enable rc-local
    sudo systemctl start rc-local
    dialog --msgbox "ZRAM настроен с размером $ZRAM_SIZE и будет активирован при загрузке." 6 50
else
    dialog --msgbox "ZRAM настроен с размером $ZRAM_SIZE, но не будет добавлен в автозапуск." 6 50
fi

# Очистка
clear
