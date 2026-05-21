const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const AVATAR_COLORS = [0xff2d6b32, 0xff3d8b48, 0xff4a9b54, 0xff1b521b, 0xff2a6b32];

function colorForNickname(nickname) {
  let hash = 0;
  for (let i = 0; i < nickname.length; i++) {
    hash = nickname.charCodeAt(i) + ((hash << 5) - hash);
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

async function main() {
  const demos = [
    { nickname: 'anna', phone: '+79001111111', password: 'anna123' },
    { nickname: 'maxim', phone: '+79002222222', password: 'maxim123' },
    { nickname: 'elena', phone: '+79003333333', password: 'elena123' },
    { nickname: 'plant_team', phone: '+79004444444', password: 'plant123' },
  ];

  for (const d of demos) {
    await prisma.user.upsert({
      where: { nickname: d.nickname },
      create: {
        nickname: d.nickname,
        phone: d.phone,
        passwordHash: bcrypt.hashSync(d.password, 10),
        avatarColor: colorForNickname(d.nickname),
      },
      update: {},
    });
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
