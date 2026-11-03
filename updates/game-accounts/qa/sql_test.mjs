import {PGlite} from '@electric-sql/pglite';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const db=new PGlite({extensions:{pgcrypto}});
await db.exec('create role anon;create role authenticated;');
await db.exec(await fs.readFile(new URL('../game_accounts.sql',import.meta.url),'utf8'));
let checks=0;
async function rpc(name,args){return (await db.transaction(async tx=>{
 await tx.exec('set local role anon');
 return tx.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) as result`,args);
})).rows[0].result;}
const empty={schema:1,slots:[null,null,null,null,null],last_slot:0};
const alice=await rpc('game_register',['Alice_01','test-only-password-123']);
assert.equal(alice.ok,true);assert.equal(alice.user.username,'alice_01');assert.match(alice.session_token,/^[a-f0-9]{64}$/);checks+=3;
const hash=(await db.query("select password_hash from game_private.accounts where username='alice_01'")).rows[0].password_hash;
assert.match(hash,/^\$2[aby]\$10\$/);assert.notEqual(hash,'test-only-password-123');checks+=2;
assert.equal((await rpc('game_register',['ALICE_01','different-password'])).error,'username_taken');checks++;
assert.equal((await rpc('game_register',['../bad','test-only-password'])).error,'invalid_username');checks++;
assert.equal((await rpc('game_register',['bad_password','x'.repeat(73)])).error,'invalid_password');checks++;
const second=await rpc('game_sign_in',['ALICE_01','test-only-password-123']);
assert.equal(second.user.id,alice.user.id);assert.notEqual(second.session_token,alice.session_token);checks+=2;
assert.equal((await rpc('game_sign_in',['alice_01','wrong-password'])).error,'invalid_credentials');checks++;
assert.equal((await rpc('game_sign_in',['does_not_exist','wrong-password'])).error,'invalid_credentials');checks++;
const bob=await rpc('game_register',['bob_02','another-test-password']);assert.equal(bob.ok,true);checks++;
const payload=structuredClone(empty);payload.slots[0]={player_name:'นักผจญภัย',inventory:{potion_red:5},save_point:[1,.1,2]};
assert.deepEqual(await rpc('game_write_save',[alice.session_token,0,payload]),{ok:true,revision:1});checks++;
assert.equal((await rpc('game_read_save',[second.session_token])).payload.slots[0].player_name,'นักผจญภัย');checks++;
assert.equal((await rpc('game_read_save',[bob.session_token])).payload.slots[0],null);checks++;
const stale=await rpc('game_write_save',[alice.session_token,0,empty]);assert.equal(stale.error,'conflict');assert.equal(stale.revision,1);checks+=2;
assert.equal((await rpc('game_read_save',['0'.repeat(64)])).error,'session_expired');checks++;
assert.equal((await rpc('game_write_save',['0'.repeat(64),0,payload])).error,'session_expired');checks++;
for(const broken of [null,{},[],{...empty,slots:[]},{...empty,last_slot:1.5},{...empty,slots:[{},null,null,null,null]}, {...empty,junk:'x'.repeat(2100000)}]){
 assert.equal((await rpc('game_write_save',[alice.session_token,1,broken])).error,'invalid_save');checks++;
}
assert.equal((await rpc('game_read_save',[alice.session_token])).revision,1);checks++;
await rpc('game_sign_out',[alice.session_token]);assert.equal((await rpc('game_read_save',[alice.session_token])).error,'session_expired');checks++;
assert.equal((await rpc('game_read_save',[second.session_token])).ok,true);checks++;
await db.query("update game_private.sessions set expires_at=now()-interval '1 second' where account_id=$1",[bob.user.id]);
assert.equal((await rpc('game_whoami',[bob.session_token])).error,'session_expired');checks++;
for(const role of ['anon','authenticated']){
 await assert.rejects(()=>db.transaction(async tx=>{await tx.exec(`set local role ${role}`);return tx.query('select * from game_private.accounts')}));checks++;
 await assert.rejects(()=>db.transaction(async tx=>{await tx.exec(`set local role ${role}`);return tx.query('select * from game_private.saves')}));checks++;
}
await assert.rejects(()=>db.transaction(async tx=>{await tx.exec('set local role anon');return tx.query("select game_private.issue_session($1)",[second.user.id])}));checks++;
await db.exec("delete from game_private.rate_limits where bucket like 'login:user:%'");
for(let i=0;i<8;i++)assert.equal((await rpc('game_sign_in',['alice_01','wrong-password'])).error,'invalid_credentials');
assert.equal((await rpc('game_sign_in',['alice_01','test-only-password-123'])).error,'rate_limited');checks++;
assert.equal((await db.query("select attempts from game_private.rate_limits where bucket='login:user:alice_01'")).rows[0].attempts,9);checks++;
assert.equal((await db.query('select count(*)::int as n from game_private.accounts')).rows[0].n,2);checks++;
await db.close();console.log(`GAME ACCOUNT DATABASE CHECKS: ${checks} passed`);
