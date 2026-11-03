'use strict';
(() => {
  const endpoint='https://gqbqbosjszmlhebbsbmy.supabase.co';
  const key='sb_publishable_x8E8FTaCVqo631rTnsf_Eg_vSpfDKAg';
  const form=document.querySelector('#account-form'),name=document.querySelector('#username'),password=document.querySelector('#password'),confirmation=document.querySelector('#confirmation');
  const status=document.querySelector('#status'),submit=document.querySelector('#submit'),toggle=document.querySelector('#switch');
  let register=false,busy=false,grant=null,currentSession=null,gameFrame=null;
  function updateSession(token,username){
    currentSession=token&&/^[a-f0-9]{64}$/.test(token)&&/^[a-z][a-z0-9_]{2,23}$/.test(username)?{session_token:token,expected_username:username}:null;
    document.querySelector('#account-name').textContent=currentSession?'บัญชี: '+username:'เซฟในเครื่อง — ยังไม่ได้เข้าสู่บัญชี';
    if(!currentSession)grant=null;
  }
  window.BlockrealmGameAccountBridge=Object.freeze({take(){const value=grant;grant=null;return value?JSON.stringify(value):'';},update:updateSession});
  window.blockrealmReloadGame=()=>{
    if(!gameFrame)return;grant=currentSession?{...currentSession}:null;
    gameFrame.src='about:blank';setTimeout(()=>{gameFrame.src='play/index.html?build=20261103-game-accounts'},50);
  };
  window.blockrealmEnterDisplay=()=>{if(gameFrame&&gameFrame.requestFullscreen)gameFrame.requestFullscreen().catch(()=>{});};
  window.blockrealmRestoreDisplay=()=>{if(document.fullscreenElement&&document.exitFullscreen)document.exitFullscreen().catch(()=>{});};
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
      updateSession(data.session_token,data.user.username);grant={...currentSession};
      password.value='';confirmation.value='';
      document.querySelector('#account-name').textContent='บัญชี: '+data.user.username;
      document.querySelector('#account-card').hidden=true;document.querySelector('#play-area').hidden=false;
      const frame=document.createElement('iframe');gameFrame=frame;frame.title='Blockrealm Saga — เกมของบัญชี '+data.user.username;
      frame.allow='autoplay; fullscreen';frame.src='play/index.html?build=20261103-game-accounts';document.querySelector('#game-host').appendChild(frame);
    }catch(_){status.textContent='เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่';}
    finally{lock(false);}
  });
  submit.disabled=false;toggle.disabled=false;
})();
