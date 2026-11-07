const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),{EventEmitter}=require('node:events');
const source=fs.readFileSync('C:/Users/Guide/Documents/blockrealm-saga-clone/server/server.js','utf8');
class FakeServer extends EventEmitter{listen(){}}
class FakeWSS extends EventEmitter{}
class Client extends EventEmitter{constructor(){super();this.readyState=1;this.sent=[]}send(s){this.sent.push(JSON.parse(s))}close(){this.readyState=3}message(m){this.emit('message',Buffer.from(JSON.stringify(m)),false)}}
const ctx={require:n=>n==='http'?{createServer:()=>new FakeServer()}:n==='ws'?{WebSocketServer:FakeWSS}:require(n),__dirname:'C:/Users/Guide/Documents/blockrealm-saga-clone/server',process:{env:{}},setInterval(){},console:{log(){}},Buffer};
vm.runInNewContext(source+'\nglobalThis.audit={wss,players,parties};',ctx);
const {wss}=ctx.audit,a=new Client(),b=new Client();wss.emit('connection',a,{});wss.emit('connection',b,{});
a.message({t:'hello',name:'Audit A',lv:1});b.message({t:'hello',name:'Audit B',lv:1});
const aid=a.sent.find(m=>m.t==='welcome').id,bid=b.sent.find(m=>m.t==='welcome').id;
assert.ok(b.sent.find(m=>m.t==='welcome').players.some(p=>p.id===aid));
a.message({t:'chat',msg:'Audit chat'});assert.ok(b.sent.some(m=>m.t==='chat'&&m.msg==='Audit chat'));
a.message({t:'invite',to:bid});assert.ok(b.sent.some(m=>m.t==='invite'));
b.message({t:'invite_reply',to:aid,ok:true});assert.equal(b.sent.findLast(m=>m.t==='party').members.length,2);
a.message({t:'party_kick',to:bid});assert.equal(b.sent.findLast(m=>m.t==='party').id,0);
console.log('PASS_ONLINE local relay: presence, chat, party invitation, joining and leader kick');
// Local-only validation probe: no production WebSocket messages are sent.
a.message({t:'gift',to:bid,item:'gold_ore',n:9999});
assert.ok(b.sent.some(m=>m.t==='gift'&&m.n===9999));
console.log('OPEN_HIGH server accepts gift amounts without account or inventory ownership validation (local reproduction)');
