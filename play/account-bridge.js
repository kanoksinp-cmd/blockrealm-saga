/* Capture an email callback before loading the game. Credentials stay in memory. */
(function () {
  'use strict';
  const key = 'blockrealm.pending-email.gqbqbosjszmlhebbsbmy';
  let result = null;
  const params = new URLSearchParams(location.hash.slice(1));
  const callback = params.has('access_token') || params.has('error');
  function pending() {
    try {
      const value = JSON.parse(localStorage.getItem(key) || 'null');
      if (!value || typeof value.email !== 'string' || !Number.isFinite(value.created) ||
          Date.now() - value.created < 0 || Date.now() - value.created > 30 * 60 * 1000) return null;
      return value;
    } catch (_) { return null; }
  }
  if (callback) {
    // Remove credentials from the address bar before any game/assets are loaded.
    history.replaceState(null, '', location.pathname + location.search);
    const request = pending();
    if (params.has('error')) result = { error: 'expired_or_used' };
    else if (!request) result = { error: 'request_missing' };
    else if (!['signup', 'magiclink', 'email'].includes(params.get('type'))) result = { error: 'wrong_type' };
    else result = {
      access_token: params.get('access_token'),
      refresh_token: params.get('refresh_token'),
      expires_in: Number(params.get('expires_in') || '3600'),
      expected_email: request.email,
      type: params.get('type')
    };
  }
  window.BlockrealmAccountBridge = Object.freeze({
    remember(email) {
      try { localStorage.setItem(key, JSON.stringify({ email: String(email).trim().toLowerCase(), created: Date.now() })); return true; }
      catch (_) { return false; }
    },
    clear() { try { localStorage.removeItem(key); } catch (_) {} },
    take() { const value = result; result = null; return value ? JSON.stringify(value) : ''; }
  });
}());
