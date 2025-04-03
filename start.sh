#!/bin/bash

# Устанавливаем переменную SUDO для использования в командах
SUDO=$(command -v sudo)

# Функция для проверки и установки пакетов
install_dependencies() {
    echo "Необходимые пакеты не найдены. Устанавливаю их..."
    $SUDO apt-get update
    $SUDO apt-get install -y dialog git
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

# Функция для отображения меню
show_menu() {
    while true; do
        # Находим все .sh файлы и директории
        SCRIPTS=(*.sh)
        DIRECTORIES=(*)

        # Создаем список для dialog
        CHOICES=()
        current_dir=$(pwd)

        for DIR in "${DIRECTORIES[@]}"; do
            if [ -d "$DIR" ]; then
                # Проверяем, не находимся ли мы в /tmp/MootComb
                if [ "$current_dir" != "$CLONE_DIR" ]; then
                    CHOICES+=("$DIR" "$DIR")
                fi
            fi
        done

        for SCRIPT in "${SCRIPTS[@]}"; do
            CHOICES+=("$SCRIPT" "$SCRIPT")
        done

        # Добавляем кнопку "Назад", если есть поддиректории
        if [ ${#DIRECTORIES[@]} -gt 0 ]; then
            CHOICES+=("back" "Назад")
        fi

        # Используем dialog для выбора файла или директории
        SELECTED_ITEM=$(dialog --title "Выберите скрипт или директорию" --menu "Выберите один из следующих элементов:" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        # Проверяем, был ли выбран элемент
        if [ $? -ne 0 ]; then
            echo "Выбор отменен."
            exit 0
        fi

        # Обрабатываем выбор
        if [ "$SELECTED_ITEM" == "back" ]; then
            return  # Возврат в предыдущее меню
        elif [ -d "$SELECTED_ITEM" ]; then
            # Если выбрана директория, переходим в нее
            cd "$SELECTED_ITEM" || exit
            echo "Вы находитесь в директории: $SELECTED_ITEM"
        else
            # Выполняем выбранный скрипт
            chmod +x "$SELECTED_ITEM"
            ./"$SELECTED_ITEM"
            exit 0  # Завершаем скрипт после выполнения
        fi
    done
}

# Запускаем меню
while true; do
    show_menu
    # После выхода из show_menu, возвращаемся в родительскую директорию
    cd "$CLONE_DIR" || exit
done
