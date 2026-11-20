# OUTPOST — ARC Raiders fan hub

Неофициальный фан-хаб ARC Raiders. Текущая сборка сайта: v0.8.

## Сайт

Опубликован через GitHub Pages: https://pyotr870.github.io/outpost-fanhub1/

## Публикация

Сайт собирается из `outpost_v08_deploy.zip`, проходит подготовительные исправления и публикуется GitHub Actions workflow **Deploy OUTPOST to GitHub Pages**.

Последняя публикация прошла успешно: build и deploy завершились со статусом success. История запусков: https://github.com/Pyotr870/outpost-fanhub1/actions

Корневой `index.html` намеренно сохранён как резервная версия; опубликованная версия берётся из архива v0.8.

## Проверки и исправления

- Архив v0.8 прошёл проверку структуры, локальных ссылок, повторяющихся HTML ID и синтаксиса JavaScript.
- Исправления Service Worker и Supabase auth callback применяются во время сборки.
- Service Worker удаляет только кэши приложения OUTPOST, а не все кэши на том же origin.

## Интеграции

Supabase пока не подключён: облачная галерея, email-вход и OAuth не активны до настройки проекта и провайдеров.

**Безопасность:** в публичном репозитории допустим только Supabase publishable/anon key. Не добавляй сюда service_role/secret key, пароль базы данных или OAuth client secret.
