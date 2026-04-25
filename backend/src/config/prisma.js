/**
 * Prisma client singleton.
 * Reuses the same instance to avoid connection pool exhaustion.
 * In development, attaches to the global object to survive hot reloads.
 */

'use strict';

const { PrismaClient } = require('@prisma/client');

const globalForPrisma = globalThis;

const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}

module.exports = { prisma };
