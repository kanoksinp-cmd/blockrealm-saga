const fs=require('fs'),vm=require('vm'),assert=require('assert');
const source=fs.readFileSync('Mobile_Landscape_Polish/web/assets/landscape-display-20261116.js','utf8');
function fixture(mobile){
 const nodes=[],events={},screenEvents={};
 const button={addEventListener(n,f){this[n]=f}};
 function element(){return {classList:{toggle(n,v){this[n]=v}},append(){},querySelector(){return button}}}
 const doc={head:{append(){}},body:{append(x){nodes.push(x)}},createElement:element,documentElement:{requestFullscreen:async()=>{}}};
 const win={addEventListener(n,f){events[n]=f}};const screen={width:390,height:844,orientation:{type:'portrait-primary',addEventListener(n,f){screenEvents[n]=f},async lock(value){assert.equal(value,'landscape');this.type='landscape-primary'}}};
 const context={window:win,parent:win,screen,document:doc,matchMedia:()=>({matches:mobile}),navigator:{userAgent:mobile?'iPhone':'Desktop'}};
 vm.runInNewContext(source,context);return {nodes,events,screenEvents,screen,button};
}
(async()=>{
 let f=fixture(true);assert.equal(f.nodes[0].classList.show,true,'portrait prompts rotation');
 f.screen.orientation.type='landscape-primary';f.screenEvents.change();assert.equal(f.nodes[0].classList.show,false,'landscape hides prompt');
 f.screen.orientation.type='portrait-primary';await f.button.click();assert.equal(f.nodes[0].classList.show,false,'fullscreen action requests landscape');
 f=fixture(true);f.screen.orientation.lock=async()=>{throw Error('unsupported')};await f.button.click();assert.equal(f.nodes[0].classList.show,true,'unsupported lock keeps manual rotation prompt');
 assert.equal(fixture(false).nodes.length,0,'desktop receives no overlay');
 console.log('LANDSCAPE WEB PASS');
})().catch(e=>{console.error(e);process.exitCode=1});
