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
        SCRIPTS=(*.sh)
        DIRECTORIES=(*)
        CHOICES=()

        for DIR in "${DIRECTORIES[@]}"; do
            [ -d "$DIR" ] && CHOICES+=("$DIR" "$DIR")
        done

        [ ${#SCRIPTS[@]} -gt 0 ] && for SCRIPT in "${SCRIPTS[@]}"; do
            CHOICES+=("$SCRIPT" "$SCRIPT")
        done

        [ "$CURRENT_DIR" != "$CLONE_DIR" ] && CHOICES+=("back" "Назад")

        if [ ${#CHOICES[@]} -eq 0 ]; then
            echo "Нет доступных скриптов или директорий."
            exit 0
        fi

        SELECTED_ITEM=$(dialog --title "Выберите" --menu "Выберите элемент:" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && echo "Выбор отменен." && exit 0

        if [ "$SELECTED_ITEM" == "back" ]; then
            [ ${#DIR_STACK[@]} -gt 0 ] && CURRENT_DIR="${DIR_STACK[-1]}" && DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}") && cd "$CURRENT_DIR" || continue
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$SELECTED_ITEM"
            cd "$CURRENT_DIR" || continue
        else
            [ -f "$SELECTED_ITEM" ] && chmod +x "$SELECTED_ITEM" && ./"$SELECTED_ITEM"
        fi
    done
}

while true; do
    show_menu
    cd "$CLONE_DIR" || exit 1
done
