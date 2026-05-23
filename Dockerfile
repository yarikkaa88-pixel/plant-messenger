FROM node:20-alpine

RUN apk add --no-cache openssl

WORKDIR /app/backend

COPY backend/package*.json ./
COPY backend/prisma/ ./prisma/

RUN npm install
ENV DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy"
RUN npx prisma generate
ENV DATABASE_URL=""

COPY backend/ .

EXPOSE 3000

CMD node server.js
