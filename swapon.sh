#!/bin/bash

# Обработка сигнала SIGINT (Ctrl+C)
trap 'echo -e "\nСкрипт прерван пользователем."; exit 0' SIGINT

# Проверка наличия sudo
if command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# Файл для хранения настроек ZRAM
ZRAM_CONFIG="/etc/zram_config.conf"

# Функция для установки dialog
install_dialog() {
    if command -v apt &> /dev/null; then
        $SUDO apt update && $SUDO apt install -y dialog
    elif command -v yum &> /dev/null; then
        $SUDO yum install -y dialog
    elif command -v dnf &> /dev/null; then
        $SUDO dnf install -y dialog
    elif command -v pacman &> /dev/null; then
        $SUDO pacman -Sy --noconfirm dialog
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

# Проверка существующих настроек
if [ -f "$ZRAM_CONFIG" ]; then
    source "$ZRAM_CONFIG"
    dialog --msgbox "Текущие настройки ZRAM:\nРазмер: $ZRAM_SIZE\nАвтозапуск: $(if [ "$ADD_TO_AUTOSTART" -eq 1 ]; then echo "Включен"; else echo "Выключен"; fi)" 10 50
    dialog --yesno "Хотите удалить изменения или продолжить выполнение скрипта?" 7 40
    if [ $? -eq 0 ]; then
        rm -f "$ZRAM_CONFIG"
        dialog --msgbox "Настройки ZRAM удалены." 6 30
    else
        dialog --msgbox "Продолжаем выполнение скрипта." 6 30
    fi
fi

# Запрос размера zram
while true; do
    dialog --inputbox "Введите размер zram (например, 8G, 512M):" 8 40 2> /tmp/zram_size
    if [ $? -ne 0 ]; then
        dialog --msgbox "Вы отменили ввод. Скрипт завершен." 6 40
        exit 0
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
        echo -e "ZRAM_SIZE=$ZRAM_SIZE\nADD_TO_AUTOSTART=0" | $SUDO tee $ZRAM_CONFIG > /dev/null
        echo -e "#!/bin/bash\n$SUDO modprobe zram\n$SUDO sh -c 'echo \$ZRAM_SIZE > /sys/block
        echo -e "#!/bin/bash\n$SUDO modprobe zram\n$SUDO sh -c 'echo \$ZRAM_SIZE > /sys/block/zram/disksize'\n$SUDO mkswap /dev/zram0\n$SUDO swapon /dev/zram0" | $SUDO tee /etc/init.d/zram_setup > /dev/null
        $SUDO chmod +x /etc/init.d/zram_setup
        $SUDO update-rc.d zram_setup defaults
    fi

    dialog --msgbox "zram настроен успешно!" 6 30
else
    dialog --msgbox "Скрипт не был запущен." 6 30
fi

# Удаление временного файла
rm -f /tmp/zram_size
rm -f /tmp/zram_size
