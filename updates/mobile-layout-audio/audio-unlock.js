/* Runs in the game frame before the engine creates its Web Audio context. */
(() => {
  'use strict';
  const contexts = new Set();
  let unlockButton;
  function sync() {
    const active = [...contexts].filter(context => context.state !== 'closed');
    const blocked = active.some(context => context.state === 'suspended' || context.state === 'interrupted');
    document.documentElement.dataset.brAudioState = blocked ? 'blocked' : (active.length ? 'running' : 'waiting');
    if (unlockButton) unlockButton.hidden = !blocked;
  }
  function resume() {
    for (const context of contexts) {
      if (context.state !== 'suspended' && context.state !== 'interrupted') continue;
      try { Promise.resolve(context.resume()).then(sync, sync); } catch (_) { sync(); }
    }
  }
  const wrapped = new Map();
  for (const name of ['AudioContext', 'webkitAudioContext']) {
    const NativeContext = window[name];
    if (typeof NativeContext !== 'function') continue;
    if (!wrapped.has(NativeContext)) {
      wrapped.set(NativeContext, new Proxy(NativeContext, {
        construct(Target, args) {
          const context = Reflect.construct(Target, args, Target);
          contexts.add(context);
          context.addEventListener('statechange', () => {
            if (context.state === 'closed') contexts.delete(context);
            sync();
          });
          sync();
          return context;
        }
      }));
    }
    window[name] = wrapped.get(NativeContext);
  }
  for (const event of ['pointerdown', 'touchend', 'keydown']) {
    document.addEventListener(event, resume, {capture:true, passive:true});
  }
  document.addEventListener('visibilitychange', () => { if (!document.hidden) resume(); });
  window.addEventListener('pageshow', resume);
  function mount() {
    unlockButton = document.createElement('button');
    unlockButton.type = 'button';
    unlockButton.id = 'enable-game-audio';
    unlockButton.textContent = 'เปิดเสียง';
    unlockButton.setAttribute('aria-label', 'แตะเพื่อเปิดเสียงเกม');
    unlockButton.style.cssText = 'position:fixed;z-index:1000;left:50%;bottom:max(12px,env(safe-area-inset-bottom));transform:translateX(-50%);min-height:44px;padding:8px 18px;background:#171d26;color:#f2eee5;border:1px solid #c7a567;border-radius:9px;font:14px system-ui,sans-serif;touch-action:manipulation;';
    unlockButton.hidden = true;
    unlockButton.addEventListener('click', resume);
    document.body.appendChild(unlockButton);
    sync();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, {once:true});
  else mount();
})();
