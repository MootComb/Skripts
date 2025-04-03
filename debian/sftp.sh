#!/bin/bash

# Функция для отображения сообщений об ошибках
error() {
    echo "$1" >&2
    exit 1
}

# Проверка наличия необходимых пакетов
if ! command -v sshfs &> /dev/null; then
    echo "sshfs не установлен. Устанавливаю..."
    apt update && apt install -y sshfs || error "Не удалось установить sshfs."
fi

if ! command -v dialog &> /dev/null; then
    echo "dialog не установлен. Устанавливаю..."
    apt update && apt install -y dialog || error "Не удалось установить dialog."
fi

# Параметры монтирования
HOST=$(dialog --inputbox "Введите хост SFTP (например, example.com или 192.168.1.1):" 10 60 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 1

PORT=$(dialog --inputbox "Введите порт SFTP (по умолчанию 22):" 10 60 "22" 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 1

REMOTE_DIR=$(dialog --inputbox "Введите удаленную директорию (например, /home/user):" 10 60 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 1

LOCAL_DIR=$(dialog --inputbox "Введите локальную директорию для монтирования (например, /mnt/sftp):" 10 60 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 1

USER=$(dialog --inputbox "Введите имя пользователя для подключения к SFTP:" 10 60 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 1

PASSWORD=$(dialog --inputbox "Введите пароль для пользователя:" 10 60 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 1

# Создание локальной директории, если она не существует
mkdir -p "$LOCAL_DIR" || error "Не удалось создать локальную директорию."

# Проверка, смонтирован ли SFTP
if mount | grep "$LOCAL_DIR" > /dev/null; then
    if dialog --yesno "SFTP уже смонтирован. Хотите отмонтировать и удалить автозапуск?" 6 40; then
        fusermount -u "$LOCAL_DIR" || error "Не удалось отмонтировать SFTP."
        
        # Удаление автозапуска
        SERVICE_FILE="$HOME/.config/systemd/user/sftp-mount.service"
        if [ -f "$SERVICE_FILE" ]; then
            systemctl --user stop sftp-mount.service
            systemctl --user disable sftp-mount.service
            rm "$SERVICE_FILE"
            dialog --msgbox "Автозапуск удален." 6 40
        fi
    else
        dialog --msgbox "Скрипт завершен." 6 40
        exit 0
    fi
fi

# Монтирование SFTP с указанием порта
sshfs -p "$PORT" "$USER@$HOST:$REMOTE_DIR" "$LOCAL_DIR" -o password_stdin <<< "$PASSWORD"
if [ $? -ne 0 ]; then
    error "Не удалось смонтировать SFTP."
fi

# Запрос на добавление автозапуска
if dialog --yesno "Хотите добавить автозапуск при загрузке?" 6 40; then
    SERVICE_FILE="$HOME/.config/systemd/user/sftp-mount.service"
    
    mkdir -p "$HOME/.config/systemd/user"
    
    echo "[Unit]
Description=Mount SFTP
After=network.target

[Service]
ExecStart=$(command -v sshfs) -p $PORT $USER@$HOST:$REMOTE_DIR $LOCAL_DIR -o password_stdin <<< \"$PASSWORD\"
ExecStop=/bin/fusermount -u $LOCAL_DIR
Restart=always

[Install]
WantedBy=default.target" > "$SERVICE_FILE"

    # Перезагрузка демона systemd и включение службы
    systemctl --user daemon-reload
    systemctl --user enable sftp-mount.service
    systemctl --user start sftp-mount.service

    dialog --msgbox "Автозапуск добавлен." 6 40
else
    dialog --msgbox "Автозапуск не добавлен." 6 40
fi

dialog --msgbox "SFTP успешно смонтирован!" 6 40
