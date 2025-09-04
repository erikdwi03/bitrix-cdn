# 🚀 Bitrix CDN Server

**Высокопроизводительный CDN сервер для автоматической оптимизации изображений Битрикс сайтов**

[![Version](https://img.shields.io/badge/Version-2.0-blue.svg)](https://github.com/AAChibilyaev/bitrix-cdn)
[![Docker Ready](https://img.shields.io/badge/Docker-Ready-brightgreen.svg)](./docs/DOCKER_ARCHITECTURE.md)
[![WebP](https://img.shields.io/badge/WebP-Optimized-orange.svg)](./docs/DATA_PROCESSING_FLOWS.md)
[![Monitoring](https://img.shields.io/badge/Monitoring-Grafana-red.svg)](./docs/MONITORING_METRICS.md)

---

## ⚡ Быстрая навигация

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0;">
  
  <div style="border: 2px solid #4CAF50; border-radius: 10px; padding: 20px;">
    <h3>🚀 Быстрый старт</h3>
    <ul style="list-style: none; padding: 0;">
      <li>📖 <a href="#quick-start">Quick Start Guide</a></li>
      <li>🐳 <a href="./docs/DOCKER_ARCHITECTURE.md">Docker Setup</a></li>
      <li>⚙️ <a href="./docs/INSTALL.md">Installation Guide</a></li>
    </ul>
  </div>

  <div style="border: 2px solid #2196F3; border-radius: 10px; padding: 20px;">
    <h3>📚 Документация</h3>
    <ul style="list-style: none; padding: 0;">
      <li>🏗️ <a href="./docs/README.md">Полная документация</a></li>
      <li>🔄 <a href="./docs/NETWORK_FLOWS.md">Сетевые потоки</a></li>
      <li>💾 <a href="./docs/VOLUMES_FILESYSTEM.md">Файловая система</a></li>
    </ul>
  </div>

  <div style="border: 2px solid #FF9800; border-radius: 10px; padding: 20px;">
    <h3>📊 Мониторинг</h3>
    <ul style="list-style: none; padding: 0;">
      <li>📈 <a href="./docs/MONITORING_METRICS.md">Метрики и алерты</a></li>
      <li>⚡ <a href="./docs/PERFORMANCE_SCALING.md">Производительность</a></li>
      <li>🔒 <a href="./docs/SECURITY_OPTIMIZATION.md">Безопасность</a></li>
    </ul>
  </div>

  <div style="border: 2px solid #9C27B0; border-radius: 10px; padding: 20px;">
    <h3>🛠️ Управление</h3>
    <ul style="list-style: none; padding: 0;">
      <li>🔧 <a href="./docs/OPERATIONAL_MANAGEMENT.md">Операции</a></li>
      <li>🚀 <a href="./docs/CI_CD_PIPELINE.md">CI/CD Pipeline</a></li>
      <li>❓ <a href="./docs/TROUBLESHOOTING.md">Troubleshooting</a></li>
    </ul>
  </div>

</div>

---

## 🎯 О проекте

**Bitrix CDN Server** - это готовое решение для развертывания CDN с автоматической конвертацией изображений в WebP формат для Битрикс сайтов.

### ✨ Ключевые возможности

- **🎯 Экономия 40-55%** размера изображений благодаря WebP
- **⚡ Ускорение загрузки** страниц в 2-3 раза
- **🔄 Автоматическая конвертация** JPG/PNG → WebP на лету
- **📊 Полный мониторинг** через Prometheus + Grafana
- **🛡️ Отказоустойчивость** с автовосстановлением
- **🐳 Docker-ready** решение из коробки

### 🏗️ Архитектура

Решение состоит из **11 Docker контейнеров**, обеспечивающих:

- NGINX для обработки запросов
- Python конвертер WebP
- SSHFS для доступа к файлам Битрикс
- Redis для кеширования метаданных
- Varnish для edge кеширования
- Полный стек мониторинга

[Подробная архитектура →](./docs/DOCKER_ARCHITECTURE.md)

---

## 🚀 Quick Start {#quick-start}

### Требования

- Docker 20.10+
- Docker Compose 1.29+
- SSH доступ к Битрикс серверу
- 4GB RAM, 2 CPU минимум

### Установка за 5 минут

```bash
# 1. Клонирование репозитория
git clone https://github.com/AAChibilyaev/bitrix-cdn.git
cd bitrix-cdn

# 2. Настройка окружения
cp .env.example .env
nano .env  # Укажите IP и данные вашего Битрикс сервера

# 3. Автоматическая настройка
./docker-manage.sh setup

# 4. Запуск системы
docker-compose up -d

# 5. Проверка статуса
./docker-manage.sh status
```

### Настройка Битрикс

Добавьте публичный ключ на Битрикс сервер:

```bash
cat docker/ssh/bitrix_mount.pub
# Скопируйте ключ в ~/.ssh/authorized_keys на Битрикс сервере
```

[Полная инструкция установки →](./docs/INSTALL.md)

---

## 📊 Мониторинг и метрики

После запуска доступны следующие интерфейсы:

| Сервис | URL | Описание |
|--------|-----|----------|
| **Grafana** | http://localhost:3000 | Дашборды и метрики |
| **Prometheus** | http://localhost:9090 | Сбор метрик |
| **CDN** | http://localhost:80 | CDN endpoint |

### Основные метрики

- 📈 **Cache Hit Rate**: >90% после прогрева
- ⚡ **Время конвертации**: ~200ms на изображение
- 💾 **Экономия размера**: 40-55% с качеством 85
- 🚀 **Пропускная способность**: 10000+ изображений/день

[Подробнее о мониторинге →](./docs/MONITORING_METRICS.md)

---

## 🛠️ Управление

### Основные команды

```bash
# Статус системы
./docker-manage.sh status

# Просмотр логов
./docker-manage.sh logs -f

# Очистка кеша
./docker-manage.sh clean

# Статистика кеша
./docker-manage.sh stats

# Резервное копирование
./docker-manage.sh backup
```

[Все команды управления →](./docs/OPERATIONAL_MANAGEMENT.md)

---

## 📚 Полезные ссылки

### Документация
- [📖 Полная документация](./docs/README.md)
- [🏗️ Docker архитектура](./docs/DOCKER_ARCHITECTURE.md)
- [🔄 Потоки данных](./docs/DATA_PROCESSING_FLOWS.md)
- [📊 Мониторинг](./docs/MONITORING_METRICS.md)

### Разработка
- [🚀 CI/CD Pipeline](./docs/CI_CD_PIPELINE.md)
- [🛠️ Варианты деплоя](./docs/DEPLOYMENT_VARIANTS.md)
- [🔧 Troubleshooting](./docs/TROUBLESHOOTING.md)

### GitHub
- [Repository](https://github.com/AAChibilyaev/bitrix-cdn)
- [Issues](https://github.com/AAChibilyaev/bitrix-cdn/issues)
- [Releases](https://github.com/AAChibilyaev/bitrix-cdn/releases)

---

## 👨‍💻 Автор

**Alexandr Chibilyaev**  
AAChibilyaev LTD  
📧 info@aachibilyaev.com  
🌐 [aachibilyaev.com](https://aachibilyaev.com)

---

## 📄 Лицензия

MIT License - см. [LICENSE](./LICENSE)

---

<div style="text-align: center; margin-top: 50px; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; color: white;">
  <h2>🚀 Готовы начать?</h2>
  <p>Разверните высокопроизводительный CDN за 5 минут!</p>
  <a href="https://github.com/AAChibilyaev/bitrix-cdn" style="display: inline-block; padding: 12px 30px; background: white; color: #764ba2; border-radius: 5px; text-decoration: none; font-weight: bold; margin: 10px;">
    GitHub Repository →
  </a>
</div>