const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync('C:/Users/Guide/Documents/blockrealm-saga-clone/assets/game-account.js','utf8');
let checks=0;
function fixture(reply){
 const nodes=new Map();
 const node=id=>{if(!nodes.has(id))nodes.set(id,{value:'',textContent:'',hidden:false,disabled:false,open:false,style:{setProperty(){}},classList:{add(){}},handlers:{},addEventListener(n,cb){this.handlers[n]=cb},reportValidity(){return true},querySelectorAll(){return []},appendChild(c){this.child=c}});return nodes.get(id)};
 const requests=[];const document={documentElement:node('root'),querySelector:node,createElement:()=>({...node('frame'),handlers:{}}),addEventListener(){},visibilityState:'visible'};
 const ctx={window:{},document,navigator:{userAgent:'Windows',maxTouchPoints:0},screen:{},fetch:async(url,opt)=>{requests.push({url,body:JSON.parse(opt.body)});if(reply instanceof Error)throw reply;return{ok:true,json:async()=>reply}},TextEncoder,AbortSignal,JSON,Object,Error,Date,Promise,setTimeout:cb=>cb()};
 vm.runInNewContext(source,ctx);return{nodes,node,ctx,requests};
}
(async()=>{
 const response={ok:true,session_token:'a'.repeat(64),user:{id:'11111111-1111-4111-8111-111111111111',username:'player_01'}};
 let f=fixture(response),n=f.node;
 n('#switch').handlers.click();assert.equal(n('#confirmation').required,true);checks++;
 n('#username').value=' Player_01 ';n('#password').value='test-only-password';n('#confirmation').value='mismatch';
 await n('#account-form').handlers.submit({preventDefault(){}});assert.equal(f.requests.length,0);checks++;
 n('#confirmation').value='test-only-password';await n('#account-form').handlers.submit({preventDefault(){}});
 assert.equal(f.requests[0].body.p_username,'player_01');assert.ok(f.requests[0].url.endsWith('/game_register'));checks+=2;
 assert.equal(n('#password').value,'');assert.equal(n('#confirmation').value,'');assert.equal(n('#play-area').hidden,false);assert.equal(n('#account-card').hidden,true);checks+=4;
 const frame=n('#game-host').child;assert.match(frame.src,/play\/index.html\?build=[a-f0-9]{16}/);assert.ok(!frame.src.includes('session')&&!frame.src.includes('password'));checks+=2;
 assert.equal(JSON.parse(f.ctx.window.BlockrealmGameAccountBridge.take()).expected_username,'player_01');assert.equal(f.ctx.window.BlockrealmGameAccountBridge.take(),'');checks+=2;
 f.ctx.window.blockrealmReloadGame();assert.equal(JSON.parse(f.ctx.window.BlockrealmGameAccountBridge.take()).session_token,response.session_token);checks++;
 f.ctx.window.BlockrealmGameAccountBridge.update('','');f.ctx.window.blockrealmReloadGame();assert.equal(f.ctx.window.BlockrealmGameAccountBridge.take(),'');checks++;
 for(const reply of [{ok:false,error:'invalid_credentials'},Error('offline'),{...response,user:{...response.user,username:'other_account'}}]){
  f=fixture(reply);n=f.node;n('#username').value='player_01';n('#password').value='test-only-password';await n('#account-form').handlers.submit({preventDefault(){}});
  assert.equal(n('#game-host').child,undefined);assert.ok(n('#status').textContent.length>0);checks+=2;
 }
 console.log('PASS_PORTAL '+checks+' registration/login, validation, rejection, cleared passwords and session bridge checks');
})();
