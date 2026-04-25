/**
 * Role guard middleware factory.
 * Restricts a route to users with one of the allowed roles.
 * Must be used after the authenticate middleware so req.user is set.
 */

'use strict';

/**
 * Returns a middleware that allows only the specified role(s).
 *
 * @param {...string} allowedRoles - One or more roles: 'user' | 'therapist' | 'admin'
 * @returns {import('express').RequestHandler}
 */
function roleGuard(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Not authenticated.' },
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'Insufficient permissions.' },
      });
    }

    next();
  };
}

module.exports = { roleGuard };
