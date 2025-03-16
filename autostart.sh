#!/bin/bash

# Путь к вашему скрипту autostart.sh
AUTOSTART_SCRIPT="/usr/local/bin/autostart.sh"

# Создание скрипта autostart.sh
echo "#!/bin/sh" > $AUTOSTART_SCRIPT
echo "echo 'Скрипт autostart.sh выполнен!'" >> $AUTOSTART_SCRIPT
echo "exit 0" >> $AUTOSTART_SCRIPT

# Сделать скрипт исполняемым
chmod +x $AUTOSTART_SCRIPT

# Создание файла службы systemd
SERVICE_FILE="/etc/systemd/system/autostart.service"

echo "[Unit]" > $SERVICE_FILE
echo "Description=Autostart Script" >> $SERVICE_FILE
echo "" >> $SERVICE_FILE
echo "[Service]" >> $SERVICE_FILE
echo "ExecStart=$AUTOSTART_SCRIPT" >> $SERVICE_FILE
echo "Type=oneshot" >> $SERVICE_FILE
echo "RemainAfterExit=yes" >> $SERVICE_FILE
echo "" >> $SERVICE_FILE
echo "[Install]" >> $SERVICE_FILE
echo "WantedBy=multi-user.target" >> $SERVICE_FILE

# Активировать службу
systemctl enable autostart.service

# Запустить службу (по желанию)
systemctl start autostart.service

# Вывод расположения скрипта
echo "Скрипт autostart.sh расположен по адресу: $AUTOSTART_SCRIPT"
