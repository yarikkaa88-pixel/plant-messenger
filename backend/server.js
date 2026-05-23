require('dotenv').config();

const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const http = require('http');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
const { createClient } = require('@supabase/supabase-js');
const ws = require('ws');
const Sentry = require('@sentry/node');
const { v4: uuidv4 } = require('uuid');
const {
  db,
  initDb,
  userToJson,
  getUserById,
  colorForNickname,
  normalizePhone,
} = require('./db');

const app = express();
const server = http.createServer(app);

const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET || 'plant-secret-change-in-production';
const PUBLIC_BASE_URL = process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`;
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
const SENTRY_DSN = process.env.SENTRY_DSN || '';
const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const SUPABASE_BUCKET = process.env.SUPABASE_BUCKET || 'plant-media';

if (SENTRY_DSN) {
  Sentry.init({ dsn: SENTRY_DSN });
}

const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
app.use('/uploads', express.static(uploadsDir));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
});

const io = new Server(server, {
  cors: { origin: CORS_ORIGIN === '*' ? true : CORS_ORIGIN.split(',') },
});

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      realtime: { transport: ws },
    })
  : null;

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Требуется авторизация' });
  }
  try {
    req.user = jwt.verify(header.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Недействительный токен' });
  }
}

async function seedDemoUsers() {
  const demos = [
    { nickname: 'anna', phone: '+79001111111', password: 'anna123' },
    { nickname: 'maxim', phone: '+79002222222', password: 'maxim123' },
    { nickname: 'elena', phone: '+79003333333', password: 'elena123' },
    { nickname: 'plant_team', phone: '+79004444444', password: 'plant123' },
  ];
  for (const demo of demos) {
    await db.user.upsert({
      where: { nickname: demo.nickname },
      create: {
        nickname: demo.nickname,
        phone: demo.phone,
        passwordHash: bcrypt.hashSync(demo.password, 10),
        avatarColor: colorForNickname(demo.nickname),
      },
      update: {},
    });
  }
}

async function saveMedia(file) {
  const ext = path.extname(file.originalname || '');
  const filename = `${uuidv4()}${ext}`;
  if (supabase) {
    const { error } = await supabase.storage.from(SUPABASE_BUCKET).upload(filename, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });
    if (error) throw error;
    const { data } = supabase.storage.from(SUPABASE_BUCKET).getPublicUrl(filename);
    return { content: data.publicUrl, fileName: file.originalname };
  }
  const target = path.join(uploadsDir, filename);
  await fs.promises.writeFile(target, file.buffer);
  return { content: `${PUBLIC_BASE_URL}/uploads/${filename}`, fileName: file.originalname };
}

function messageToJson(row, currentUserId) {
  return {
    id: row.id,
    chatId: row.chatId,
    senderId: row.senderId,
    type: row.type,
    content: row.content,
    fileName: row.fileName,
    sentAt: row.sentAt,
    isMine: row.senderId === currentUserId,
  };
}

function postToJson(post, reactionsByEmoji, comments) {
  return {
    id: post.id,
    channelId: post.channelId,
    type: post.type,
    content: post.content,
    fileName: post.fileName,
    sentAt: post.sentAt,
    reactions: reactionsByEmoji,
    comments,
  };
}

async function getReactions(postId) {
  const rows = await db.postReaction.findMany({ where: { postId } });
  const reactions = {};
  for (const row of rows) {
    if (!reactions[row.emoji]) reactions[row.emoji] = [];
    reactions[row.emoji].push(row.userId);
  }
  return reactions;
}

const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
});

const messageLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
});

app.use(cors({ origin: CORS_ORIGIN === '*' ? true : CORS_ORIGIN.split(','), credentials: true }));
app.use(express.json({ limit: '2mb' }));
app.use('/api/auth', authLimiter);
app.use('/api/chats/:id/messages', messageLimiter);
app.use('/api/channels/:id/posts', messageLimiter);

io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('unauthorized'));
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    socket.user = payload;
    return next();
  } catch {
    return next(new Error('unauthorized'));
  }
});

io.on('connection', (socket) => {
  socket.on('chat:join', (chatId) => {
    socket.join(`chat:${chatId}`);
  });
  socket.on('chat:leave', (chatId) => {
    socket.leave(`chat:${chatId}`);
  });
});

app.post('/api/auth/register', async (req, res) => {
  const { nickname, password, phone } = req.body;
  if (!nickname?.trim() || !password || !phone?.trim()) {
    return res.status(400).json({ error: 'Заполните все поля' });
  }
  const nick = nickname.trim();
  const ph = phone.trim();
  if (await db.user.findUnique({ where: { nickname: nick } })) {
    return res.status(409).json({ error: 'nickname_taken' });
  }
  if (await db.user.findUnique({ where: { phone: ph } })) {
    return res.status(409).json({ error: 'phone_taken' });
  }
  const user = await db.user.create({
    data: {
      nickname: nick,
      passwordHash: bcrypt.hashSync(password, 10),
      phone: ph,
      avatarColor: colorForNickname(nick),
    },
  });
  const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });
  res.json({ token, user: userToJson(user) });
});

app.post('/api/auth/login', async (req, res) => {
  const { nickname, password } = req.body;
  if (!nickname?.trim() || !password) return res.status(400).json({ error: 'empty_fields' });
  const row = await db.user.findUnique({ where: { nickname: nickname.trim() } });
  if (!row) return res.status(401).json({ error: 'user_not_found' });
  if (!bcrypt.compareSync(password, row.passwordHash)) return res.status(401).json({ error: 'wrong_password' });
  const token = jwt.sign({ userId: row.id }, JWT_SECRET, { expiresIn: '30d' });
  res.json({ token, user: userToJson(row) });
});

app.get('/api/auth/me', authMiddleware, async (req, res) => {
  res.json(await getUserById(req.user.userId));
});

app.get('/api/users/search', authMiddleware, async (req, res) => {
  const q = (req.query.q || '').trim().toLowerCase();
  if (!q) return res.json([]);
  const users = await db.user.findMany({ where: { id: { not: req.user.userId } } });
  const phoneQ = normalizePhone(q);
  const results = users
    .filter((u) => u.nickname.toLowerCase().includes(q) || normalizePhone(u.phone).includes(phoneQ))
    .map(userToJson);
  res.json(results);
});

app.get('/api/users/:id', authMiddleware, async (req, res) => {
  const user = await getUserById(req.params.id);
  if (!user) return res.status(404).json({ error: 'not_found' });
  res.json(user);
});

app.get('/api/chats', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const memberships = await db.chatParticipant.findMany({
    where: { userId },
    include: {
      chat: {
        include: {
          participants: { include: { user: true } },
          messages: { orderBy: { sentAt: 'asc' } },
        },
      },
    },
  });
  const chats = memberships.map((m) => {
    const participants = m.chat.participants.map((p) => p.userId);
    const other = m.chat.participants.find((p) => p.userId !== userId)?.user ?? null;
    const messages = m.chat.messages.map((msg) => messageToJson(msg, userId));
    return {
      id: m.chat.id,
      participantIds: participants,
      otherUser: other ? userToJson(other) : null,
      messages,
      lastMessage: messages.length ? messages[messages.length - 1] : null,
    };
  });
  chats.sort((a, b) => new Date(b.lastMessage?.sentAt || 0) - new Date(a.lastMessage?.sentAt || 0));
  res.json(chats);
});

app.post('/api/chats', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const { otherUserId } = req.body;
  if (!otherUserId || otherUserId === userId) return res.status(400).json({ error: 'invalid_user' });
  if (!(await db.user.findUnique({ where: { id: otherUserId } }))) return res.status(404).json({ error: 'user_not_found' });

  const existing = await db.chat.findFirst({
    where: {
      AND: [
        { participants: { some: { userId } } },
        { participants: { some: { userId: otherUserId } } },
      ],
    },
  });
  if (existing) return res.json({ id: existing.id, participantIds: [userId, otherUserId] });

  const chat = await db.chat.create({
    data: {
      participants: {
        create: [{ userId }, { userId: otherUserId }],
      },
    },
  });
  res.status(201).json({ id: chat.id, participantIds: [userId, otherUserId] });
});

app.get('/api/chats/:id', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const chat = await db.chat.findUnique({
    where: { id: req.params.id },
    include: { participants: true, messages: { orderBy: { sentAt: 'asc' } } },
  });
  if (!chat) return res.status(404).json({ error: 'not_found' });
  if (!chat.participants.some((p) => p.userId === userId)) return res.status(403).json({ error: 'forbidden' });
  res.json({
    id: chat.id,
    participantIds: chat.participants.map((p) => p.userId),
    messages: chat.messages.map((m) => messageToJson(m, userId)),
  });
});

app.post('/api/chats/:id/messages', authMiddleware, upload.single('file'), async (req, res) => {
  const userId = req.user.userId;
  const chatId = req.params.id;
  const member = await db.chatParticipant.findUnique({ where: { chatId_userId: { chatId, userId } } });
  if (!member) return res.status(403).json({ error: 'forbidden' });

  let payload = { content: req.body.content || '', fileName: req.body.fileName || null };
  if (req.file) payload = await saveMedia(req.file);
  if (!payload.content) return res.status(400).json({ error: 'empty_content' });

  const row = await db.message.create({
    data: {
      chatId,
      senderId: userId,
      type: req.body.type || 'text',
      content: payload.content,
      fileName: payload.fileName,
    },
  });
  const json = messageToJson(row, userId);
  io.to(`chat:${chatId}`).emit('message:new', json);
  res.status(201).json(json);
});

app.get('/api/channels', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const channels = await db.channel.findMany({
    where: {
      OR: [{ ownerId: userId }, { subscribers: { some: { userId } } }],
    },
    orderBy: { createdAt: 'desc' },
    include: {
      subscribers: true,
      posts: { orderBy: { sentAt: 'asc' } },
    },
  });
  const result = [];
  for (const ch of channels) {
    const posts = [];
    for (const post of ch.posts) {
      const comments = await db.postComment.findMany({
        where: { postId: post.id },
        orderBy: { sentAt: 'asc' },
        include: { user: true },
      });
      posts.push(postToJson(post, await getReactions(post.id), comments.map((c) => ({
        id: c.id,
        userId: c.userId,
        userName: c.user.nickname,
        text: c.text,
        sentAt: c.sentAt,
      }))));
    }
    result.push({
      id: ch.id,
      name: ch.name,
      description: ch.description,
      ownerId: ch.ownerId,
      subscriberIds: ch.subscribers.map((s) => s.userId),
      posts,
    });
  }
  res.json(result);
});

app.post('/api/channels', authMiddleware, async (req, res) => {
  const { name, description } = req.body;
  const userId = req.user.userId;
  if (!name?.trim()) return res.status(400).json({ error: 'empty_name' });
  const channel = await db.channel.create({
    data: {
      name: name.trim(),
      description: (description || '').trim(),
      ownerId: userId,
      subscribers: { create: { userId } },
    },
  });
  res.status(201).json({
    id: channel.id,
    name: channel.name,
    description: channel.description,
    ownerId: userId,
    subscriberIds: [userId],
    posts: [],
  });
});

app.get('/api/channels/:id', authMiddleware, async (req, res) => {
  const channel = await db.channel.findUnique({
    where: { id: req.params.id },
    include: { subscribers: true, posts: { orderBy: { sentAt: 'asc' } } },
  });
  if (!channel) return res.status(404).json({ error: 'not_found' });
  const posts = [];
  for (const post of channel.posts) {
    const comments = await db.postComment.findMany({
      where: { postId: post.id },
      orderBy: { sentAt: 'asc' },
      include: { user: true },
    });
    posts.push(postToJson(post, await getReactions(post.id), comments.map((c) => ({
      id: c.id,
      userId: c.userId,
      userName: c.user.nickname,
      text: c.text,
      sentAt: c.sentAt,
    }))));
  }
  res.json({
    id: channel.id,
    name: channel.name,
    description: channel.description,
    ownerId: channel.ownerId,
    subscriberIds: channel.subscribers.map((s) => s.userId),
    posts,
  });
});

app.post('/api/channels/:id/subscribe', authMiddleware, async (req, res) => {
  const channelId = req.params.id;
  const userId = req.user.userId;
  if (!(await db.channel.findUnique({ where: { id: channelId } }))) return res.status(404).json({ error: 'not_found' });
  await db.channelSubscriber.upsert({
    where: { channelId_userId: { channelId, userId } },
    create: { channelId, userId },
    update: {},
  });
  res.json({ ok: true });
});

app.post('/api/channels/:id/posts', authMiddleware, upload.single('file'), async (req, res) => {
  const channelId = req.params.id;
  const userId = req.user.userId;
  const ch = await db.channel.findUnique({ where: { id: channelId } });
  if (!ch) return res.status(404).json({ error: 'not_found' });
  if (ch.ownerId !== userId) return res.status(403).json({ error: 'forbidden' });

  let payload = { content: req.body.content || '', fileName: req.body.fileName || null };
  if (req.file) payload = await saveMedia(req.file);
  if (!payload.content) return res.status(400).json({ error: 'empty_content' });

  const post = await db.channelPost.create({
    data: {
      channelId,
      type: req.body.type || 'text',
      content: payload.content,
      fileName: payload.fileName,
    },
  });
  res.status(201).json(postToJson(post, {}, []));
});

app.post('/api/channels/:channelId/posts/:postId/reactions', authMiddleware, async (req, res) => {
  const { channelId, postId } = req.params;
  const { emoji } = req.body;
  const userId = req.user.userId;
  if (!emoji) return res.status(400).json({ error: 'empty_emoji' });
  const post = await db.channelPost.findFirst({ where: { id: postId, channelId } });
  if (!post) return res.status(404).json({ error: 'not_found' });
  const existing = await db.postReaction.findUnique({ where: { postId_userId_emoji: { postId, userId, emoji } } });
  if (existing) {
    await db.postReaction.delete({ where: { postId_userId_emoji: { postId, userId, emoji } } });
  } else {
    await db.postReaction.create({ data: { postId, userId, emoji } });
  }
  res.json({ reactions: await getReactions(postId) });
});

app.post('/api/channels/:channelId/posts/:postId/comments', authMiddleware, async (req, res) => {
  const { channelId, postId } = req.params;
  const { text } = req.body;
  const userId = req.user.userId;
  if (!text?.trim()) return res.status(400).json({ error: 'empty_text' });
  const subscribed = await db.channelSubscriber.findUnique({ where: { channelId_userId: { channelId, userId } } });
  if (!subscribed) return res.status(403).json({ error: 'not_subscribed' });
  const post = await db.channelPost.findFirst({ where: { id: postId, channelId } });
  if (!post) return res.status(404).json({ error: 'not_found' });
  const comment = await db.postComment.create({ data: { postId, userId, text: text.trim() } });
  const user = await getUserById(userId);
  res.status(201).json({
    id: comment.id,
    userId,
    userName: user.nickname,
    text: comment.text,
    sentAt: comment.sentAt,
  });
});

app.get('/api/health', (_, res) => {
  res.json({ status: 'ok', app: 'PLANT', uptime: process.uptime() });
});

app.get('/api/ready', async (_, res) => {
  try {
    await db.$queryRaw`SELECT 1`;
    res.json({ status: 'ready' });
  } catch {
    res.status(503).json({ status: 'not_ready' });
  }
});

app.use((err, _req, res, _next) => {
  if (SENTRY_DSN) Sentry.captureException(err);
  console.error(err);
  res.status(500).json({ error: 'internal_error' });
});

const { execSync } = require('child_process');

async function start() {
  console.log('Running migrations...');
  try {
    execSync(`npx prisma migrate deploy`, { stdio: 'inherit' });
  } catch (err) {
    console.error('Migration warning:', err.message);
  }
  await initDb();
  await seedDemoUsers();
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`PLANT API: ${PUBLIC_BASE_URL}`);
    console.log(`Health: ${PUBLIC_BASE_URL}/api/health`);
  });
}

start().catch((err) => {
  console.error('Startup failed', err);
  process.exit(1);
});
