# Настройка монтирования resize_cache на Битрикс сервере

## Концепция двустороннего монтирования

Система работает с двусторонним SSHFS монтированием:

1. **CDN сервер → Битрикс сервер**: CDN монтирует `/var/www/bitrix/upload/` для чтения оригиналов
2. **Битрикс сервер → CDN сервер**: Битрикс монтирует `/var/www/cdn/upload/resize_cache/` для записи превью

## Workflow работы

1. Битрикс генерирует resize_cache и пишет в `/var/www/bitrix/upload/resize_cache/`
2. Эта папка примонтирована через SSHFS с CDN сервера
3. Файлы физически сохраняются на CDN сервере в `/var/www/cdn/upload/resize_cache/`
4. CDN сервер автоматически создает WebP версии всех новых файлов
5. При запросе CDN отдает WebP если браузер поддерживает

## Установка на Битрикс сервере (Server1)

### Автоматическая установка

```bash
# Скачать скрипт установки
wget https://cdn.termokit.ru/scripts/setup-bitrix-mount.sh
chmod +x setup-bitrix-mount.sh

# Запустить с параметрами вашего CDN сервера
CDN_SERVER_IP=192.168.1.20 \
CDN_SERVER_USER=cdn \
./setup-bitrix-mount.sh
```

### Ручная установка

#### 1. Установить SSHFS

```bash
apt-get update
apt-get install -y sshfs fuse
```

#### 2. Создать SSH ключ

```bash
ssh-keygen -t rsa -b 4096 -f /root/.ssh/cdn_mount -N ""
```

#### 3. Добавить публичный ключ на CDN сервер

Скопировать содержимое `/root/.ssh/cdn_mount.pub` и добавить в файл `/home/cdn/.ssh/authorized_keys` на CDN сервере.

#### 4. Создать точку монтирования

```bash
# Создать директорию если не существует
mkdir -p /var/www/bitrix/upload/resize_cache
```

#### 5. Настроить автоматическое монтирование

Добавить в `/etc/fstab`:

```
cdn@192.168.1.20:/var/www/cdn/upload/resize_cache /var/www/bitrix/upload/resize_cache fuse.sshfs defaults,allow_other,default_permissions,IdentityFile=/root/.ssh/cdn_mount,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 0 0
```

#### 6. Примонтировать

```bash
mount /var/www/bitrix/upload/resize_cache
```

#### 7. Создать systemd сервис

Создать файл `/etc/systemd/system/cdn-resize-mount.service`:

```ini
[Unit]
Description=Mount CDN resize_cache via SSHFS
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
ExecStartPre=/bin/mkdir -p /var/www/bitrix/upload/resize_cache
ExecStart=/usr/bin/sshfs cdn@192.168.1.20:/var/www/cdn/upload/resize_cache /var/www/bitrix/upload/resize_cache -o allow_other,default_permissions,IdentityFile=/root/.ssh/cdn_mount,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
ExecStop=/bin/fusermount -u /var/www/bitrix/upload/resize_cache
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Активировать сервис:

```bash
systemctl daemon-reload
systemctl enable cdn-resize-mount.service
systemctl start cdn-resize-mount.service
```

## Настройка прав доступа на CDN сервере

На CDN сервере (Server2) нужно настроить права для записи:

```bash
# Создать пользователя cdn если не существует
useradd -m -s /bin/bash cdn

# Создать директории
mkdir -p /var/www/cdn/upload/resize_cache
chown -R cdn:www-data /var/www/cdn/upload/resize_cache
chmod -R 775 /var/www/cdn/upload/resize_cache

# Настроить SSH доступ
mkdir -p /home/cdn/.ssh
touch /home/cdn/.ssh/authorized_keys
chmod 700 /home/cdn/.ssh
chmod 600 /home/cdn/.ssh/authorized_keys
chown -R cdn:cdn /home/cdn/.ssh

# Добавить публичный ключ с Битрикс сервера
echo "ssh-rsa AAAAB3... (ключ с Битрикс сервера)" >> /home/cdn/.ssh/authorized_keys
```

## Проверка работы

### На Битрикс сервере

```bash
# Проверить монтирование
df -h | grep resize_cache

# Проверить запись
touch /var/www/bitrix/upload/resize_cache/test.txt
ls -la /var/www/bitrix/upload/resize_cache/test.txt
rm /var/www/bitrix/upload/resize_cache/test.txt
```

### На CDN сервере

```bash
# Проверить что файлы появляются
ls -la /var/www/cdn/upload/resize_cache/

# Мониторинг новых файлов
watch -n 1 'ls -la /var/www/cdn/upload/resize_cache/ | head -20'
```

## Интеграция с Битрикс

В файле `/bitrix/php_interface/init.php`:

```php
// CDN для изображений
define("BX_IMG_SERVER", "https://cdn.termokit.ru");

// Заменять пути к изображениям
AddEventHandler("main", "OnEndBufferContent", "ReplaceCDNPaths");
function ReplaceCDNPaths(&$content) {
    $content = str_replace('/upload/', BX_IMG_SERVER . '/upload/', $content);
}
```

## Устранение проблем

### Mount не работает

```bash
# Проверить SSH подключение
ssh -i /root/.ssh/cdn_mount cdn@192.168.1.20 "echo OK"

# Проверить логи
journalctl -u cdn-resize-mount.service -n 50

# Перемонтировать
fusermount -u /var/www/bitrix/upload/resize_cache
mount /var/www/bitrix/upload/resize_cache
```

### Нет прав на запись

```bash
# На CDN сервере проверить права
ls -la /var/www/cdn/upload/resize_cache/
# Должно быть drwxrwxr-x cdn:www-data
```

### Битрикс не видит папку

```bash
# Проверить от пользователя битрикс
sudo -u www-data ls -la /var/www/bitrix/upload/resize_cache/
```

## Мониторинг

### Проверка места

```bash
# На CDN сервере
df -h /var/www/cdn/upload/resize_cache
du -sh /var/www/cdn/upload/resize_cache
```

### Статистика WebP конвертации

```bash
# На CDN сервере
find /var/www/cdn/upload/resize_cache -name "*.webp" | wc -l
```

### Логи монтирования

```bash
# На Битрикс сервере
tail -f /var/log/syslog | grep sshfs
```