#!/bin/bash

# Скрипт для ручного деплоя на GitHub Pages
set -e

echo "🚀 Начинаем деплой на GitHub Pages..."

# Сохраняем текущую ветку
CURRENT_BRANCH=$(git branch --show-current)
echo "📋 Текущая ветка: $CURRENT_BRANCH"

# Собираем веб-приложение
echo "🔨 Собираем Flutter веб-приложение..."
flutter build web --release --base-href /payme/

# Создаем .nojekyll файл в build/web
echo "📋 Создаем .nojekyll файл..."
touch build/web/.nojekyll

# Создаем временную директорию для собранных файлов
TEMP_DIR=$(mktemp -d)
echo "📁 Временная директория: $TEMP_DIR"

# Копируем собранные файлы во временную директорию
echo "📋 Копируем собранные файлы..."
cp -r build/web/* "$TEMP_DIR/"

# Копируем .nojekyll файл (если он существует)
echo "📋 Копируем .nojekyll файл..."
if [ -f "web/.nojekyll" ]; then
    cp web/.nojekyll "$TEMP_DIR/"
    echo "✅ .nojekyll файл скопирован"
else
    echo "⚠️  .nojekyll файл не найден"
fi

# Переключаемся на ветку gh-pages
echo "🔄 Переключаемся на ветку gh-pages..."
git checkout gh-pages

# Очищаем ветку gh-pages
echo "🧹 Очищаем ветку gh-pages..."
git rm -rf . || true

# Копируем файлы из временной директории
echo "📋 Копируем файлы в gh-pages..."
cp -r "$TEMP_DIR"/* .

# Добавляем все файлы в git
echo "➕ Добавляем файлы в git..."
git add .

# Коммитим изменения
echo "💾 Коммитим изменения..."
git commit -m "Deploy to GitHub Pages - $(date)"

# Отправляем изменения
echo "📤 Отправляем изменения..."
git push origin gh-pages --force

# Возвращаемся на исходную ветку
echo "🔄 Возвращаемся на ветку $CURRENT_BRANCH..."
git checkout "$CURRENT_BRANCH"

# Удаляем временную директорию
echo "🧹 Удаляем временную директорию..."
rm -rf "$TEMP_DIR"

echo "✅ Деплой завершен успешно!"
echo "🌐 Приложение доступно по адресу: https://fominyhdenis.github.io/payme/" 