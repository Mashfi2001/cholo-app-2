const crypto = require('crypto');
const prisma = require('./prisma');

// How long a session stays valid before the user has to log in again.
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

/**
 * Only the hash of a token is stored, so a leaked database dump cannot be
 * replayed as a login. The raw token is returned to the client exactly once.
 */
const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const generateToken = () => crypto.randomBytes(32).toString('base64url');

/**
 * Best-effort label for the device that logged in, shown in the active-devices
 * list. Never trusted for anything security related.
 */
const deviceNameFrom = (req) => {
  const explicit = req.get('X-Device-Name');
  if (explicit) return explicit.slice(0, 100);
  const agent = req.get('User-Agent');
  return agent ? agent.slice(0, 100) : null;
};

/**
 * Issues a new session for a user. Existing sessions are deliberately left
 * alone so the same account can stay signed in on several devices at once.
 */
const createSession = async (userId, req) => {
  const token = generateToken();
  const expiresAt = new Date(Date.now() + SESSION_TTL_MS);

  const session = await prisma.session.create({
    data: {
      tokenHash: hashToken(token),
      userId,
      deviceName: req ? deviceNameFrom(req) : null,
      expiresAt,
    },
  });

  return { token, session };
};

/**
 * Resolves a raw token to its live session, or null when the token is unknown,
 * revoked, or past its expiry.
 */
const findActiveSession = async (token) => {
  if (!token) return null;

  const session = await prisma.session.findUnique({
    where: { tokenHash: hashToken(token) },
    include: { user: true },
  });

  if (!session) return null;
  if (session.revokedAt) return null;
  if (new Date() > new Date(session.expiresAt)) return null;

  return session;
};

const revokeSession = async (sessionId) => {
  await prisma.session.updateMany({
    where: { id: sessionId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
};

/**
 * Revokes every session for a user. `exceptSessionId` lets the caller keep the
 * device that triggered the action signed in.
 */
const revokeAllSessions = async (userId, exceptSessionId = null) => {
  const where = { userId, revokedAt: null };
  if (exceptSessionId) where.id = { not: exceptSessionId };

  const result = await prisma.session.updateMany({
    where,
    data: { revokedAt: new Date() },
  });

  return result.count;
};

const listActiveSessions = async (userId) =>
  prisma.session.findMany({
    where: {
      userId,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
    orderBy: { lastUsedAt: 'desc' },
    select: {
      id: true,
      deviceName: true,
      createdAt: true,
      lastUsedAt: true,
      expiresAt: true,
    },
  });

/** Drops rows that can never authenticate again, so the table does not grow forever. */
const purgeDeadSessions = async () => {
  try {
    await prisma.session.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() } },
          { revokedAt: { lt: new Date(Date.now() - SESSION_TTL_MS) } },
        ],
      },
    });
  } catch (error) {
    // Housekeeping only — never let this break a login.
    console.error('Session purge failed:', error);
  }
};

module.exports = {
  SESSION_TTL_MS,
  createSession,
  findActiveSession,
  revokeSession,
  revokeAllSessions,
  listActiveSessions,
  purgeDeadSessions,
};
