#!/bin/bash

# Цвета для вывода
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

# URL-адреса для скрипта и файла устройств на GitHub
OTA_DOWNLOADER_URL="https://raw.githubusercontent.com/mansur54321/realme_ota/refs/heads/main/ota_downloader.sh"
DEVICES_FILE_URL="https://raw.githubusercontent.com/mansur54321/realme_ota/refs/heads/main/devices.txt"
REALME_OTA_REPO="https://github.com/R0rt1z2/realme-ota.git"

# --- Функции ---

# Функция для вывода сообщений
print_message() {
    echo -e "${GREEN}[INFO] $1${RESET}"
}

# Функция для вывода ошибок
print_error() {
    echo -e "${RED}[ERROR] $1${RESET}"
}

# Функция для вывода предупреждений
print_warning() {
    echo -e "${YELLOW}[WARN] $1${RESET}"
}

# --- Логика установки для разных ОС ---

install_debian() {
    print_message "Обнаружен дистрибутив на базе Debian. Установка зависимостей..."
    sudo apt update && sudo apt install python3 python3-pip python3-venv git curl -y
    PYTHON_CMD="python3"
}

install_arch() {
    print_message "Обнаружен дистрибутив на базе Arch. Установка зависимостей..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S python python-pip git curl --noconfirm
    PYTHON_CMD="python"
}

install_fedora() {
    print_message "Обнаружен дистрибутив на базе Fedora. Установка зависимостей..."
    sudo dnf check-update
    sudo dnf install python3 python3-pip git curl -y
    PYTHON_CMD="python3"
}

install_termux() {
    print_message "Обнаружен Termux. Установка зависимостей..."
    pkg update && pkg upgrade -y
    pkg install python python-pip git curl -y
    PYTHON_CMD="python"
}

install_windows() {
    print_message "Обнаружен Git Bash для Windows. Проверка зависимостей..."
    PYTHON_CMD="python"
    
    if ! command -v python &> /dev/null; then
        print_error "Python не найден!"
        print_warning "Пожалуйста, установите Python для Windows с сайта python.org"
        print_warning "ВАЖНО: Во время установки обязательно поставьте галочку 'Add Python to PATH'."
        exit 1
    fi
    print_message "Python найден."

    if ! command -v git &> /dev/null; then
        print_error "Git не найден! Пожалуйста, переустановите Git for Windows."
        exit 1
    fi
    print_message "Git найден."
    
    if ! command -v curl &> /dev/null; then
        print_error "cURL не найден! Пожалуйста, переустановите Git for Windows, выбрав компонент cURL."
        exit 1
    fi
    print_message "cURL найден."
}

# --- Основная логика скрипта ---

# 1. Определение ОС
OS=""
PYTHON_CMD="python3" # Значение по умолчанию

if [[ "$(uname -o)" == "Msys" ]]; then
    OS="windows"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    if [[ "$ID_LIKE" == *"termux"* ]]; then
        OS="termux"
    fi
elif [ -d "/data/data/com.termux" ]; then
    OS="termux"
else
    print_error "Не удалось определить вашу операционную систему. Выход."
    exit 1
fi

# 2. Установка зависимостей и определение переменных для конкретной ОС
case "$OS" in
    "debian" | "ubuntu") install_debian ;;
    "arch") install_arch ;;
    "fedora") install_fedora ;;
    "termux") install_termux ;;
    "windows") install_windows ;;
    *)
        print_error "Неподдерживаемая система: $OS. Выход."
        exit 1
        ;;
esac

# 3. Определение правильного пути для активации venv
VENV_ACTIVATE_PATH="venv/bin/activate" # По умолчанию для Linux/Termux
if [ "$OS" == "windows" ]; then
    VENV_ACTIVATE_PATH="venv/Scripts/activate" # Путь для Windows
fi

# 4. Обработка существующей папки realme-ota
INSTALL_DIR="$HOME/realme-ota"
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Папка 'realme-ota' уже существует в вашем домашнем каталоге."
    read -p "$(echo -e "${YELLOW}Вы хотите обновить (u), переустановить (r) или пропустить (s)? [u/r/s]: ${RESET}")" choice
    case "$choice" in
        u|U )
            print_message "Обновление существующей установки..."
            cd "$INSTALL_DIR" || { print_error "Не удалось перейти в каталог. Выход."; exit 1; }
            git pull || { print_error "Не удалось обновить репозиторий."; exit 1; }
            ;;
        r|R )
            print_warning "Удаление существующей папки '$INSTALL_DIR'..."
            rm -rf "$INSTALL_DIR" || { print_error "Не удалось удалить папку. Проверьте права доступа."; exit 1; }
            print_message "Клонирование репозитория заново..."
            git clone "$REALME_OTA_REPO" "$INSTALL_DIR" || { print_error "Не удалось клонировать репозиторий. Выход."; exit 1; }
            cd "$INSTALL_DIR" || { print_error "Не удалось перейти в каталог. Выход."; exit 1; }
            ;;
        * )
            print_message "Пропускаем клонирование. Используется существующая папка."
            cd "$INSTALL_DIR" || { print_error "Не удалось перейти в каталог. Выход."; exit 1; }
            ;;
    esac
else
    print_message "Клонирование репозитория realme-ota в $INSTALL_DIR..."
    git clone "$REALME_OTA_REPO" "$INSTALL_DIR" || { print_error "Не удалось клонировать репозиторий. Выход."; exit 1; }
    cd "$INSTALL_DIR" || { print_error "Не удалось перейти в каталог. Выход."; exit 1; }
fi

# 5. Настройка виртуальной среды и установка пакетов
print_message "Настройка виртуальной среды Python..."
$PYTHON_CMD -m venv venv
source "$VENV_ACTIVATE_PATH"

print_message "Установка пакета realme-ota из локального репозитория..."
pip install . || {
    print_warning "Произошла ошибка при обычной установке. Попытка установки с --break-system-packages..."
    pip install . --break-system-packages || { print_error "Не удалось установить пакет realme-ota. Выход."; exit 1; }
}
deactivate # Временно деактивируем для чистоты

# 6. Загрузка вспомогательных файлов
print_message "Загрузка скрипта ota_downloader.sh..."
curl -L -o ota_downloader.sh "$OTA_DOWNLOADER_URL" || { print_error "Не удалось загрузить ota_downloader.sh. Выход."; exit 1; }
chmod +x ota_downloader.sh

print_message "Загрузка файла devices.txt..."
curl -L -o devices.txt "$DEVICES_FILE_URL" || { print_error "Не удалось загрузить devices.txt. Выход."; exit 1; }

# 7. Настройка псевдонима (alias)
print_message "Настройка псевдонима 'ota' в ~/.bashrc..."
# Удаляем старый псевдоним, если он существует, чтобы избежать дублирования
sed -i.bak "/alias ota=/d" ~/.bashrc
# Добавляем новый псевдоним с ПРАВИЛЬНЫМ путем активации для вашей ОС
echo "alias ota='cd \"$INSTALL_DIR\" && source \"$VENV_ACTIVATE_PATH\" && bash ota_downloader.sh'" >> ~/.bashrc

# 8. Завершение установки
print_message "\n${BLUE}Установка успешно завершена!${RESET}"
print_message "Чтобы изменения вступили в силу, перезапустите терминал или выполните команду:"
print_message "${YELLOW}source ~/.bashrc${RESET}"
print_message "После этого для запуска просто введите в терминале:"
print_message "${YELLOW}ota${RESET}"
