FROM node:20-alpine

WORKDIR /app

COPY backend/package*.json backend/
COPY backend/prisma/ backend/prisma/

WORKDIR /app/backend
RUN npm install
RUN npx prisma generate

COPY backend/ .

RUN npx prisma migrate deploy
RUN node prisma/seed.js

EXPOSE 3000

CMD npx prisma migrate deploy && npx prisma generate && node server.js