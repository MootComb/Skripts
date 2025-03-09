#!/bin/bash

# Функция для установки dialog
install_dialog() {
    if command -v apt &> /dev/null; then
        $SUDO apt update && $SUDO apt install -y dialog
    elif command -v yum &> /dev/null; then
        $SUDO yum install -y dialog
    elif command -v dnf &> /dev/null; then
        $SUDO dnf install -y dialog
    else
        echo "Не удалось установить dialog. Пожалуйста, установите его вручную."
        exit 1
    fi
}

# Проверка, установлен ли dialog
if ! command -v dialog &> /dev/null; then
    echo "dialog не установлен. Устанавливаю..."
    # Проверка наличия sudo
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        SUDO=""
    fi
    install_dialog
fi

# Проверка наличия sudo
if command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# Запрос размера zram
dialog --inputbox "Введите размер zram (например, 8G):" 8 40 2> /tmp/zram_size
ZRAM_SIZE=$(< /tmp/zram_size)

# Запрос добавления в автозапуск
dialog --yesno "Добавить zram в автозапуск?" 7 40
ADD_TO_AUTOSTART=$?

# Подтверждение запуска
dialog --yesno "Вы выбрали:\nРазмер zram: $ZRAM_SIZE\nДобавить в автозапуск: $(if [ $ADD_TO_AUTOSTART -eq 0 ]; then echo "Да"; else echo "Нет"; fi)\n\nЗапустить скрипт?" 10 50
RUN_SCRIPT=$?

# Если пользователь согласен запустить скрипт
if [ $RUN_SCRIPT -eq 0 ]; then
    # Настройка zram
    $SUDO modprobe zram
    echo $ZRAM_SIZE | $SUDO tee /sys/block/zram/disksize > /dev/null
    $SUDO mkswap /dev/zram0
    $SUDO swapon /dev/zram0

    # Добавление в автозапуск, если выбрано
    if [ $ADD_TO_AUTOSTART -eq 0 ]; then
        echo -e "#!/bin/bash\n$SUDO modprobe zram\n$SUDO sh -c 'echo $ZRAM_SIZE > /sys/block/zram/disksize'\n$SUDO mkswap /dev/zram0\n$SUDO swapon /dev/zram0" | $SUDO tee /etc/init.d/zram_setup > /dev/null
        $SUDO chmod +x /etc/init.d/zram_setup
        $SUDO update-rc.d zram_setup defaults
    fi

    dialog --msgbox "zram настроен успешно!" 6 30
else
    dialog --msgbox "Скрипт не был запущен." 6 30
fi

# Удаление временного файла
rm -f /tmp/zram_size
