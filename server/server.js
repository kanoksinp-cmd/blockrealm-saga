// Blockrealm Saga online server
// - WebSocket at /ws : everyone who connects sees everyone else (position, look, chat)
// - Also serves the website files from the repository root, so this one service can
//   host the whole game if you want (https://<service>.onrender.com/).
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');

const PORT = Number(process.env.PORT) || 8080;
const ROOT = path.resolve(__dirname, '..');
const MAX_PLAYERS = Number(process.env.MAX_PLAYERS) || 150;
const TICK_MS = 100;            // position broadcast rate (10 Hz)
const MAX_MSG = 16 * 1024;      // bytes per message
const CHAT_MAX = 160;           // characters per chat line
const CHAT_GAP_MS = 700;        // min time between chat lines per player

// ------------------------------------------------------------------ static files
const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.webmanifest': 'application/manifest+json', '.png': 'image/png', '.webp': 'image/webp', '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf', '.txt': 'text/plain; charset=utf-8', '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.ico': 'image/x-icon',
};

function serveStatic(req, res) {
  let urlPath;
  try { urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname); } catch (e) { res.writeHead(400); return res.end(); }
  if (urlPath === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Cache-Control': 'no-store' });
    return res.end(JSON.stringify({ ok: true, players: players.size }));
  }
  if (urlPath.endsWith('/')) urlPath += 'index.html';
  const file = path.resolve(ROOT, '.' + urlPath);
  const rel = path.relative(ROOT, file);
  if (rel.startsWith('..') || path.isAbsolute(rel) || rel.split(path.sep).some(s => s.startsWith('.') || s === 'server' || s === 'node_modules')) {
    res.writeHead(404); return res.end('Not found');
  }
  fs.stat(file, (err, st) => {
    if (err || !st.isFile()) { res.writeHead(404); return res.end('Not found'); }
    const ext = path.extname(file).toLowerCase();
    res.writeHead(200, {
      'Content-Type': TYPES[ext] || 'application/octet-stream',
      'Content-Length': st.size,
      'Cache-Control': ext === '.html' ? 'no-cache' : 'public, max-age=3600',
    });
    if (req.method === 'HEAD') return res.end();
    fs.createReadStream(file).pipe(res);
  });
}

const server = http.createServer(serveStatic);

// ------------------------------------------------------------------ players
let nextId = 1;
const players = new Map();   // id -> player

function clean(s, max) {
  return String(s == null ? '' : s).replace(/[\u0000-\u001f\u007f\[\]]/g, '').trim().slice(0, max);
}

// Appearance / equipment are small dictionaries of numbers, strings and string arrays.
function cleanDict(d, depth = 0) {
  const out = {};
  if (!d || typeof d !== 'object' || Array.isArray(d) || depth > 2) return out;
  let n = 0;
  for (const k of Object.keys(d)) {
    if (++n > 40) break;
    const key = clean(k, 32);
    if (!/^[a-z_0-9]+$/i.test(key)) continue;
    const v = d[k];
    if (typeof v === 'number' && Number.isFinite(v)) out[key] = Math.max(-1e6, Math.min(1e6, v));
    else if (typeof v === 'string') out[key] = clean(v, 48);
    else if (typeof v === 'boolean') out[key] = v;
    else if (Array.isArray(v)) out[key] = v.slice(0, 16).filter(x => typeof x === 'string').map(x => clean(x, 32));
    else if (typeof v === 'object' && v) out[key] = cleanDict(v, depth + 1);
  }
  return out;
}

function num(v, lim) {
  v = Number(v);
  if (!Number.isFinite(v)) return 0;
  return Math.max(-lim, Math.min(lim, Math.round(v * 100) / 100));
}

function publicInfo(p) {
  return { id: p.id, name: p.name, job: p.job, lv: p.lv, look: p.look, equip: p.equip, refine: p.refine, s: p.state };
}

function send(ws, obj) {
  if (ws.readyState === 1) ws.send(JSON.stringify(obj));
}

function broadcast(obj, exceptId) {
  const msg = JSON.stringify(obj);
  for (const p of players.values()) {
    if (p.id !== exceptId && p.ready && p.ws.readyState === 1) p.ws.send(msg);
  }
}

const wss = new WebSocketServer({ server, path: '/ws', maxPayload: MAX_MSG, perMessageDeflate: false });

wss.on('connection', (ws, req) => {
  if (players.size >= MAX_PLAYERS) {
    send(ws, { t: 'full' });
    return ws.close(1013, 'server full');
  }
  const p = {
    id: nextId++, ws, ready: false, name: 'Adventurer', job: 'swordsman', lv: 1,
    look: {}, equip: {}, refine: {}, state: [0, 0, 0, 0, 0, 0, 0], dirty: false,
    lastChat: 0, alive: true, msgs: 0, msgWindow: Date.now(),
    party: null, invites: new Map(), lastGift: 0,
  };
  players.set(p.id, p);

  ws.on('pong', () => { p.alive = true; });

  ws.on('message', (data, isBinary) => {
    // simple flood guard: 60 messages per second max
    const now = Date.now();
    if (now - p.msgWindow > 1000) { p.msgWindow = now; p.msgs = 0; }
    if (++p.msgs > 60 || isBinary) return;
    let m;
    try { m = JSON.parse(data.toString()); } catch (e) { return; }
    if (!m || typeof m !== 'object') return;

    switch (m.t) {
      case 'hello': {
        p.name = clean(m.name, 24) || 'Adventurer';
        p.job = clean(m.job, 24) || 'swordsman';
        p.lv = Math.max(1, Math.min(999, Math.floor(Number(m.lv) || 1)));
        p.look = cleanDict(m.look);
        p.equip = cleanDict(m.equip);
        p.refine = cleanDict(m.refine);
        if (Array.isArray(m.s)) p.state = readState(m.s);
        const first = !p.ready;
        p.ready = true;
        if (first) {
          send(ws, { t: 'welcome', id: p.id, players: [...players.values()].filter(o => o.ready && o.id !== p.id).map(publicInfo) });
          broadcast({ t: 'join', p: publicInfo(p) }, p.id);
          console.log(`join #${p.id} ${p.name} (${players.size} online)`);
        } else {
          broadcast({ t: 'look', p: publicInfo(p) }, p.id);
          const pt = p.party && parties.get(p.party);
          if (pt) sendParty(pt);
        }
        break;
      }
      case 's': // position/state: [x, y, z, yaw, moving, attackCount, dead]
        if (p.ready && Array.isArray(m.s)) { p.state = readState(m.s); p.dirty = true; }
        break;
      case 'chat': {
        if (!p.ready) break;
        const text = clean(m.msg, CHAT_MAX);
        if (!text || now - p.lastChat < CHAT_GAP_MS) break;
        p.lastChat = now;
        const pt = m.party && p.party && parties.get(p.party);
        if (pt) {
          for (const id of pt.members) { const x = players.get(id); if (x) send(x.ws, { t: 'chat', id: p.id, name: p.name, msg: text, party: true }); }
        } else {
          broadcast({ t: 'chat', id: p.id, name: p.name, msg: text });
        }
        break;
      }
      case 'invite': {            // {to}
        const to = players.get(Number(m.to));
        if (!p.ready || !to || !to.ready || to.id === p.id) break;
        const mine = p.party && parties.get(p.party);
        if (mine && mine.members.length >= PARTY_MAX) { send(ws, { t: 'notice', key: 'party_full' }); break; }
        if (mine && mine.members.includes(to.id)) break;
        if (to.party) { send(ws, { t: 'notice', key: 'in_party', name: to.name }); break; }
        to.invites.set(p.id, now);
        send(to.ws, { t: 'invite', from: p.id, name: p.name, lv: p.lv, job: p.job });
        send(ws, { t: 'notice', key: 'invite_sent', name: to.name });
        break;
      }
      case 'invite_reply': {      // {to: inviterId, ok}
        const from = players.get(Number(m.to));
        const at = p.invites.get(Number(m.to));
        p.invites.delete(Number(m.to));
        if (!from || !at || now - at > 120000) { send(ws, { t: 'notice', key: 'invite_expired' }); break; }
        if (!m.ok) { send(from.ws, { t: 'notice', key: 'invite_declined', name: p.name }); break; }
        if (p.party) leaveParty(p, 'left');
        let pt = from.party && parties.get(from.party);
        if (!pt) { pt = { id: nextParty++, leader: from.id, members: [from.id] }; parties.set(pt.id, pt); from.party = pt.id; }
        if (pt.members.length >= PARTY_MAX) { send(ws, { t: 'notice', key: 'party_full' }); break; }
        pt.members.push(p.id);
        p.party = pt.id;
        for (const id of pt.members) { const x = players.get(id); if (x && id !== p.id) send(x.ws, { t: 'party_note', name: p.name, what: 'joined' }); }
        sendParty(pt);
        break;
      }
      case 'party_leave':
        if (p.party) leaveParty(p, 'left');
        break;
      case 'party_kick': {        // leader only
        const pt = p.party && parties.get(p.party);
        const to = players.get(Number(m.to));
        if (pt && pt.leader === p.id && to && to.party === pt.id && to.id !== p.id) leaveParty(to, 'kicked');
        break;
      }
      case 'pexp': {              // share kill EXP with the party: {amount, x, z}
        const pt = p.party && parties.get(p.party);
        if (!pt) break;
        const amount = Math.max(0, Math.min(5000000, Math.floor(Number(m.amount) || 0)));
        if (!amount) break;
        for (const id of pt.members) { if (id === p.id) continue; const x = players.get(id); if (x) send(x.ws, { t: 'pexp', from: p.id, name: p.name, amount, x: num(m.x, 1e5), z: num(m.z, 1e5) }); }
        break;
      }
      case 'gift': {              // {to, item, n}
        const to = players.get(Number(m.to));
        const item = clean(m.item, 48);
        const n = Math.max(1, Math.min(9999, Math.floor(Number(m.n) || 1)));
        if (!p.ready || !item || !/^[a-z0-9_]+$/.test(item)) break;
        if (!to || !to.ready || to.id === p.id || now - p.lastGift < 300) { send(ws, { t: 'gift_fail', item, n, to: Number(m.to) }); break; }
        p.lastGift = now;
        send(to.ws, { t: 'gift', from: p.id, name: p.name, item, n });
        send(ws, { t: 'gift_ok', to: to.id, name: to.name, item, n });
        console.log(`gift ${p.name} -> ${to.name}: ${item} x${n}`);
        break;
      }
      case 'ping':
        send(ws, { t: 'pong', k: m.k });
        break;
    }
  });

  ws.on('close', () => {
    if (p.party) leaveParty(p, 'offline');
    players.delete(p.id);
    if (p.ready) {
      broadcast({ t: 'leave', id: p.id });
      console.log(`leave #${p.id} ${p.name} (${players.size} online)`);
    }
  });
  ws.on('error', () => {});
});

function readState(s) {
  return [num(s[0], 1e5), num(s[1], 1e5), num(s[2], 1e5), num(s[3], 100), s[4] ? 1 : 0,
    Math.floor(Math.abs(Number(s[5]) || 0)) % 1000, s[6] ? 1 : 0,
    Math.max(0, Math.min(100, Math.round(Number(s[7] == null ? 100 : s[7]) || 0)))];
}

// ------------------------------------------------------------------ parties (max 4 players)
const PARTY_MAX = 4;
let nextParty = 1;
const parties = new Map();   // id -> {id, leader, members: [playerId]}

function partyInfo(pt) {
  return { t: 'party', id: pt.id, leader: pt.leader, members: pt.members.map(id => {
    const m = players.get(id); return m ? { id, name: m.name, job: m.job, lv: m.lv } : null; }).filter(Boolean) };
}

function sendParty(pt) {
  const msg = partyInfo(pt);
  for (const id of pt.members) { const m = players.get(id); if (m) send(m.ws, msg); }
}

function leaveParty(p, reason) {
  const pt = p.party && parties.get(p.party);
  p.party = null;
  if (!pt) return;
  pt.members = pt.members.filter(id => id !== p.id);
  send(p.ws, { t: 'party', id: 0, leader: 0, members: [], reason: reason || 'left' });
  for (const id of pt.members) { const m = players.get(id); if (m) send(m.ws, { t: 'party_note', name: p.name, what: reason || 'left' }); }
  if (pt.members.length < 2) {
    for (const id of pt.members) { const m = players.get(id); if (m) { m.party = null; send(m.ws, { t: 'party', id: 0, leader: 0, members: [], reason: 'disbanded' }); } }
    parties.delete(pt.id);
    return;
  }
  if (pt.leader === p.id) pt.leader = pt.members[0];
  sendParty(pt);
}

// position snapshots for everyone who moved
setInterval(() => {
  const list = [];
  for (const p of players.values()) {
    if (p.ready && p.dirty) { list.push([p.id, ...p.state]); p.dirty = false; }
  }
  if (list.length) broadcast({ t: 'st', l: list });
}, TICK_MS);

// drop dead connections
setInterval(() => {
  for (const p of players.values()) {
    if (!p.alive) { p.ws.terminate(); continue; }
    p.alive = false;
    try { p.ws.ping(); } catch (e) {}
  }
}, 20000);

server.listen(PORT, () => console.log(`Blockrealm online server on :${PORT} (ws path /ws)`));
