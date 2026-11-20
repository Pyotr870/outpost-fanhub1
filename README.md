# OUTPOST — ARC Raiders fan hub

Неофициальный фан-хаб ARC Raiders. Текущая сборка сайта: v0.8.

## Публикация на GitHub Pages

1. Открой **Settings → Pages** в этом репозитории.
2. В разделе **Build and deployment** выбери **Source: GitHub Actions**.
3. После этого открой **Actions** и повторно запусти workflow **Deploy OUTPOST to GitHub Pages** (или сообщи мне — проверю запуск).

Workflow собирает сайт из `outpost_v08_deploy.zip`, применяет подготовительные исправления и публикует результат. Корневой `index.html` намеренно сохранён как резервная версия.

## Текущий статус

- Архив v0.8 прошёл проверку структуры, локальных ссылок, повторяющихся HTML ID и синтаксиса JavaScript.
- Исправления Service Worker и Supabase auth callback применяются во время сборки.
- GitHub Pages workflow добавлен, но публикация ожидает однократного включения Pages через Settings.
- Supabase пока не подключён: облачная галерея, email-вход и OAuth не активны до настройки проекта и провайдеров.

**Безопасность:** в публичном репозитории допустим только Supabase publishable/anon key. Не добавляй сюда service_role/secret key, пароль базы данных или OAuth client secret.
