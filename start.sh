#!/bin/bash

SUDO=$(command -v sudo)

install_dependencies() {
    $SUDO apt-get update
    $SUDO apt-get install -y dialog git
}

if ! command -v dialog &> /dev/null || ! command -v git &> /dev/null; then
    read -p "Установить необходимые пакеты? (y/n): " choice
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

show_menu() {
    while true; do
        SCRIPTS=()
        DIRECTORIES=()
        CHOICES=()

        # Собираем .sh файлы, если они есть
        for FILE in *; do
            if [ -f "$FILE" ] && [[ "$FILE" == *.sh ]]; then
                SCRIPTS+=("$FILE")
            elif [ -d "$FILE" ]; then
                DIRECTORIES+=("$FILE")
            fi
        done

        # Добавляем директории в меню
        for DIR in "${DIRECTORIES[@]}"; do
            CHOICES+=("$DIR" "$DIR")
        done

        # Добавляем .sh файлы в меню, если они есть
        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "$SCRIPT")
            done
        fi

        # Добавляем кнопку "Назад", если это не корневая директория
        [ "$CURRENT_DIR" != "$CLONE_DIR" ] && CHOICES+=("back" "Назад")

        if [ ${#CHOICES[@]} -eq 0 ]; then
            echo "Нет доступных скриптов или директорий."
            exit 0
        fi

        SELECTED_ITEM=$(dialog --title "Выберите" --menu "Выберите элемент:" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && echo "Выбор отменен." && exit 0

        if [ "$SELECTED_ITEM" == "back" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                cd "${DIR_STACK[-1]}" || exit 1  # Переход в предыдущую директорию
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
