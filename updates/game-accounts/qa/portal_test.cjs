const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync(__dirname+'/../game-account.js','utf8');
let checks=0;
function fixture(reply){
 const nodes=new Map();for(const id of ['account-form','username','password','confirmation','status','submit','switch','heading','confirmation-row','account-name','account-card','play-area','game-host'])nodes.set('#'+id,{value:'',textContent:'',hidden:false,disabled:false,handlers:{},addEventListener(name,fn){this.handlers[name]=fn},reportValidity(){return true},querySelectorAll(){return [...nodes.values()]},appendChild(child){this.child=child}});
 const requests=[];const context={window:{},document:{querySelector:s=>nodes.get(s),createElement:()=>({})},fetch:async(url,options)=>{requests.push({url,body:JSON.parse(options.body)});return{ok:true,json:async()=>reply}},TextEncoder,AbortSignal,JSON,Object,Error,setTimeout:fn=>fn()};
 vm.runInNewContext(source,context);return{nodes,context,requests};
}
(async()=>{
 const response={ok:true,session_token:'a'.repeat(64),user:{id:'11111111-1111-4111-8111-111111111111',username:'player_01'}};
 let f=fixture(response),n=f.nodes;
 assert.equal(n.get('#submit').disabled,false);checks++;
 n.get('#switch').handlers.click();assert.equal(n.get('#confirmation').required,true);checks++;
 n.get('#username').value='Player_01';n.get('#password').value='test-only-password';n.get('#confirmation').value='mismatch';
 await n.get('#account-form').handlers.submit({preventDefault(){}});assert.equal(f.requests.length,0);checks++;
 n.get('#confirmation').value='test-only-password';await n.get('#account-form').handlers.submit({preventDefault(){}});
 assert.equal(f.requests.length,1);assert.ok(f.requests[0].url.endsWith('/game_register'));checks+=2;
 assert.equal(f.requests[0].body.p_username,'player_01');checks++;
 assert.equal(n.get('#password').value,'');assert.equal(n.get('#confirmation').value,'');checks+=2;
 assert.equal(n.get('#account-card').hidden,true);assert.equal(n.get('#play-area').hidden,false);checks+=2;
 const frame=n.get('#game-host').child;assert.equal(frame.src,'play/index.html?build=20261103-game-accounts');checks++;
 assert.ok(!frame.src.includes('password')&&!frame.src.includes('session'));checks++;
 const grant=JSON.parse(f.context.window.BlockrealmGameAccountBridge.take());assert.equal(grant.expected_username,'player_01');checks++;
 assert.equal(f.context.window.BlockrealmGameAccountBridge.take(),'');checks++;
 f.context.window.blockrealmReloadGame();assert.equal(JSON.parse(f.context.window.BlockrealmGameAccountBridge.take()).session_token,response.session_token);checks++;
 f.context.window.BlockrealmGameAccountBridge.update('','');f.context.window.blockrealmReloadGame();assert.equal(f.context.window.BlockrealmGameAccountBridge.take(),'');checks++;
 f=fixture({ok:false,error:'invalid_credentials'});n=f.nodes;n.get('#username').value='player_01';n.get('#password').value='wrong-test-password';
 await n.get('#account-form').handlers.submit({preventDefault(){}});assert.ok(n.get('#status').textContent.includes('ไม่ถูกต้อง'));assert.equal(n.get('#game-host').child,undefined);checks+=2;
 console.log(`GAME ACCOUNT WEB CHECKS: ${checks} passed`);
})();
