const prisma = require('../lib/prisma');
const { findActiveSession } = require('../lib/sessions');

// lastUsedAt is refreshed at most this often, so a busy client does not cause a
// database write on every single request.
const LAST_USED_REFRESH_MS = 5 * 60 * 1000; // 5 minutes

const bearerTokenFrom = (req) => {
  const header = req.get('Authorization');
  if (!header || !header.startsWith('Bearer ')) return null;
  const token = header.slice('Bearer '.length).trim();
  return token.length > 0 ? token : null;
};

const unauthorized = (res, message, code) =>
  res.status(401).json({ error: message, code });

/**
 * Resolves the caller's session and attaches `req.user` / `req.session`.
 *
 * When `required` is false the request continues unauthenticated instead of
 * being rejected, which lets a route serve both signed-in and anonymous users.
 */
const authenticate = ({ required }) => async (req, res, next) => {
  try {
    const token = bearerTokenFrom(req);

    if (!token) {
      if (!required) return next();
      return unauthorized(res, 'Authentication required. Please log in.', 'NO_TOKEN');
    }

    // Reject the pre-session scheme, where the raw user id was sent as a
    // bearer token. Those clients must log in again to obtain a real session.
    if (/^\d+$/.test(token)) {
      if (!required) return next();
      return unauthorized(
        res,
        'Your app is using an outdated login. Please log in again.',
        'LEGACY_TOKEN'
      );
    }

    const session = await findActiveSession(token);

    if (!session) {
      if (!required) return next();
      return unauthorized(res, 'Session expired or invalid. Please log in again.', 'SESSION_INVALID');
    }

    const user = session.user;

    // A ban applied after login must take effect on the next request, not only
    // at the next login.
    if (user.status === 'DELETED') {
      return res.status(403).json({
        error: 'Your account has been permanently banned.',
        banned: true,
        banType: 'permanent',
      });
    }

    if (
      user.status === 'SUSPENDED' &&
      user.suspendedUntil &&
      new Date(user.suspendedUntil) > new Date()
    ) {
      return res.status(403).json({
        error: `Your account is temporarily banned until ${new Date(
          user.suspendedUntil
        ).toLocaleString()}.`,
        banned: true,
        banType: 'temporary',
        suspendedUntil: user.suspendedUntil,
      });
    }

    if (Date.now() - new Date(session.lastUsedAt).getTime() > LAST_USED_REFRESH_MS) {
      prisma.session
        .update({ where: { id: session.id }, data: { lastUsedAt: new Date() } })
        .catch((error) => console.error('Failed to refresh session lastUsedAt:', error));
    }

    req.session = session;
    req.user = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    };

    next();
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

const requireAuth = authenticate({ required: true });
const optionalAuth = authenticate({ required: false });

/** Restricts a route to the given roles. Must run after requireAuth. */
const requireRole = (...roles) => (req, res, next) => {
  if (!req.user) {
    return unauthorized(res, 'Authentication required. Please log in.', 'NO_TOKEN');
  }
  if (!roles.includes(req.user.role)) {
    return res.status(403).json({ error: 'You do not have access to this resource.' });
  }
  next();
};

module.exports = { requireAuth, optionalAuth, requireRole };
