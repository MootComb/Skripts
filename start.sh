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

if [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
fi

git clone "$REPO_URL" "$CLONE_DIR" || exit 1
cd "$CLONE_DIR" || exit 1

DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"

show_menu() {
    while true; do
        SCRIPTS=(*.sh)
        DIRECTORIES=(*)
        CHOICES=()
        current_dir=$(pwd)

        for DIR in "${DIRECTORIES[@]}"; do
            if [ -d "$DIR" ]; then
                CHOICES+=("$DIR" "$DIR")
            fi
        done

        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "$SCRIPT")
            done
        fi

        if [ "$CURRENT_DIR" != "$CLONE_DIR" ]; then
            CHOICES+=("back" "Назад")
        fi

        if [ ${#CHOICES[@]} -eq 0 ]; then
            exit 0
        fi

        SELECTED_ITEM=$(dialog --title "Выберите" --menu "Выберите элемент:" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            echo "Выбор отменен."
            exit 0  # Завершаем скрипт при отмене
        fi

        if [ "$SELECTED_ITEM" == "back" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}")
                cd "$CURRENT_DIR" || continue
                CURRENT_DIR="${DIR_STACK[-1]}"
            fi
            continue
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")  # Сохраняем текущую директорию перед переходом
            CURRENT_DIR="$SELECTED_ITEM"
            cd "$CURRENT_DIR" || continue
        else
            if [ -f "$SELECTED_ITEM" ]; then
                chmod +x "$SELECTED_ITEM"
                ./"$SELECTED_ITEM"
                exit 0
            fi
        fi
    done
}

while true; do
    show_menu
    cd "$CLONE_DIR" || exit 1
done
