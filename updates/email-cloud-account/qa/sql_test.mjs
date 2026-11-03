import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const db = new PGlite();
await db.exec(`create role anon; create role authenticated;
create schema auth; create table auth.users(id uuid primary key,email_confirmed_at timestamptz);
create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
grant usage on schema auth to authenticated;
insert into auth.users values ('11111111-1111-4111-8111-111111111111',now()),('22222222-2222-4222-8222-222222222222',now()),('33333333-3333-4333-8333-333333333333',null);`);
await db.exec(await fs.readFile(new URL('../supabase_setup.sql',import.meta.url),'utf8'));
let checks=0;
async function identity(id,role='authenticated') {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);
  await db.exec(`set role ${role}`);
}
async function save(expected,payload) {
  return (await db.query('select public.save_account($1,$2::jsonb) as result',[expected,JSON.stringify(payload)])).rows[0].result;
}
async function denied(action){await assert.rejects(action);checks++;}
const empty={schema:1,slots:[null,null,null,null,null],last_slot:0};
await identity('11111111-1111-4111-8111-111111111111');
assert.deepEqual(await save(0,empty),{ok:true,revision:1});checks++;
assert.deepEqual(await save(0,empty),{ok:false,revision:1});checks++;
assert.deepEqual(await save(1,empty),{ok:true,revision:2});checks++;
await denied(()=>db.query('update public.account_saves set revision=999'));
await denied(()=>db.query('insert into public.account_saves(user_id,payload) values($1,$2)', ['22222222-2222-4222-8222-222222222222',empty]));
await identity('22222222-2222-4222-8222-222222222222');
assert.equal((await db.query('select * from public.account_saves')).rows.length,0);checks++;
assert.deepEqual(await save(0,empty),{ok:true,revision:1});checks++;
assert.equal((await db.query('select * from public.account_saves')).rows.length,1);checks++;
await identity('33333333-3333-4333-8333-333333333333');
await denied(()=>save(0,empty));
await identity('', 'anon');
await denied(()=>save(0,empty));
await denied(()=>db.query('select * from public.account_saves'));
await identity('11111111-1111-4111-8111-111111111111');
for (const invalid of [null,{},[],{...empty,slots:[]},{...empty,slots:[42,null,null,null,null]}, {...empty,last_slot:-1},{...empty,last_slot:1.5},{...empty,slots:[{},null,null,null,null]}, {...empty,junk:'x'.repeat(2100000)}]) await denied(()=>save(2,invalid));
assert.equal((await db.query('select revision from public.account_saves')).rows[0].revision,2);checks++;
await db.close();
console.log(`SQL SECURITY CHECKS: ${checks} passed`);
