# PLANT Backend API

Сервер для мессенджера PLANT. Production-режим: PostgreSQL + Prisma + Socket.IO.

## Быстрый старт (локально)

1. Скопируйте `.env.example` в `.env` и заполните `DATABASE_URL`, `JWT_SECRET`.
2. Запустите:

```bash
cd backend
npm install
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
npm start
```

Сервер: `http://localhost:3000`

Проверки:
- `GET /api/health`
- `GET /api/ready`

## Демо-пользователи

| Ник       | Пароль    | Телефон       |
|-----------|-----------|---------------|
| anna      | anna123   | +79001111111  |
| maxim     | maxim123  | +79002222222  |
| elena     | elena123  | +79003333333  |
| plant_team| plant123  | +79004444444  |

## API

| Метод | Путь | Описание |
|-------|------|----------|
| POST | /api/auth/register | Регистрация |
| POST | /api/auth/login | Вход |
| GET | /api/auth/me | Текущий пользователь |
| GET | /api/users/search?q= | Поиск людей |
| GET | /api/chats | Список чатов |
| POST | /api/chats | Создать чат |
| GET | /api/chats/:id | Чат с сообщениями |
| POST | /api/chats/:id/messages | Отправить сообщение |
| GET | /api/channels | Каналы |
| POST | /api/channels | Создать канал |
| POST | /api/channels/:id/subscribe | Подписаться |
| POST | /api/channels/:id/posts | Пост в канал |
| POST | /api/channels/:id/posts/:postId/reactions | Реакция |
| POST | /api/channels/:id/posts/:postId/comments | Комментарий |

Авторизация: заголовок `Authorization: Bearer <token>`

## Realtime

Socket.IO поднимается на том же хосте.  
Клиент передаёт JWT в `auth.token` и использует события:

- `chat:join` (chatId)
- `chat:leave` (chatId)
- `message:new` (новое сообщение)

## Подключение телефона

Клиент Flutter автоматически ищет backend:

- `http://10.0.2.2:3000` (Android эмулятор)
- `http://localhost:3000`
- `http://127.0.0.1:3000`
- затем сканирует локальную сеть (для реального телефона)

Важно: телефон и ПК должны быть в одной Wi‑Fi сети, а firewall должен разрешать порт `3000`.

## Файлы и хранилище

- По умолчанию (если нет Supabase env): локально в `backend/uploads/`
- При наличии `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`: загрузка в Supabase Storage bucket

## Деплой

- Готов конфиг `render.yaml` в корне репозитория.
- Для deploy нужны env:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `PUBLIC_BASE_URL`
  - `CORS_ORIGIN`
  - опционально: `SENTRY_DSN`, `SUPABASE_*`
