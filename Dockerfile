FROM node:20-alpine

RUN apk add --no-cache openssl

WORKDIR /app/backend

COPY backend/package*.json ./
COPY backend/prisma/ ./prisma/

RUN npm install
RUN npx prisma generate

COPY backend/ .

EXPOSE 3000

CMD node server.js
