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

if ! command -v dialog &> /dev/null || ! command -v git &> /dev/null; then
    read -p "$MSG_INSTALL_PROMPT" choice
    if [[ "$choice" == [Yy] ]]; then
        install_dependencies
    else
        exit 1
    fi
fi

REPO_URL="https://github.com/MootComb/Skripts.git"
CLONE_DIR="/tmp/MootComb"

[ -d "$CLONE_DIR" ] && rm -rf "$CLONE_DIR"

git clone "$REPO_URL" "$CLONE_DIR" || exit 1
cd "$CLONE_DIR" || exit 1

DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"

# Извлечение языка из конфигурационного файла
LANGUAGE=$(grep -E '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | xargs)

# Установка сообщений в зависимости от языка
if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_INSTALL_PROMPT="Установить необходимые пакеты? (y/n): "
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий."
    MSG_CANCELLED="Выбор отменен."
    MSG_BACK="Назад"
    MSG_SELECT="Выберите элемент:"
    MSG_TITLE="Выберите"
else
    MSG_INSTALL_PROMPT="Install necessary packages? (y/n): "
    MSG_NO_SCRIPTS="No available scripts or directories."
    MSG_CANCELLED="Selection cancelled."
    MSG_BACK="Back"
    MSG_SELECT="Select an item:"
    MSG_TITLE="Select"
fi

# Проверка наличия конфигурационного файла
CONFIG_FILE="/etc/mootcomb/choose.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    chmod +x /tmp/MootComb/choose.sh
    /tmp/MootComb/choose.sh
    exit 0
fi

# Массив исключений
EXCLUDE_FILES=("start.sh" "*.tmp")

show_menu() {
    while true; do
        SCRIPTS=()
        DIRECTORIES=()
        CHOICES=()

        # Собираем .sh файлы, если они есть
        for FILE in *; do
            # Проверяем, есть ли файл в массиве исключений
            if [[ " ${EXCLUDE_FILES[@]} " =~ " $FILE " ]]; then
                continue  # Пропускаем файл, если он в исключениях
            fi

            if [ -f "$FILE" ] && [[ "$FILE" == *.sh ]]; then
                SCRIPTS+=("$FILE")
            elif [ -d "$FILE" ]; then
                DIRECTORIES+=("$FILE")
            fi
        done

        # Добавляем директории в меню
        for DIR in "${DIRECTORIES[@]}"; do
            CHOICES+=("$DIR" "directory")  # Добавляем тип "directory"
        done

        # Добавляем .sh файлы в меню, если они есть
        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "script")  # Добавляем тип "script"
            done
        fi

        # Добавляем кнопку "Назад", если это не корневая директория
        [ "$CURRENT_DIR" != "$CLONE_DIR" ] && CHOICES+=("$MSG_BACK" "option")

        if [ ${#CHOICES[@]} -eq 0 ]; then
            echo "$MSG_NO_SCRIPTS"
            exit 0
        fi

        SELECTED_ITEM=$(dialog --title "$MSG_TITLE" --menu "$MSG_SELECT" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && echo "$MSG_CANCELLED" && exit 0

        if [ "$SELECTED_ITEM" == "$MSG_BACK" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                cd "${DIR_STACK[-1]}" || exit
                CURRENT_DIR="${DIR_STACK[-1]}"  # Обновляем текущую директорию
                DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}")  # Удаляем последнюю директорию из стека
            fi
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")  # Сохраняем текущую директорию перед переходом
            CURRENT_DIR="$CURRENT_DIR/$SELECTED_ITEM"  # Обновляем текущую директорию с учетом вложенности
            cd "$CURRENT_DIR" || exit 1
        else
            if [ -f "$SELECTED_ITEM" ]; then
                chmod +x "$SELECTED_ITEM"
                ./"$SELECTED_ITEM"  # Выполняем выбранный скрипт
                exit 0  # Завершаем текущий скрипт после выполнения
            fi
        fi
    done
}

show_menu
