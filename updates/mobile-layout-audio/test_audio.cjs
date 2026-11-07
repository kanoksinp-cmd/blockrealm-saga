const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const enginePath=fs.existsSync(__dirname+'/index.js')?__dirname+'/index.js':path.resolve(__dirname,'../../play/index.js');
const engine=fs.readFileSync(enginePath,'utf8');
function routing(source) {
  const start=source.indexOf('Bus:class Bus{')+4;
  const end=source.indexOf(',sampleFinishedCallback:',start);
  class Gain {
    constructor(){this.gain={value:1};this.connections=new Set();}
    connect(node){this.connections.add(node);return node;}
    disconnect(){this.connections.clear();}
  }
  const audio={ctx:{createGain:()=>new Gain(),destination:new Gain()},buses:[],busSolo:null};
  audio.Bus=vm.runInNewContext('('+source.slice(start,end)+')',{GodotAudio:audio});
  audio.Bus.create();
  const master=audio.buses[0];
  for(let i=0;i<3;i++)audio.Bus.addAt(-1);
  for(let i=1;i<audio.buses.length;i++)audio.buses[i].setSend(audio.buses[0]);
  return {audio,master};
}
let {audio,master}=routing(engine.replace('if(index>=0&&index!==newBus.getId())','if(index!==newBus.getId())'));
assert.notEqual(audio.buses[0],master,'The original routing defect should be reproduced');
assert.equal(master.getOutputNode().connections.has(audio.ctx.destination),false);
({audio,master}=routing(engine));
assert.equal(audio.buses[0],master);
assert.equal(master.getSend(),null);
assert.ok(master.getOutputNode().connections.has(audio.ctx.destination));
for(const bus of audio.buses.slice(1))assert.equal(bus.getSend(),master);
audio.buses[1].mute(true);assert.equal(audio.buses[1]._muteNode.gain.value,0);
audio.buses[1].mute(false);assert.equal(audio.buses[1]._muteNode.gain.value,1);
console.log('PASS reproduced old defect; four buses now reach Master/destination; mute retained');

const listeners={},buttons=[];
class Context {
  constructor(){this.state='suspended';this.listeners={};this.resumes=0;}
  addEventListener(name,cb){this.listeners[name]=cb;}
  resume(){this.resumes++;this.state='running';this.listeners.statechange();return Promise.resolve();}
}
const document={hidden:false,readyState:'complete',documentElement:{dataset:{}},body:{appendChild:b=>buttons.push(b)},
  addEventListener:(name,cb)=>listeners[name]=cb,
  createElement:()=>({style:{},setAttribute(){},addEventListener(name,cb){this[name]=cb;}})};
const window={AudioContext:Context,addEventListener:(name,cb)=>listeners[name]=cb};
vm.runInNewContext(fs.readFileSync(__dirname+'/audio-unlock.js','utf8'),{window,document,Map,Set,Proxy,Reflect,Promise});
const context=new window.AudioContext();
assert.ok(context instanceof Context);
assert.equal(document.documentElement.dataset.brAudioState,'blocked');assert.equal(buttons[0].hidden,false);
listeners.pointerdown();
assert.equal(context.state,'running');assert.equal(context.resumes,1);
assert.equal(document.documentElement.dataset.brAudioState,'running');assert.equal(buttons[0].hidden,true);
context.state='interrupted';context.listeners.statechange();assert.equal(buttons[0].hidden,false);
listeners.visibilitychange();assert.equal(context.state,'running');assert.equal(context.resumes,2);
listeners.pointerdown();assert.equal(context.resumes,2);
console.log('PASS in-frame gesture unlock, interrupted context recovery and no repeated resume while running');
