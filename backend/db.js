const { PrismaClient } = require('@prisma/client');

const db = new PrismaClient();

function initDb() {
  return db.$connect();
}

const AVATAR_COLORS = [0xff2d6b32, 0xff3d8b48, 0xff4a9b54, 0xff1b521b, 0xff2a6b32];

function colorForNickname(nickname) {
  let hash = 0;
  for (let i = 0; i < nickname.length; i++) {
    hash = nickname.charCodeAt(i) + ((hash << 5) - hash);
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function userToJson(row) {
  if (!row) return null;
  return {
    id: row.id,
    nickname: row.nickname,
    phone: row.phone,
    avatarColor: row.avatarColor,
    online: false,
  };
}

async function getUserById(id) {
  const user = await db.user.findUnique({ where: { id } });
  return userToJson(user);
}

function normalizePhone(phone) {
  return phone.replace(/[\s\-()+]/g, '');
}

module.exports = { db, initDb, userToJson, getUserById, colorForNickname, normalizePhone };
