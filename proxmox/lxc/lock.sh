#!/bin/bash

# Определяем, доступна ли команда sudo
SUDO=$(command -v sudo)

# Функция для вывода списка контейнеров
list_containers() {
    echo "Список доступных контейнеров:"
    $SUDO lxc-ls --fancy
}

# Функция для блокировки (остановки или заморозки) контейнера
lock_container() {
    local container_name=$1
    local action=$2

    case $action in
        stop)
            echo "Останавливаем контейнер $container_name..."
            $SUDO lxc-stop -n "$container_name"
            ;;
        freeze)
            echo "Замораживаем контейнер $container_name..."
            $SUDO lxc-freeze -n "$container_name"
            ;;
        *)
            echo "Неизвестное действие: $action"
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Контейнер $container_name успешно заблокирован (действие: $action)."
    else
        echo "Ошибка при блокировке контейнера $container_name."
    fi
}

# Основное меню
while true; do
    echo "Выберите действие:"
    echo "1. Заблокировать конкретный контейнер"
    echo "2. Заблокировать все контейнеры"
    echo "3. Показать список контейнеров"
    echo "4. Выйти"
    read -p "Введите номер действия: " choice

    case $choice in
        1)
            list_containers
            read -p "Введите имя контейнера: " container_name
            echo "Выберите тип блокировки:"
            echo "1. Остановить контейнер"
            echo "2. Заморозить контейнер"
            read -p "Введите номер действия: " lock_choice

            case $lock_choice in
                1)
                    lock_container "$container_name" "stop"
                    ;;
                2)
                    lock_container "$container_name" "freeze"
                    ;;
                *)
                    echo "Неверный выбор."
                    ;;
            esac
            ;;
        2)
            echo "Блокируем все контейнеры..."
            containers=$($SUDO lxc-ls)
            for container in $containers; do
                lock_container "$container" "stop"  # Останавливаем все контейнеры
            done
            ;;
        3)
            list_containers
            ;;
        4)
            echo "Выход из скрипта."
            exit 0
            ;;
        *)
            echo "Неверный выбор. Попробуйте снова."
            ;;
    esac
done
