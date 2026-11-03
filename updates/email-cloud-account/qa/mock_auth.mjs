// Local-only protocol fixture. No real email, account or production data is used.
import http from 'node:http';
let row=null, fail=false, stale=false, delayed=false;
const id='11111111-1111-4111-8111-111111111111';
const session={access_token:'local-test-token',refresh_token:'local-test-refresh',expires_in:3600,user:{id,email:'player@example.test'}};
const server=http.createServer(async(req,res)=>{
  let text='';for await(const chunk of req)text+=chunk;
  let body={};try{body=JSON.parse(text||'{}')}catch{}
  const url=new URL(req.url,'http://127.0.0.1');
  const send=(status,data)=>{res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(data))};
  if(url.pathname==='/test/reset'){row=null;fail=false;stale=false;return send(200,{ok:true})}
  if(url.pathname==='/test/offline'){fail=!!body.fail;return send(200,{ok:true})}
  if(url.pathname==='/test/advance'){if(row)row.revision++;return send(200,{ok:true})}
  if(url.pathname==='/test/malformed'){stale=true;return send(200,{ok:true})}
  if(url.pathname==='/test/delay'){delayed=true;return send(200,{ok:true})}
  if(fail)return send(503,{error:'offline'});
  if(req.headers.apikey!=='local-test-key')return send(401,{error:'apikey'});
  if(url.pathname==='/auth/v1/otp')return send(200,{});
  if(url.pathname==='/auth/v1/verify')return (body.token==='123456'||body.token_hash==='a'.repeat(64))?send(200,session):send(403,{error:'invalid otp'});
  if(url.pathname==='/auth/v1/token')return body.refresh_token===session.refresh_token?send(200,session):send(401,{});
  if(req.headers.authorization!=='Bearer '+session.access_token)return send(401,{error:'token'});
  if(url.pathname==='/auth/v1/logout')return send(200,{});
  if(url.pathname==='/rest/v1/account_saves')return send(200,stale?[{revision:100,payload:{slots:'broken'}}]:(row?[row]:[]));
  if(url.pathname==='/rest/v1/rpc/save_account'){
    if(body.expected_revision!==(row?.revision||0))return send(200,{ok:false,revision:row?.revision||0});
    row={revision:(row?.revision||0)+1,payload:body.new_payload};
    const result={ok:true,revision:row.revision};
    if(delayed){delayed=false;return setTimeout(()=>send(200,result),150)}
    return send(200,result);
  }
  send(404,{});
});
server.listen(8879,'127.0.0.1',()=>console.log('LOCAL_AUTH_FIXTURE_READY'));
