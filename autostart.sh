#!/bin/bash

# Переменная для sudo
SUDO=$(command -v sudo || echo "")

# Переменные для путей
AUTOSTART_SCRIPT="/usr/local/mootcomb/autostart.sh"  # Путь к вашему скрипту autostart.sh
SERVICE_FILE="/etc/systemd/system/autostart.service"  # Файл службы systemd

# Создание скрипта autostart.sh
echo "#!/bin/sh" | $SUDO tee "$AUTOSTART_SCRIPT" > /dev/null
echo "# Системный демон (systemd) находится в /lib/systemd/system/" | $SUDO tee -a "$AUTOSTART_SCRIPT" > /dev/null
echo "echo 'Скрипт autostart.sh выполнен!'" | $SUDO tee -a "$AUTOSTART_SCRIPT" > /dev/null

# Сделать скрипт исполняемым
$SUDO chmod +x "$AUTOSTART_SCRIPT"

# Создание файла службы systemd
echo "[Unit]" | $SUDO tee "$SERVICE_FILE" > /dev/null
echo "Description=Autostart Script" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "[Service]" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "ExecStart=$AUTOSTART_SCRIPT" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "Type=oneshot" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "RemainAfterExit=yes" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "[Install]" | $SUDO tee -a "$SERVICE_FILE" > /dev/null
echo "WantedBy=multi-user.target" | $SUDO tee -a "$SERVICE_FILE" > /dev/null

# Активировать службу
$SUDO systemctl enable autostart.service

# Запустить службу (по желанию)
$SUDO systemctl start autostart.service

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
                $SUDO nano "$AUTOSTART_SCRIPT"
                break
            elif [[ "$EDITOR" == "vim" ]]; then
                $SUDO vim "$AUTOSTART_SCRIPT"
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
