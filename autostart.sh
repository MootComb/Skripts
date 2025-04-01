#!/bin/bash

# Переменные для путей
AUTOSTART_SCRIPT="/usr/local/mootcomb/autostart.sh"  # Путь к вашему скрипту autostart.sh
SERVICE_FILE="/etc/systemd/system/autostart.service"  # Файл службы systemd

# Создание скрипта autostart.sh
echo "#!/bin/sh" > "$AUTOSTART_SCRIPT"
echo "# Системный демон (systemd) находится в /lib/systemd/system/" >> "$AUTOSTART_SCRIPT"
echo "echo 'Скрипт autostart.sh выполнен!'" >> "$AUTOSTART_SCRIPT"
echo "exit 0" >> "$AUTOSTART_SCRIPT"

# Сделать скрипт исполняемым
chmod +x "$AUTOSTART_SCRIPT"

# Создание файла службы systemd
echo "[Unit]" > "$SERVICE_FILE"
echo "Description=Autostart Script" >> "$SERVICE_FILE"
echo "" >> "$SERVICE_FILE"
echo "[Service]" >> "$SERVICE_FILE"
echo "ExecStart=$AUTOSTART_SCRIPT" >> "$SERVICE_FILE"
echo "Type=oneshot" >> "$SERVICE_FILE"
echo "RemainAfterExit=yes" >> "$SERVICE_FILE"
echo "" >> "$SERVICE_FILE"
echo "[Install]" >> "$SERVICE_FILE"
echo "WantedBy=multi-user.target" >> "$SERVICE_FILE"

# Активировать службу
systemctl enable autostart.service

# Запустить службу (по желанию)
systemctl start autostart.service

# Вывод расположения скрипта
echo "Скрипт autostart.sh расположен по адресу: $AUTOSTART_SCRIPT"

# Запрос на открытие скрипта
while true; do
    read -p "Хотите открыть $AUTOSTART_SCRIPT для редактирования? (y/n): " OPEN_SCRIPT
    if [[ "$OPEN_SCRIPT" == "y" || "$OPEN_SCRIPT" == "Y" ]]; then
        # Запрос на выбор редактора
        while true; do
            read -p "Выберите редактор (nano/vim): " EDITOR
            if [[ "$EDITOR" == "nano" ]]; then
                nano "$AUTOSTART_SCRIPT"
                break
            elif [[ "$EDITOR" == "vim" ]]; then
                vim "$AUTOSTART_SCRIPT"
                break
            else
                echo "Неверный выбор редактора. Пожалуйста, выберите nano или vim."
            fi
        done
        break
    elif [[ "$OPEN_SCRIPT" == "n" || "$OPEN_SCRIPT" == "N" ]]; then
        break
    else
        echo "Неверный ответ. Пожалуйста, введите 'y' или 'n'."
    fi
done

# Вывод расположения скрипта после закрытия редактора
echo "Скрипт autostart.sh расположен по адресу: $AUTOSTART_SCRIPT"
