const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const script = readFileSync(__dirname + '/mobile-performance.js', 'utf8');
function run({ua='iPhone', touch=5, coarse=true, search='', width=844, height=390, dpr=3}={}) {
  const listeners = {};
  const ctx = {
    location: {search}, navigator: {userAgent: ua, maxTouchPoints: touch},
    innerWidth:width, innerHeight:height, devicePixelRatio:dpr,
    matchMedia: () => ({matches:coarse}), URLSearchParams, setTimeout: f=>f(), clearTimeout(){},
    addEventListener:(name,f)=>listeners[name]=f,
    document:{addEventListener:(name,f)=>listeners[name]=f}
  };
  ctx.window = ctx; ctx.parent = ctx;
  vm.runInNewContext(script,ctx);
  const config = {canvasResizePolicy:2}; const canvas = {style:{},width:300,height:150};
  ctx.BlockrealmMobileProfile.configure(config,canvas);
  return {ctx,config,canvas,listeners};
}
let r = run();
assert.equal(r.config.canvasResizePolicy,0);
assert.equal(r.canvas.width,1055); assert.equal(r.canvas.height,488);
assert.equal(r.canvas.style.width,'844px');
assert.ok(r.canvas.width*r.canvas.height < (844*390*9)*0.18);
r.ctx.innerWidth=390; r.ctx.innerHeight=844; r.listeners.resize();
assert.equal(r.canvas.width,488); assert.equal(r.canvas.height,1055);
r = run({width:2560,height:1600});
assert.equal(r.canvas.width,1280); assert.equal(r.canvas.height,800);
assert.equal(run({ua:'Macintosh',touch:5,coarse:false}).ctx.BlockrealmMobileProfile.mobile,true);
r = run({ua:'Windows',touch:0,coarse:false});
assert.equal(r.config.canvasResizePolicy,2); assert.equal(r.canvas.width,300);
assert.equal(run({search:'?mobile=0'}).ctx.BlockrealmMobileProfile.mobile,false);
assert.equal(run({ua:'Windows',touch:0,search:'?mobile=1'}).ctx.BlockrealmMobileProfile.mobile,true);
console.log('PASS phone/tablet/desktop detection, portrait resize, pixel cap, forced modes');
