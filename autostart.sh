#!/bin/bash

# Переменная для sudo
SUDO=$(command -v sudo || echo "")

# Переменные для путей
AUTOSTART_SCRIPT="/usr/local/mootcomb/autostart.sh"  # Путь к вашему скрипту autostart.sh
SERVICE_FILE="/etc/systemd/system/autostart.service"  # Файл службы systemd
SERVICE_NAME="autostart.service"  # Имя службы

# Проверка существования systemd daemon
if systemctl list-units --full --all | grep -q "$SERVICE_NAME"; then
    echo "Служба $SERVICE_NAME уже существует."
    read -p "Хотите удалить авто запуск $SERVICE_NAME? (y/n): " REMOVE_SERVICE

    if [[ "$REMOVE_SERVICE" == "y" || "$REMOVE_SERVICE" == "Y" ]]; then
        # Остановка и отключение службы
        $SUDO systemctl stop "$SERVICE_NAME"
        $SUDO systemctl disable "$SERVICE_NAME"

        # Удаление файла службы
        if $SUDO rm "$SERVICE_FILE"; then
            echo "Служба $SERVICE_NAME успешно удалена."
        else
            echo "Ошибка: не удалось удалить службу $SERVICE_NAME."
        fi

        # Обновление systemd
        $SUDO systemctl daemon-reload
    else
        echo "Авто запуск $SERVICE_NAME не был удален."
        exit 0
    fi
else
    echo "Служба $SERVICE_NAME не найдена."
fi

# Создание директории, если она не существует
if ! $SUDO mkdir -p /usr/local/mootcomb; then
    echo "Ошибка: не удалось создать директорию /usr/local/mootcomb."
    exit 1
fi

# Создание скрипта autostart.sh
{
    echo "#!/bin/sh"
    echo "# Системный демон (systemd) находится в /lib/systemd/system/"
    echo "echo 'Скрипт autostart.sh выполнен!'"
    echo "exit 0"
} | $SUDO tee "$AUTOSTART_SCRIPT" > /dev/null

# Проверка успешности создания скрипта
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось создать файл $AUTOSTART_SCRIPT."
    exit 1
fi

# Сделать скрипт исполняемым
if ! $SUDO chmod +x "$AUTOSTART_SCRIPT"; then
    echo "Ошибка: не удалось сделать файл $AUTOSTART_SCRIPT исполняемым."
    exit 1
fi

# Создание файла службы systemd
{
    echo "[Unit]"
    echo "Description=Autostart Script"
    echo ""
    echo "[Service]"
    echo "ExecStart=$AUTOSTART_SCRIPT"
    echo "Type=oneshot"
    echo "RemainAfterExit=yes"
    echo ""
    echo "[Install]"
    echo "WantedBy=multi-user.target"
} | $SUDO tee "$SERVICE_FILE" > /dev/null

# Проверка успешности создания файла службы
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось создать файл службы $SERVICE_FILE."
    exit 1
fi

# Активировать службу
if ! $SUDO systemctl enable "$SERVICE_NAME"; then
    echo "Ошибка: не удалось активировать службу $SERVICE_NAME."
    exit 1
fi

# Запустить службу
if ! $SUDO systemctl start "$SERVICE_NAME"; then
    echo "Ошибка: не удалось запустить службу $SERVICE_NAME."
    exit 1
fi

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

# Вывод расположения скрипта после завершения всех операций
echo "Скрипт autostart.sh расположен по адресу: $AUTOSTART_SCRIPT"
