#!/bin/bash

# Copyright (c) 2025 MootComb
# Author: MootComb
# License: Apache License 2.0
# https://github.com/MootComb/Skripts/blob/main/LICENSE
# Source: https://github.com/MootComb/Skripts

SUDO=$(command -v sudo)

install_dependencies() {
    $SUDO apt-get update
    $SUDO apt-get install -y dialog git
}

# Проверка наличия конфигурационного файла
CONFIG_FILE="/etc/MootComb/choose.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Конфигурационный файл не найден. Выполняем choose.sh."
    CHOOSE_SCRIPT="/tmp/MootComb/choose.sh"
    if [ -f "$CHOOSE_SCRIPT" ]; then
        chmod +x "$CHOOSE_SCRIPT"
        "$CHOOSE_SCRIPT"
    else
        echo "Ошибка: Скрипт choose.sh не найден в $CHOOSE_SCRIPT."
        exit 1
    fi
fi

# Извлечение языка из конфигурационного файла
LANGUAGE=$(grep -E '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | xargs)

# Установка сообщений в зависимости от языка
if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_INSTALL_PROMPT="Установить необходимые пакеты? (y/n): "
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий."
    MSG_CANCELLED="Выбор отменен."
    MSG_BACK="назад"
    MSG_SELECT="Выберите опцию:"
    MSG_CLONE_ERROR="Ошибка: Не удалось клонировать репозиторий."
    MSG_CD_ERROR="Ошибка: Не удалось перейти в директорию."
#    MSG_TITLE="Текущая директория: $CURRENT_DIR"
else
    MSG_INSTALL_PROMPT="Install necessary packages? (y/n): "
    MSG_NO_SCRIPTS="No available scripts or directories."
    MSG_CANCELLED="Selection cancelled."
    MSG_BACK="back"
    MSG_SELECT="Select an option:"
    MSG_CLONE_ERROR="Error: Failed to clone the repository."
    MSG_CD_ERROR="Error: Failed to change directory."
#    MSG_TITLE="Current directory: $CURRENT_DIR"
fi

# Проверка и установка зависимостей
if ! command -v dialog &> /dev/null || ! command -v git &> /dev/null; then
    read -p "$MSG_INSTALL_PROMPT" choice
    if [[ "$choice" == [Yy] ]]; then
        install_dependencies
    else
        exit 1
    fi
fi

# Клонирование репозитория
REPO_URL="https://github.com/MootComb/Skripts.git"
CLONE_DIR="/tmp/MootComb"

if [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
fi

git clone "$REPO_URL" "$CLONE_DIR" || { echo "$MSG_CLONE_ERROR"; exit 1; }
cd "$CLONE_DIR" || { echo "$MSG_CD_ERROR $CLONE_DIR."; exit 1; }

DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"

# Массив исключений
EXCLUDE_FILES=("start.sh" "*.tmp")

show_menu() {
    while true; do
        SCRIPTS=()
        DIRECTORIES=()
        CHOICES=()

        # Собираем .sh файлы, если они есть
        for FILE in *; do
            if [[ " ${EXCLUDE_FILES[@]} " =~ " $FILE " ]]; then
                continue
            fi

            if [ -f "$FILE" ] && [[ "$FILE" == *.sh ]]; then
                SCRIPTS+=("$FILE")
            elif [ -d "$FILE" ]; then
                DIRECTORIES+=("$FILE")
            fi
        done

        # Добавляем директории в меню
        for DIR in "${DIRECTORIES[@]}"; do
            CHOICES+=("$DIR" "directory")
        done

        # Добавляем .sh файлы в меню, если они есть
        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "script")
            done
        fi

        # Добавляем кнопку "Назад", если это не корневая директория
        [ "$CURRENT_DIR" != "$CLONE_DIR" ] && CHOICES+=("$MSG_BACK" "option")

        if [ ${#CHOICES[@]} -eq 0 ]; then
            echo "$MSG_NO_SCRIPTS"
            exit 0
        fi

        # Обновляем MSG_TITLE с текущей директорией
        if [[ "$LANGUAGE" == "Русский" ]]; then
            MSG_TITLE="$CURRENT_DIR"
        else
            MSG_TITLE="$CURRENT_DIR"
        fi

        # Отображение меню с помощью dialog
        SELECTED_ITEM=$(dialog --title "$MSG_TITLE" --menu "$MSG_SELECT" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        # Проверка, была ли отмена выбора
        if [ $? -ne 0 ]; then
            echo "$MSG_CANCELLED"
            exit 0
        fi

        # Обработка выбора пользователя
        if [ "$SELECTED_ITEM" == "$MSG_BACK" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                cd "${DIR_STACK[-1]}" || { echo "$MSG_CD_ERROR ${DIR_STACK[-1]}."; exit 1; }
                CURRENT_DIR="${DIR_STACK[-1]}"
                DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}")
            fi
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$CURRENT_DIR/$SELECTED_ITEM"
            cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR $CURRENT_DIR."; exit 1; }
        else
            if [ -f "$SELECTED_ITEM" ]; then
                chmod +x "$SELECTED_ITEM"
                ./"$SELECTED_ITEM"
                exit 0
            fi
        fi
    done
}

# Запуск меню
show_menu
