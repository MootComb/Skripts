#!/bin/bash

# Функция для автоматической установки пакетов
auto_install() {
    PACKAGE=$1
    if ! command -v $PACKAGE &> /dev/null; then
        echo "Утилита $PACKAGE не найдена. Устанавливаю..."
        sudo apt update && sudo apt install -y $PACKAGE
        if [ $? -ne 0 ]; then
            echo "Не удалось установить $PACKAGE. Пожалуйста, установите его вручную."
            exit 1
        fi
    fi
}

# Автоматическая установка необходимых утилит
auto_install dialog
auto_install util-linux  # Для modprobe, mkswap, swapon

# Запросить у пользователя размер zram
ZRAM_SIZE=$(dialog --inputbox "Введите размер zram (например, 8G, 1G и т.д.):" 8 40 3>&1 1>&2 2>&3 3>&-)

# Запросить у пользователя, добавлять ли в автозапуск
if dialog --yesno "Хотите добавить zram в автозапуск?" 7 60; then
    AUTOSTART=0
else
    AUTOSTART=1
fi

# Подтверждение выбранных параметров
CONFIRM=$(dialog --yesno "Вы выбрали:\nРазмер zram: $ZRAM_SIZE\nДобавить в автозапуск: $(if [ $AUTOSTART -eq 0 ]; then echo 'Да'; else echo 'Нет'; fi)\n\nВы хотите продолжить?" 10 60; echo $?)

if [ $? -ne 0 ]; then
    dialog --msgbox "Изменения отменены." 6 30
    exit 0
fi

# Загрузка модуля zram
sudo modprobe zram

# Установка размера zram
echo $ZRAM_SIZE | sudo tee /sys/block/zram0/disksize

# Создание области подкачки
sudo mkswap /dev/zram0

# Активация подкачки
sudo swapon /dev/zram0

# Создание файла /etc/zram, если он не существует
if [ ! -f /etc/zram ]; then
    echo "#!/bin/bash" | sudo tee /etc/zram
    echo "modprobe zram" | sudo tee -a /etc/zram
    echo "echo $ZRAM_SIZE > /sys/block/zram0/disksize" | sudo tee -a /etc/zram
    echo "mkswap /dev/zram0" | sudo tee -a /etc/zram
    echo "swapon /dev/zram0" | sudo tee -a /etc/zram
    sudo chmod +x /etc/zram
fi

# Создание службы systemd для zram
if [ ! -f /etc/systemd/system/zram.service ]; then
    echo "[Unit]" | sudo tee /etc/systemd/system/zram.service
    echo "Description=ZRAM Setup" | sudo tee -a /etc/systemd/system/zram.service
    echo "After=local-fs.target" | sudo tee -a /etc/systemd/system/zram.service
    echo "" | sudo tee -a /etc/systemd/system/zram.service
    echo "[Service]" | sudo tee -a /etc/systemd/system/zram.service
    echo "Type=forking" | sudo tee -a /etc/systemd/system/zram.service
    echo "ExecStart=/etc/zram" | sudo tee -a /etc/systemd/system/zram.service
    echo "TimeoutSec=0" | sudo tee -a /etc/systemd/system/zram.service
    echo "StandardOutput=journal" | sudo tee -a /etc/systemd/system/zram.service
    echo "RemainAfterExit=yes" | sudo tee -a /etc/systemd/system/zram.service
    echo "" | sudo tee -a /etc/systemd/system/zram.service
    echo "[Install]" | sudo tee -a /etc/systemd/system/zram.service
    echo "WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/zram.service
fi

# Включение и запуск службы zram, если пользователь выбрал автозапуск
if [[ $AUTOSTART -eq 0 ]]; then
    sudo systemctl enable zram.service
    sudo systemctl start zram.service
    dialog --msgbox "ZRAM успешно настроен и добавлен в автозапуск." 6 40
