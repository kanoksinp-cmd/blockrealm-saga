'use strict';
(() => {
  const endpoint='https://gqbqbosjszmlhebbsbmy.supabase.co';
  const key='sb_publishable_x8E8FTaCVqo631rTnsf_Eg_vSpfDKAg';
  const form=document.querySelector('#account-form'),name=document.querySelector('#username'),password=document.querySelector('#password'),confirmation=document.querySelector('#confirmation');
  const status=document.querySelector('#status'),submit=document.querySelector('#submit'),toggle=document.querySelector('#switch');
  let register=false,busy=false,grant=null,currentSession=null,gameFrame=null;
  const GAME_URL='play/index.html?build=f0ab47945ce0a37d';
  // Remember the sign-in on this device so a refresh, a reopened tab or the game frame
  // reloading does not ask for the password again. Server sessions last 24 hours.
  const REMEMBER_KEY='blockrealm.game-session.v1',REMEMBER_MS=23*3600*1000;
  function remembered(){try{const v=JSON.parse(localStorage.getItem(REMEMBER_KEY)||'null');
    if(v&&/^[a-f0-9]{64}$/.test(v.t)&&/^[a-z][a-z0-9_]{2,23}$/.test(v.u)&&v.e>Date.now())return v;}catch(_){}
    forget();return null;}
  function remember(token,user){try{localStorage.setItem(REMEMBER_KEY,JSON.stringify({t:token,u:user,e:Date.now()+REMEMBER_MS}));}catch(_){}}
  function forget(){try{localStorage.removeItem(REMEMBER_KEY);}catch(_){}}
  const root=document.documentElement,area=document.querySelector('#play-area');
  const $=sel=>document.querySelector(sel);
  const tools=$('#play-tools');
  $('#play-tools-close').addEventListener('click',()=>{tools.open=false;if(gameFrame)gameFrame.contentWindow.focus();});
  $('#play-fullscreen').addEventListener('click',()=>{tools.open=false;enterFullscreen();});
  document.addEventListener('keydown',event=>{if(event.key==='Escape')tools.open=false;});
  // ---------- phones / tablets ----------
  const coarse=!!(window.matchMedia&&matchMedia('(pointer:coarse)').matches);
  const mobile=(coarse&&(navigator.maxTouchPoints||0)>0)||/Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent||'');
  const ios=/iP(hone|ad|od)/.test(navigator.userAgent||'')||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
  const standalone=navigator.standalone===true||!!(window.matchMedia&&matchMedia('(display-mode: fullscreen), (display-mode: standalone)').matches);
  const canFullscreen=!!(area.requestFullscreen||area.webkitRequestFullscreen);
  let userExited=false,lastExit=0,wakeLock=null;
  const isFull=()=>!!(document.fullscreenElement||document.webkitFullscreenElement);
  function fitHeight(){
    const h=(window.visualViewport&&window.visualViewport.height)||window.innerHeight;
    root.style.setProperty('--app-h',Math.round(h)+'px');
  }
  function noZoom(on){
    const meta=document.querySelector('meta[name=viewport]');
    if(meta)meta.content='width=device-width,initial-scale=1,viewport-fit=cover'+(on?',maximum-scale=1,user-scalable=no':'');
  }
  async function keepAwake(){
    try{if(mobile&&'wakeLock' in navigator&&!wakeLock&&document.visibilityState==='visible'){wakeLock=await navigator.wakeLock.request('screen');wakeLock.addEventListener('release',()=>{wakeLock=null;});}}catch(_){}
  }
  function syncFsButton(){
    const b=$('#m-fs');if(!b)return;
    b.hidden=!(mobile&&canFullscreen&&!standalone&&gameFrame&&!isFull()&&$('#m-start').hidden);
  }
  function lockLandscape(){
    /* portrait and landscape are both supported: no orientation lock */
  }
  function enterFullscreen(){
    userExited=false;
    if(!mobile){if(gameFrame&&gameFrame.requestFullscreen)gameFrame.requestFullscreen().catch(()=>{});return Promise.resolve(false);}
    window.scrollTo(0,0);fitHeight();keepAwake();
    if(isFull()){lockLandscape();return Promise.resolve(true);}
    const request=area.requestFullscreen||area.webkitRequestFullscreen;
    if(!request)return Promise.resolve(false);
    let p;try{p=Promise.resolve(request.call(area,{navigationUI:'hide'}));}catch(e){p=Promise.reject(e);}
    return p.then(()=>{lockLandscape();syncFsButton();return true;}).catch(()=>{syncFsButton();return false;});
  }
  function refullscreen(){
    if(!mobile||userExited||isFull()||!canFullscreen||standalone||Date.now()-lastExit<800)return;
    try{const a=gameFrame&&gameFrame.contentDocument&&gameFrame.contentDocument.activeElement;
      if(a&&(a.tagName==='INPUT'||a.tagName==='TEXTAREA'))return;}catch(_){}   // typing in chat: keep the keyboard
    enterFullscreen();
  }
  function startMobile(){
    root.classList.add('mobile-play');noZoom(true);fitHeight();window.scrollTo(0,0);
    if(ios&&!standalone&&!canFullscreen){
      let seen=false;try{seen=localStorage.getItem('br_ios_tip')==='1';}catch(_){}
      if(!seen)$('#m-ios').hidden=false;
    }
    keepAwake();
    if(standalone||!canFullscreen)return;          // already app-like, or no API (iPhone Safari)
    // the sign-in tap may still count as a user gesture: try right away,
    // otherwise ask for one big tap before the game starts drawing
    enterFullscreen().then(ok=>{if(!ok&&!isFull()){$('#m-start').hidden=false;syncFsButton();}});
  }
  if(mobile){
    window.addEventListener('resize',fitHeight);
    window.addEventListener('orientationchange',()=>setTimeout(fitHeight,250));
    if(window.visualViewport)window.visualViewport.addEventListener('resize',fitHeight);
    document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='visible'&&gameFrame)keepAwake();});
    const onFsChange=()=>{
      if(!isFull()){lastExit=Date.now();window.scrollTo(0,0);fitHeight();}
      syncFsButton();
    };
    document.addEventListener('fullscreenchange',onFsChange);
    document.addEventListener('webkitfullscreenchange',onFsChange);
    $('#m-go').addEventListener('click',()=>{$('#m-start').hidden=true;enterFullscreen();try{gameFrame&&gameFrame.contentWindow.focus();}catch(_){}});
    $('#m-skip').addEventListener('click',()=>{$('#m-start').hidden=true;userExited=true;syncFsButton();});
    $('#m-fs').addEventListener('click',()=>enterFullscreen());
    $('#m-ios button').addEventListener('click',()=>{$('#m-ios').hidden=true;try{localStorage.setItem('br_ios_tip','1');}catch(_){}});
  }
  function updateSession(token,username){
    currentSession=token&&/^[a-f0-9]{64}$/.test(token)&&/^[a-z][a-z0-9_]{2,23}$/.test(username)?{session_token:token,expected_username:username}:null;
    document.querySelector('#account-name').textContent=currentSession?'บัญชี: '+username:'เซฟในเครื่อง — ยังไม่ได้เข้าสู่บัญชี';
    $('#play-account-label').textContent=$('#account-name').textContent;
    if(!currentSession)grant=null;
  }
  // The game asks for the sign-in each time it starts. Answer with the current session every
  // time (not only once), so a reloaded or crashed-and-restarted game frame stays signed in.
  // update() is called by the game after an in-game sign-in or sign-out.
  window.BlockrealmGameAccountBridge=Object.freeze({
    take(){const value=currentSession||grant;grant=null;return value?JSON.stringify(value):'';},
    update(token,username){updateSession(token,username);
      if(currentSession){if(!rememberBox||rememberBox.checked)remember(currentSession.session_token,currentSession.expected_username);}else forget();}
  });
  window.blockrealmReloadGame=()=>{
    if(!gameFrame)return;grant=currentSession?{...currentSession}:null;
    gameFrame.src='about:blank';setTimeout(()=>{gameFrame.src=GAME_URL},50);
  };
  window.blockrealmEnterDisplay=()=>{enterFullscreen();};
  window.blockrealmRestoreDisplay=()=>{
    userExited=true;
    try{if(screen.orientation&&screen.orientation.unlock)screen.orientation.unlock();}catch(_){}
    if(document.fullscreenElement&&document.exitFullscreen)document.exitFullscreen().catch(()=>{});
    else if(document.webkitFullscreenElement&&document.webkitExitFullscreen)document.webkitExitFullscreen();
    syncFsButton();
  };
  const messages={username_taken:'ชื่อบัญชีนี้ถูกใช้แล้ว กรุณาเลือกชื่ออื่น',invalid_credentials:'ชื่อบัญชีหรือรหัสผ่านไม่ถูกต้อง',invalid_username:'กรุณาตรวจรูปแบบชื่อบัญชี',invalid_password:'รหัสผ่านต้องมีอย่างน้อย 8 ตัว หากรหัสยาวมากกรุณาลดความยาว',rate_limited:'ลองสมัครหรือเข้าสู่ระบบบ่อยเกินไป กรุณารอสักครู่'};
  function lock(value){busy=value;for(const input of form.querySelectorAll('input,button'))input.disabled=value;}
  toggle.addEventListener('click',()=>{
    if(busy)return;register=!register;password.value='';confirmation.value='';status.textContent='';
    document.querySelector('#heading').textContent=register?'สมัครบัญชีเกมใหม่':'เข้าสู่ระบบบัญชีเกม';
    document.querySelector('#confirmation-row').hidden=!register;confirmation.required=register;
    password.autocomplete=register?'new-password':'current-password';
    submit.textContent=register?'สร้างบัญชีเกม':'เข้าสู่ระบบ';toggle.textContent=register?'มีบัญชีแล้ว → เข้าสู่ระบบ':'ยังไม่มีบัญชี → สมัครบัญชีใหม่';
  });
  form.addEventListener('submit',async event=>{
    event.preventDefault();if(busy||!form.reportValidity())return;
    const username=name.value.trim().toLowerCase();
    if(!/^[a-z][a-z0-9_]{2,23}$/.test(username)){status.textContent=messages.invalid_username;return;}
    if(password.value.length<8||new TextEncoder().encode(password.value).length>72){status.textContent=messages.invalid_password;return;}
    if(register&&password.value!==confirmation.value){status.textContent='ยืนยันรหัสผ่านไม่ตรงกัน';return;}
    lock(true);status.textContent=register?'กำลังสร้างบัญชีเกม…':'กำลังเข้าสู่ระบบ…';
    try{
      const response=await fetch(endpoint+'/rest/v1/rpc/'+(register?'game_register':'game_sign_in'),{method:'POST',headers:{apikey:key,'Content-Type':'application/json'},body:JSON.stringify({p_username:username,p_password:password.value}),signal:AbortSignal.timeout(20000),cache:'no-store'});
      const data=await response.json();
      if(!response.ok||!data.ok){status.textContent=messages[data.error]||'เชื่อมต่อบัญชีไม่สำเร็จ กรุณาลองใหม่';return;}
      if(!data.user||data.user.username!==username||typeof data.session_token!=='string'||!/^[a-f0-9]{64}$/.test(data.session_token))throw Error('invalid session');
      updateSession(data.session_token,data.user.username);
      if(rememberBox&&rememberBox.checked)remember(data.session_token,data.user.username);else forget();
      password.value='';confirmation.value='';
      launch(data.user.username);
    }catch(_){status.textContent='เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่';}
    finally{lock(false);}
  });
  function launch(username){
      grant=currentSession?{...currentSession}:null;
      document.querySelector('#account-name').textContent='บัญชี: '+username;
      document.querySelector('#account-card').hidden=true;document.querySelector('#play-area').hidden=false;
      const frame=document.createElement('iframe');gameFrame=frame;frame.title='Blockrealm Saga — เกมของบัญชี '+username;
      frame.allow='autoplay; fullscreen; gamepad; screen-wake-lock';frame.src=GAME_URL;
      frame.addEventListener('load',()=>{
        try{frame.contentWindow.focus();}catch(_){}
        // phones: a tap inside the game brings full screen back (the browser drops it
        // on swipe-back, notifications, keyboard...) unless the player chose to leave it
        if(mobile)try{for(const t of ['touchend','pointerup'])frame.contentWindow.addEventListener(t,refullscreen,true);}catch(_){}
      });
      document.querySelector('#game-host').appendChild(frame);
      if(mobile)startMobile();
  }
  // "remember me" checkbox under the password (on by default; untick on shared computers)
  const rememberBox=(()=>{const row=document.createElement('label');row.className='remember';
    row.innerHTML='<input type="checkbox" id="remember" checked style="width:18px;height:18px;min-width:0;margin:0;padding:0;flex:none;accent-color:#e9bf62"><span>จำการเข้าสู่ระบบในเครื่องนี้ (24 ชั่วโมง)</span>';
    row.style.cssText='display:flex;gap:10px;align-items:center;justify-content:flex-start;text-align:left;margin:12px 0 4px;font-size:14px;cursor:pointer;width:auto';
    status.parentNode.insertBefore(row,status);return row.querySelector('input');})();
  // sign out from the page (clears the remembered sign-in and ends the server session)
  function signOut(){
    const s=currentSession||(remembered()&&{session_token:remembered().t});
    forget();updateSession('','');
    if(s&&s.session_token)fetch(endpoint+'/rest/v1/rpc/game_sign_out',{method:'POST',headers:{apikey:key,'Content-Type':'application/json'},body:JSON.stringify({p_session_token:s.session_token}),keepalive:true}).catch(()=>{});
    setTimeout(()=>location.reload(),150);
  }
  (()=>{const body=document.querySelector('#play-tools .play-tools-body');if(!body)return;
    const b=document.createElement('button');b.type='button';b.id='play-sign-out';b.textContent='ออกจากระบบบัญชีนี้';
    b.addEventListener('click',signOut);body.insertBefore(b,body.querySelector('a'));})();
  // come back signed in: check the remembered session with the server, then start the game
  (async()=>{
    const saved=remembered();if(!saved)return;
    lock(true);status.textContent='กำลังกลับเข้าบัญชี '+saved.u+'…';
    try{
      const r=await fetch(endpoint+'/rest/v1/rpc/game_whoami',{method:'POST',headers:{apikey:key,'Content-Type':'application/json'},body:JSON.stringify({p_session_token:saved.t}),signal:AbortSignal.timeout(20000),cache:'no-store'});
      const d=await r.json();
      if(r.ok&&d&&d.ok&&d.user&&d.user.username===saved.u){updateSession(saved.t,saved.u);status.textContent='';launch(saved.u);return;}
      forget();status.textContent='การเข้าสู่ระบบหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง';
    }catch(_){status.textContent='เชื่อมต่อบัญชีไม่ได้ กรุณาเข้าสู่ระบบอีกครั้ง';}
    finally{lock(false);}
  })();
  submit.disabled=false;toggle.disabled=false;
})();
