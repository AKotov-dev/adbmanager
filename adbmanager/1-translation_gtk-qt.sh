#!/bin/bash

# Скрипт дублирует языковые файлы adbmanager → adbmanager-qt
# и компилирует все .po → .mo через msgfmt

LANG_DIR="./languages"  # папка с файлами переводов

# Проверяем наличие утилиты msgfmt
if ! command -v msgfmt >/dev/null 2>&1; then
  echo "❌ Ошибка: утилита 'msgfmt' не найдена!"
  echo "Установите пакет gettext, например:"
  echo "  sudo apt install gettext"
  exit 1
fi

# Проверяем, что папка существует
[ -d "$LANG_DIR" ] || { echo "❌ Папка $LANG_DIR не найдена!"; exit 1; }

echo "🧹 Очистка старых adbmanager-qt файлов..."
rm -f "$LANG_DIR"/adbmanager-qt*

# Проходим по всем файлам, начинающимся с adbmanager
for file in "$LANG_DIR"/adbmanager*.*; do
  # Пропускаем уже существующие с -qt
  if [[ "$file" != *"-qt"* ]]; then
    dir=$(dirname "$file")
    base=$(basename "$file")       # например adbmanager.cs.po
    ext="${base#adbmanager}"       # .cs.po или .pot
    new_file="$dir/adbmanager-qt$ext"

    # Копируем файл
    cp "$file" "$new_file"
    echo "📄 Создан $new_file"

    # Если это .po — компилируем в .mo
    if [[ "$file" == *.po ]]; then
      mo_file="${file%.po}.mo"
      mo_qt_file="${new_file%.po}.mo"

      msgfmt "$file" -o "$mo_file" && echo "✅ Скомпилирован $mo_file" || echo "⚠️ Ошибка при компиляции $file"
      msgfmt "$new_file" -o "$mo_qt_file" && echo "✅ Скомпилирован $mo_qt_file" || echo "⚠️ Ошибка при компиляции $new_file"
    fi
  fi
done

echo "✨ Готово! Все файлы adbmanager дублированы с -qt и .po → .mo скомпилированы."
