#!/bin/bash

# Устанавливаем переменную SUDO для использования в командах
SUDO=$(command -v sudo)

# Функция для проверки и установки пакетов
install_dependencies() {
    echo "Необходимые пакеты не найдены. Установить их? (y/n)"
    read -r answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        $SUDO apt-get update
        $SUDO apt-get install dialog git
    else
        echo "Зависимости не установлены. Завершение работы."
        exit 1
    fi
}

# Проверяем наличие необходимых пакетов
if ! command -v dialog &> /dev/null || ! command -v git &> /dev/null; then
    install_dependencies
fi

# Клонируем репозиторий
REPO_URL="https://github.com/MootComb/Skripts.git"
CLONE_DIR="/tmp/MootComb"

# Очищаем временную директорию, если она существует
if [ -d "$CLONE_DIR" ]; then
    echo "Очищаем временную директорию..."
    rm -rf "$CLONE_DIR"
fi

# Клонируем репозиторий
echo "Клонируем репозиторий..."
git clone "$REPO_URL" "$CLONE_DIR"

# Переходим в директорию с скриптами
cd "$CLONE_DIR" || exit

# Находим все .sh файлы
SCRIPTS=(*.sh)

# Проверяем, есть ли .sh файлы
if [ ${#SCRIPTS[@]} -eq 0 ]; then
    echo "Нет доступных .sh файлов для выполнения."
    exit 1
fi

# Создаем список для dialog
CHOICES=()
for SCRIPT in "${SCRIPTS[@]}"; do
    CHOICES+=("$SCRIPT" "$SCRIPT")
done

# Используем dialog для выбора файла
SELECTED_SCRIPT=$(dialog --title "Выберите скрипт для выполнения" --menu "Выберите один из следующих скриптов:" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

# Проверяем, был ли выбран скрипт
if [ $? -ne 0 ]; then
    echo "Выбор отменен."
    exit 0
fi

# Выполняем выбранный скрипт
chmod +x "$SELECTED_SCRIPT"
./"$SELECTED_SCRIPT"
