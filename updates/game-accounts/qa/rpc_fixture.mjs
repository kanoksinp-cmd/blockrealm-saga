import http from 'node:http';
import fs from 'node:fs/promises';
import {PGlite} from '@electric-sql/pglite';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
const db=new PGlite({extensions:{pgcrypto}});
await db.exec('create role anon;create role authenticated;');
await db.exec(await fs.readFile(new URL('../game_accounts.sql',import.meta.url),'utf8'));
let offline=false,delay=false;
const args={game_register:['p_username','p_password'],game_sign_in:['p_username','p_password'],game_whoami:['p_session_token'],game_read_save:['p_session_token'],game_write_save:['p_session_token','p_expected_revision','p_payload'],game_sign_out:['p_session_token']};
const server=http.createServer(async(req,res)=>{
 let raw='';for await(const part of req)raw+=part;
 let body;try{body=JSON.parse(raw||'{}')}catch{res.writeHead(400);return res.end('{}')}
 const path=new URL(req.url,'http://127.0.0.1').pathname;
 const send=(code,data)=>{res.writeHead(code,{'Content-Type':'application/json'});res.end(JSON.stringify(data))};
 if(path==='/test/offline'){offline=!!body.fail;return send(200,{ok:true})}
 if(path==='/test/delay'){delay=true;return send(200,{ok:true})}
 if(path==='/test/advance'){await db.query('update game_private.saves set revision=revision+1 where account_id=(select id from game_private.accounts where username=$1)',[body.username]);return send(200,{ok:true})}
 if(offline)return send(503,{});
 if(req.headers.apikey!=='sb_publishable_localtest')return send(401,{});
 const method=path.split('/').pop();if(!args[method])return send(404,{});
 try{
  const parameters=args[method].map(name=>name==='p_payload'?JSON.stringify(body[name]):body[name]);
  const reply=await db.transaction(async tx=>{await tx.exec('set local role anon');return tx.query(`select public.${method}(${parameters.map((_,i)=>'$'+(i+1)).join(',')}) as result`,parameters)});
  if(delay&&method==='game_write_save'){delay=false;return setTimeout(()=>send(200,reply.rows[0].result),150)}
  send(200,reply.rows[0].result);
 }catch(_){send(500,{error:'fixture_error'})}
});
server.listen(8879,'127.0.0.1',()=>console.log('REAL_DATABASE_RPC_FIXTURE_READY'));
