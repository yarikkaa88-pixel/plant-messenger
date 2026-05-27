const { PrismaClient } = require('@prisma/client');

const db = new PrismaClient();

function initDb() {
  return db.$connect();
}

const AVATAR_COLORS = [0x2d6b32, 0x3d8b48, 0x4a9b54, 0x1b521b, 0x2a6b32];

function colorForNickname(nickname) {
  let hash = 0;
  for (let i = 0; i < nickname.length; i++) {
    hash = nickname.charCodeAt(i) + ((hash << 5) - hash);
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function userToJson(row) {
  if (!row) return null;
  const hidePhone = row.hidePhone || false;
  let phone = row.phone;
  if (hidePhone && phone.length >= 7) {
    phone = phone.slice(0, 4) + '***' + phone.slice(7);
  }
  return {
    id: row.id,
    nickname: row.nickname,
    phone: phone,
    avatarColor: row.avatarColor,
    online: false,
    avatarPath: row.avatarPath || null,
    hidePhone,
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
