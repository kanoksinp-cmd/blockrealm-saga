const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const code = fs.readFileSync(__dirname+'/account-bridge.js','utf8');
const key = 'blockrealm.pending-email.gqbqbosjszmlhebbsbmy';
let checks=0;
function boot(hash,record,storageError=false){
  const data=new Map(record?[[key,JSON.stringify(record)]]:[]);
  const history=[];
  const context={window:{},location:{hash,pathname:'/play/index.html',search:'?build=test'},
    URLSearchParams,Date,JSON,Number,Object,String,
    history:{replaceState:(...args)=>history.push(args)},
    localStorage:{getItem:k=>{if(storageError)throw Error('blocked');return data.get(k)||null},
      setItem:(k,v)=>{if(storageError)throw Error('blocked');data.set(k,v)},removeItem:k=>data.delete(k)}};
  vm.runInNewContext(code,context);
  return {bridge:context.window.BlockrealmAccountBridge,data,history};
}
const grant='#access_token=fake-access&refresh_token=fake-refresh&expires_in=3600&type=signup';
const pending={email:'player@example.test',created:Date.now()};
let page=boot(grant,pending);
const result=JSON.parse(page.bridge.take());
assert.equal(result.expected_email,pending.email);checks++;
assert.equal(result.access_token,'fake-access');checks++;
assert.equal(page.bridge.take(),'');checks++;
assert.equal(page.history[0][2],'/play/index.html?build=test');checks++;
assert.ok(![...page.data.values()].some(x=>x.includes('fake-access')||x.includes('fake-refresh')));checks++;
page.bridge.clear();assert.equal(page.data.size,0);checks++;
page=boot('#error=access_denied&error_code=otp_expired',pending);
assert.equal(JSON.parse(page.bridge.take()).error,'expired_or_used');checks++;
assert.equal(page.history.length,1);checks++;
page=boot(grant,null);assert.equal(JSON.parse(page.bridge.take()).error,'request_missing');checks++;
page=boot(grant,{...pending,created:Date.now()-31*60*1000});assert.equal(JSON.parse(page.bridge.take()).error,'request_missing');checks++;
page=boot(grant.replace('signup','recovery'),pending);assert.equal(JSON.parse(page.bridge.take()).error,'wrong_type');checks++;
page=boot('#fashion',null);assert.equal(page.history.length,0);assert.equal(page.bridge.take(),'');checks++;
assert.equal(page.bridge.remember(' PLAYER@example.test '),true);assert.equal(JSON.parse(page.data.get(key)).email,'player@example.test');checks++;
page=boot('',null,true);assert.equal(page.bridge.remember('player@example.test'),false);checks++;
console.log('EMAIL CALLBACK BRIDGE CHECKS: '+checks+' passed');
