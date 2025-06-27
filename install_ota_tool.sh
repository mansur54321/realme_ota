#!/bin/bash

# Цвета для вывода
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# URL-адреса для скрипта и файла устройств на GitHub

OTA_DOWNLOADER_URL="https://raw.githubusercontent.com/mansur54321/sus/refs/heads/main/ota_downloader.sh"
DEVICES_FILE_URL="https://raw.githubusercontent.com/mansur54321/sus/refs/heads/main/devices.txt"

# Функция для вывода сообщений
print_message() {
    echo -e "${GREEN}$1${RESET}"
}

# Функция для вывода ошибок
print_error() {
    echo -e "\e[31m$1${RESET}"
}

# Функция для установки на Debian/Ubuntu
install_debian() {
    print_message "Обнаружен дистрибутив на базе Debian. Установка зависимостей..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install python3 python3-pip python3-venv git -y
}

# Функция для установки на Arch Linux
install_arch() {
    print_message "Обнаружен дистрибутив на базе Arch. Установка зависимостей..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S python python-pip git --noconfirm
}

# Функция для установки на Fedora
install_fedora() {
    print_message "Обнаружен дистрибутив на базе Fedora. Установка зависимостей..."
    sudo dnf check-update
    sudo dnf install python3 python3-pip git -y
}

# Определение дистрибутива и установка
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    print_error "Не удалось определить дистрибутив. Выход."
    exit 1
fi

case "$OS" in
    "debian" | "ubuntu")
        install_debian
        ;;
    "arch")
        install_arch
        ;;
    "fedora")
        install_fedora
        ;;
    *)
        print_error "Неподдерживаемый дистрибутив: $OS. Выход."
        exit 1
        ;;
esac

# Основной процесс установки
print_message "Клонирование репозитория realme-ota..."
git clone https://github.com/R0rt1z2/realme-ota.git || { print_error "Не удалось клонировать репозиторий. Выход."; exit 1; }
cd realme-ota || { print_error "Не удалось перейти в каталог realme-ota. Выход."; exit 1; }

print_message "Настройка виртуальной среды Python..."
python3 -m venv venv
source venv/bin/activate

print_message "Установка пакета realme-ota..."
pip install . || {
    print_yellow "Произошла ошибка. Попытка установки с --break-system-packages..."
    pip install . --break-system-packages
}

print_message "Загрузка скрипта ota_downloader.sh..."
curl -o ota_downloader.sh "$OTA_DOWNLOADER_URL" || { print_error "Не удалось загрузить ota_downloader.sh. Выход."; exit 1; }
chmod +x ota_downloader.sh

print_message "Загрузка файла devices.txt..."
curl -o devices.txt "$DEVICES_FILE_URL" || { print_error "Не удалось загрузить devices.txt. Выход."; exit 1; }

# Настройка псевдонима
print_message "Настройка псевдонима 'ota'..."
# Удаляем старый псевдоним, если он существует
sed -i "/alias ota=/d" ~/.bashrc
# Добавляем новый псевдоним
echo "alias ota='cd ~/realme-ota && source venv/bin/activate && bash ota_downloader.sh'" >> ~/.bashrc

print_message "\n${BLUE}Установка завершена!${RESET}"
print_message "Чтобы использовать скрипт, перезапустите терминал или выполните:"
print_message "${YELLOW}source ~/.bashrc${RESET}"
print_message "Затем просто введите команду:"
print_message "${YELLOW}ota${RESET}"
