// Creates two isolated QA game accounts, without real personal credentials.
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
const root='https://gqbqbosjszmlhebbsbmy.supabase.co/rest/v1/';
const headers={apikey:'sb_publishable_x8E8FTaCVqo631rTnsf_Eg_vSpfDKAg','Content-Type':'application/json'};
let checks=0;
async function rpc(name,body){
 const response=await fetch(root+'rpc/'+name,{method:'POST',headers,body:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
 assert.equal(response.ok,true,'RPC transport must succeed: '+name);
 return response.json();
}
assert.equal((await rpc('game_whoami',{p_session_token:'0'.repeat(64)})).error,'session_expired');checks++;
const stamp=Date.now().toString(36),userA='qa_'+stamp+'_a',userB='qa_'+stamp+'_b';
const passA=crypto.randomBytes(20).toString('base64url'),passB=crypto.randomBytes(20).toString('base64url');
const a=await rpc('game_register',{p_username:userA,p_password:passA});assert.equal(a.ok,true);checks++;
const b=await rpc('game_register',{p_username:userB,p_password:passB});assert.equal(b.ok,true);checks++;
assert.notEqual(a.user.id,b.user.id);checks++;
const second=await rpc('game_sign_in',{p_username:userA,p_password:passA});assert.equal(second.user.id,a.user.id);checks++;
assert.equal((await rpc('game_sign_in',{p_username:userA,p_password:'wrong-test-password'})).error,'invalid_credentials');checks++;
const data={schema:1,slots:[{player_name:'QA cross-device',inventory:{potion_red:5},save_point:[12,.1,-9]},null,null,null,null],last_slot:0};
assert.deepEqual(await rpc('game_write_save',{p_session_token:a.session_token,p_expected_revision:0,p_payload:data}),{ok:true,revision:1});checks++;
const restored=await rpc('game_read_save',{p_session_token:second.session_token});
assert.equal(restored.payload.slots[0].player_name,'QA cross-device');assert.equal(restored.payload.slots[0].inventory.potion_red,5);checks+=2;
assert.equal((await rpc('game_read_save',{p_session_token:b.session_token})).payload.slots[0],null);checks++;
assert.equal((await rpc('game_write_save',{p_session_token:second.session_token,p_expected_revision:0,p_payload:data})).error,'conflict');checks++;
await rpc('game_sign_out',{p_session_token:a.session_token});
assert.equal((await rpc('game_read_save',{p_session_token:a.session_token})).error,'session_expired');checks++;
assert.equal((await rpc('game_read_save',{p_session_token:second.session_token})).ok,true);checks++;
const denied=await fetch(root+'accounts?select=*',{headers:{...headers,'Accept-Profile':'game_private'}});
assert.ok([401,403,404,406].includes(denied.status));checks++;
await rpc('game_sign_out',{p_session_token:second.session_token});await rpc('game_sign_out',{p_session_token:b.session_token});
await fs.writeFile(new URL('./live_validation.json',import.meta.url),JSON.stringify({passed:checks,qa_accounts:[userA,userB],sessions_revoked:true,production_cross_session_restore:true,production_account_isolation:true},null,2));
console.log('PRODUCTION GAME ACCOUNT CHECKS: '+checks+' passed');
