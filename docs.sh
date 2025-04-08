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
sudo apt update && sudo apt install -y python3 python3-pip wget unzip libjpeg-dev zlib1g-dev
check_command "Не удалось установить необходимые пакеты."

# Установка Google Chrome
if ! command -v google-chrome &> /dev/null; then
    echo "Установка Google Chrome..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
    check_command "Не удалось установить Google Chrome."
else
    echo "Google Chrome уже установлен."
fi

# Установка ChromeDriver
if ! command -v chromedriver &> /dev/null; then
    echo "Установка ChromeDriver..."
    CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d'.' -f1)
    CHROMEDRIVER_VERSION=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION)
    wget -q https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip
    unzip -q chromedriver_linux64.zip
    sudo mv chromedriver /usr/local/bin/
    sudo chmod +x /usr/local/bin/chromedriver
    rm chromedriver_linux64.zip
    check_command "Не удалось установить ChromeDriver."
else
    echo "ChromeDriver уже установлен."
fi

# Установка Python-библиотек
echo "Установка Python-библиотек..."
pip3 install selenium pillow python-telegram-bot webdriver-manager
check_command "Не удалось установить Python-библиотеки."

# Создание Python-скрипта
echo "Создание Python-скрипта..."
cat << 'EOF' > google_screenshot_telegram.py
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from PIL import Image
import time
from telegram import Bot
import os

# Настройки
GOOGLE_DOCS_URL = "https://docs.google.com/spreadsheets/d/your_document_id/edit"
TELEGRAM_BOT_TOKEN = "your_telegram_bot_token"
TELEGRAM_CHAT_ID = "your_chat_id"

# Инициализация браузера
chrome_options = Options()
chrome_options.add_argument("--user-data-dir=/tmp/chrome-profile")
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
driver.get(GOOGLE_DOCS_URL)

# Ждем загрузки страницы
time.sleep(10)

# Находим нужный элемент (например, таблицу)
element = driver.find_element(By.XPATH, "//div[@aria-label='Таблица']")

# Делаем скриншот элемента
location = element.location
size = element.size
driver.save_screenshot("screenshot.png")

# Обрезаем скриншот до нужного фрагмента
x = location['x']
y = location['y']
width = location['x'] + size['width']
height = location['y'] + size['height']

im = Image.open('screenshot.png')
im = im.crop((int(x), int(y), int(width), int(height)))
cropped_screenshot_path = "cropped_screenshot.png"
im.save(cropped_screenshot_path)

# Отправка скриншота в Telegram
bot = Bot(token=TELEGRAM_BOT_TOKEN)
with open(cropped_screenshot_path, 'rb') as photo:
    bot.send_photo(chat_id=TELEGRAM_CHAT_ID, photo=photo)

# Закрываем браузер
driver.quit()

# Удаляем временные файлы
os.remove("screenshot.png")
os.remove(cropped_screenshot_path)
EOF

# Настройка Python-скрипта
echo "Настройка Python-скрипта..."
read -p "Введите URL вашего документа Google Sheets: " google_docs_url
read -p "Введите токен вашего Telegram-бота: " telegram_bot_token
read -p "Введите ваш chat_id: " telegram_chat_id

sed -i "s|your_document_id|$google_docs_url|g" google_screenshot_telegram.py
sed -i "s|your_telegram_bot_token|$telegram_bot_token|g" google_screenshot_telegram.py
sed -i "s|your_chat_id|$telegram_chat_id|g" google_screenshot_telegram.py

# Запуск Python-скрипта
echo "Запуск Python-скрипта для создания скриншота и отправки в Telegram..."
python3 google_screenshot_telegram.py
check_command "Ошибка при выполнении Python-скрипта."

echo "Скрипт завершен."
