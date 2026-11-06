/* Keep mobile drawing bounded without changing physics, saves, or input timing. */
(() => {
  'use strict';
  let forced = new URLSearchParams(location.search).get('mobile');
  try {
    if (forced === null) forced = new URLSearchParams(parent.location.search).get('mobile');
  } catch (_) { /* Cross-origin embedding uses local detection. */ }
  const touch = navigator.maxTouchPoints > 0;
  const mobile = forced === '1' || (forced !== '0' && (
    /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
    (touch && (/Macintosh/i.test(navigator.userAgent) || matchMedia('(pointer: coarse)').matches))
  ));
  window.BlockrealmMobileProfile = {
    mobile,
    configure(config, canvas) {
      if (!mobile) return;
      config.canvasResizePolicy = 0;
      const resize = () => {
        const w = Math.max(1, Math.round(innerWidth));
        const h = Math.max(1, Math.round(innerHeight));
        const factor = Math.min(devicePixelRatio || 1, 1.25,
          1280 / Math.max(w, h), 800 / Math.min(w, h));
        canvas.style.width = `${w}px`;
        canvas.style.height = `${h}px`;
        const width = Math.max(1, Math.round(w * factor));
        const height = Math.max(1, Math.round(h * factor));
        if (canvas.width !== width) canvas.width = width;
        if (canvas.height !== height) canvas.height = height;
      };
      let timer;
      const queueResize = () => { clearTimeout(timer); timer = setTimeout(resize, 120); };
      addEventListener('resize', queueResize, {passive: true});
      addEventListener('orientationchange', queueResize, {passive: true});
      document.addEventListener('fullscreenchange', queueResize);
      resize();
    }
  };
})();
