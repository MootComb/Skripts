#!/bin/bash

# Функция для проверки успешности выполнения команды
check_command() {
    if [ $? -ne 0 ]; then
        echo "Ошибка: $1"
        exit 1
    fi
}

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
sudo apt update && sudo apt install -y python3 python3-pip
check_command "Не удалось установить необходимые пакеты."

# Установка Playwright и зависимостей
echo "Установка Playwright и зависимостей..."
pip3 install playwright python-telegram-bot pillow
check_command "Не удалось установить Playwright и зависимости."

# Установка браузеров для Playwright
echo "Установка браузеров для Playwright..."
python3 -m playwright install
check_command "Не удалось установить браузеры для Playwright."

# Создание Python-скрипта
echo "Создание Python-скрипта..."
cat << 'EOF' > playwright_screenshot.py
from playwright.sync_api import sync_playwright
from telegram import Bot
import os

GOOGLE_DOCS_URL = "https://docs.google.com/spreadsheets/d/1E2WX7jd11LviBpmbq9rildgF7NAJ_p2ERYtfEG-Prz0/edit?usp=sharing"  # Замени на URL твоего документа
TELEGRAM_BOT_TOKEN = "7178112530:AAEhI8zw_UBfyTFJojuW9TPftjzelvUobOE"  # Замени на токен твоего бота
TELEGRAM_CHAT_ID = "1642283122"  # Замени на твой chat_id

# Инициализация Playwright
with sync_playwright() as p:
    # Запуск браузера
    browser = p.chromium.launch(headless=True)  # headless=True для работы без GUI
    page = browser.new_page()

    # Переход на страницу Google Docs
    page.goto(GOOGLE_DOCS_URL)
    page.wait_for_timeout(10000)  # Ждем 10 секунд для загрузки страницы

    # Делаем скриншот всей страницы
    screenshot_path = "full_screenshot.png"
    page.screenshot(path=screenshot_path, full_page=True)  # full_page=True для скриншота всей страницы

    # Отправка скриншота в Telegram
    bot = Bot(token=TELEGRAM_BOT_TOKEN)
    with open(screenshot_path, 'rb') as photo:
        bot.send_photo(chat_id=TELEGRAM_CHAT_ID, photo=photo)

    # Удаляем временный файл
    os.remove(screenshot_path)

    # Закрываем браузер
    browser.close()
EOF
# Заменяем значения в Python-скрипте
#sed -i "s|your_telegram_bot_token|$telegram_bot_token|g" playwright_screenshot.py
#sed -i "s|your_chat_id|$telegram_chat_id|g" playwright_screenshot.py

# Запуск Python-скрипта
echo "Запуск Python-скрипта для создания скриншота и отправки в Telegram..."
python3 playwright_screenshot.py
check_command "Ошибка при выполнении Python-скрипта."

echo "Скрипт завершен."
