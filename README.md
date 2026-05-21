# PLANT Messenger

Приложение Flutter + production-ready backend (Node.js + PostgreSQL + Prisma + Socket.IO).

## Быстрый старт (Windows)

1. Установите:
   - Flutter SDK
   - Node.js LTS
2. В корне проекта запустите:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_local.ps1
```

Скрипт автоматически:
- установит зависимости backend,
- применит миграции Prisma и сиды демо-пользователей,
- запустит backend на `http://localhost:3000`,
- выполнит `flutter pub get`,
- запустит Flutter-приложение.

Перед первым запуском:
- скопируйте `backend/.env.example` в `backend/.env`
- заполните `DATABASE_URL`, `JWT_SECRET`, `PUBLIC_BASE_URL`

## Ручной запуск

Backend:

```powershell
cd .\backend
npm.cmd install
npm.cmd run prisma:generate
npm.cmd run prisma:migrate
npm.cmd run prisma:seed
npm.cmd start
```

Flutter (во втором терминале, из корня):

```powershell
flutter pub get
flutter run
```

## Вход в приложение

Демо-пользователи создаются автоматически при старте backend:
- `anna / anna123`
- `maxim / maxim123`
- `elena / elena123`
- `plant_team / plant123`

## Сеть и API URL

Ручной IP обычно не нужен: клиент сам ищет backend
(`10.0.2.2`, `localhost`, `127.0.0.1`, затем локальная сеть).

Для production-сборки используйте:

```bash
flutter run --dart-define=API_URL=https://your-api-domain.onrender.com --dart-define=WS_URL=https://your-api-domain.onrender.com
```
