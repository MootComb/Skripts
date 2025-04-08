#!/bin/bash
sudo apt update && sudo apt install -y python3 python3-pip wget unzip libjpeg-dev zlib1g-dev
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb
CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d'.' -f1)
CHROMEDRIVER_VERSION=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION)
wget -q https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip
unzip -q chromedriver_linux64.zip
sudo mv chromedriver /usr/local/bin/
sudo chmod +x /usr/local/bin/chromedriver
rm chromedriver_linux64.zip
pip3 install selenium pillow python-telegram-bot webdriver-manager
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
GOOGLE_DOCS_URL = "https://docs.google.com/spreadsheets/d/your_document_id/edit"
TELEGRAM_BOT_TOKEN = "your_telegram_bot_token"
TELEGRAM_CHAT_ID = "your_chat_id"
chrome_options = Options()
chrome_options.add_argument("--user-data-dir=/tmp/chrome-profile")
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
driver.get(GOOGLE_DOCS_URL)
time.sleep(10)
element = driver.find_element(By.XPATH, "//div[@aria-label='Таблица']")
location = element.location
size = element.size
driver.save_screenshot("screenshot.png")
x = location['x']
y = location['y']
width = location['x'] + size['width']
height = location['y'] + size['height']
im = Image.open('screenshot.png')
im = im.crop((int(x), int(y), int(width), int(height)))
cropped_screenshot_path = "cropped_screenshot.png"
im.save(cropped_screenshot_path)
bot = Bot(token=TELEGRAM_BOT_TOKEN)
with open(cropped_screenshot_path, 'rb') as photo:
    bot.send_photo(chat_id=TELEGRAM_CHAT_ID, photo=photo)
driver.quit()
os.remove("screenshot.png")
os.remove(cropped_screenshot_path)
EOF
read -p "Введите URL вашего документа Google Sheets: " google_docs_url
read -p "Введите токен вашего Telegram-бота: " telegram_bot_token
read -p "Введите ваш chat_id: " telegram_chat_id
sed -i "s|your_document_id|$google_docs_url|g" google_screenshot_telegram.py
sed -i "s|your_telegram_bot_token|$telegram_bot_token|g" google_screenshot_telegram.py
sed -i "s|your_chat_id|$telegram_chat_id|g" google_screenshot_telegram.py
python3 google_screenshot_telegram.py
