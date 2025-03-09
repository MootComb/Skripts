#!/bin/bash

# Проверка, установлен ли dialog
if ! command -v dialog &> /dev/null; then
    echo "Пожалуйста, установите dialog для работы этого скрипта."
    exit 1
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
    sudo modprobe zram
    echo $ZRAM_SIZE > /sys/block/zram/disksize
    sudo mkswap /dev/zram0
    sudo swapon /dev/zram0

    # Добавление в автозапуск, если выбрано
    if [ $ADD_TO_AUTOSTART -eq 0 ]; then
        echo -e "#!/bin/bash\nsudo modprobe zram\nsudo sh -c 'echo $ZRAM_SIZE > /sys/block/zram/disksize'\nsudo mkswap /dev/zram0\nsudo swapon /dev/zram0" | sudo tee /etc/init.d/zram_setup
        sudo chmod +x /etc/init.d/zram_setup
        sudo update-rc.d zram_setup defaults
    fi

    dialog --msgbox "zram настроен успешно!" 6 30
else
    dialog --msgbox "Скрипт не был запущен." 6 30
fi

# Удаление временного файла
rm -f /tmp/zram_size
