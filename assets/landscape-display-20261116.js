(() => {
  'use strict';
  const mobile = matchMedia('(pointer:coarse)').matches || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
  if (!mobile) return;
  const style = document.createElement('style');
  style.textContent = '#br-landscape-hint{position:fixed;inset:0;z-index:2147483000;display:none;align-items:center;justify-content:center;text-align:center;background:#101720;color:#f5ead3;padding:24px max(24px,env(safe-area-inset-right)) 24px max(24px,env(safe-area-inset-left));font:16px/1.65 system-ui,sans-serif;box-sizing:border-box;touch-action:none}#br-landscape-hint.show{display:flex}#br-landscape-hint button{font:600 17px system-ui;padding:14px 22px;border:1px solid #d4b467;border-radius:10px;background:#314c55;color:white;min-height:48px}';
  document.head.append(style);
  const hint = document.createElement('div'); hint.id = 'br-landscape-hint';
  hint.innerHTML = '<section><div style="font-size:48px">↻</div><h2>หมุนมือถือเป็นแนวนอน</h2><p>เพื่อให้เห็นฉากกว้างและแตะปุ่มได้ถนัด<br>จอยซ้ายเดิน · ปุ่มขวาต่อสู้ · สองนิ้วซูม</p><button type="button">เล่นแนวนอน / เต็มจอ</button><p style="font-size:13px;color:#c5cedb">หากหน้าจอไม่หมุน ให้ปิดการล็อกแนวตั้งแล้วหมุนเครื่อง</p></section>';
  document.body.append(hint);
  function update() {
    const type = screen.orientation && screen.orientation.type;
    const portrait = type ? type.startsWith('portrait') : screen.height > screen.width;
    hint.classList.toggle('show', portrait);
  }
  hint.querySelector('button').addEventListener('click', async () => {
    try {
      if (parent !== window && parent.blockrealmEnterDisplay) parent.blockrealmEnterDisplay();
      else if (document.documentElement.requestFullscreen) await document.documentElement.requestFullscreen();
      if (screen.orientation && screen.orientation.lock) await screen.orientation.lock('landscape');
    } catch (_) {}
    update();
  });
  window.addEventListener('orientationchange', update);
  window.addEventListener('resize', update);
  if (screen.orientation && screen.orientation.addEventListener) screen.orientation.addEventListener('change', update);
  update();
})();
