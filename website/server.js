/**
 * server.js — Railway static server for the Noor Companion website.
 * Zero dependencies (Node built-ins). Replaces Netlify:
 *   - serves the static site from this directory
 *   - clean URLs (/subscribe, /pricing) as the old _redirects did
 *   - replicates the netlify.toml security headers, including the
 *     Paystack-scoped CSP on the subscribe page (load-bearing for
 *     the inline checkout iframe)
 * Listens on process.env.PORT (injected by Railway).
 */

'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT) || 3000;
const ROOT = __dirname;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.txt': 'text/plain; charset=utf-8',
  '.woff2': 'font/woff2',
};

/** Clean URLs — mirrors the old _redirects file. */
const ROUTES = {
  '/': 'index.html',
  '/subscribe': 'subscribe.html',
  '/pricing': 'pricing.html',
};

/** Security headers from the old netlify.toml. */
const SECURITY_HEADERS = {
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
};

/** CSP for the payment page — allows the Paystack inline checkout iframe. */
const SUBSCRIBE_CSP =
  "default-src 'self'; script-src 'self' 'unsafe-inline' https://js.paystack.co; " +
  'frame-src https://checkout.paystack.co; ' +
  "connect-src 'self' https://api.noorcompanion.com https://api.paystack.co; " +
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
  "font-src https://fonts.gstatic.com; img-src 'self' data:;";

function send(res, status, body, headers = {}) {
  res.writeHead(status, headers);
  res.end(body);
}

function serveFile(res, filePath) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      send(res, 404, 'Not found', {
        'Content-Type': 'text/plain; charset=utf-8',
        ...SECURITY_HEADERS,
      });
      return;
    }
    const ext = path.extname(filePath).toLowerCase();

    // Inject deploy-time config into HTML. %%NOOR_API_URL%% was a Netlify
    // placeholder that was never actually substituted — Railway gives us a
    // real server, so fill it from the environment.
    let body = data;
    if (ext === '.html') {
      let html = body.toString('utf8');
      if (html.includes('%%')) {
        html = html
          .replace('%%NOOR_API_URL%%', process.env.NOOR_API_URL || '')
          .replace('%%NOOR_PAYSTACK_PUBLIC_KEY%%', process.env.NOOR_PAYSTACK_PUBLIC_KEY || '');
      }
      body = Buffer.from(html, 'utf8');
    }

    send(res, 200, body, {
      'Content-Type': MIME[ext] || 'application/octet-stream',
      'Cache-Control': ext === '.html' ? 'no-cache' : 'public, max-age=86400',
      ...SECURITY_HEADERS,
      ...(filePath.endsWith('subscribe.html')
        ? { 'Content-Security-Policy': SUBSCRIBE_CSP }
        : {}),
    });
  });
}

const server = http.createServer((req, res) => {
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  } catch {
    send(res, 400, 'Bad request', { 'Content-Type': 'text/plain', ...SECURITY_HEADERS });
    return;
  }

  // Path traversal guard — resolve and confirm the target stays in ROOT.
  const resolved = path.normalize(path.join(ROOT, pathname));
  if (!resolved.startsWith(ROOT)) {
    send(res, 403, 'Forbidden', { 'Content-Type': 'text/plain', ...SECURITY_HEADERS });
    return;
  }

  if (ROUTES[pathname]) {
    serveFile(res, path.join(ROOT, ROUTES[pathname]));
    return;
  }

  const target = path.extname(resolved) ? resolved : path.join(resolved, 'index.html');
  serveFile(res, target);
});

server.listen(PORT, () => {
  console.log(`Noor Companion website running on port ${PORT}`);
});
