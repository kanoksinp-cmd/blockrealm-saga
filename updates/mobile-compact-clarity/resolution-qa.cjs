const fs=require('fs'),vm=require('vm'),assert=require('assert');
const code=fs.readFileSync('Mobile_Clarity_Compact/source-web/mobile-performance.js','utf8');
function profile(w,h,dpr,mobile=true){
 const events={};const context={location:{search:mobile?'?mobile=1':'?mobile=0'},navigator:{maxTouchPoints:mobile?5:0,userAgent:mobile?'iPhone':'Desktop'},matchMedia:()=>({matches:mobile}),innerWidth:w,innerHeight:h,devicePixelRatio:dpr,URLSearchParams,Math,setTimeout:f=>{f();return 1},clearTimeout(){},addEventListener:(n,f)=>events[n]=f,document:{addEventListener:(n,f)=>events[n]=f}};context.window=context;context.parent=context;
 vm.runInNewContext(code,context);const canvas={style:{},width:0,height:0};const config={canvasResizePolicy:2};context.BlockrealmMobileProfile.configure(config,canvas);return{canvas,config,context,events};
}
for(const [w,h,dpr] of [[844,390,3],[667,320,2],[932,430,3],[1024,768,2],[1366,1024,2],[390,844,3]]){
 const p=profile(w,h,dpr);assert.equal(p.config.canvasResizePolicy,0);assert(p.canvas.width*p.canvas.height<=722000);assert(Math.max(p.canvas.width,p.canvas.height)<=1280);assert(Math.min(p.canvas.width,p.canvas.height)<=720);assert(Math.abs(p.canvas.width/p.canvas.height-w/h)<0.005);
}
const sharp=profile(844,390,3);assert(sharp.canvas.width>844&&sharp.canvas.height>390,'retina phones receive sharper canvas');
const before=[sharp.canvas.width,sharp.canvas.height];sharp.context.innerWidth=390;sharp.context.innerHeight=844;sharp.events.orientationchange();assert(sharp.canvas.width<sharp.canvas.height,'rotation updates pixel dimensions');sharp.context.innerWidth=844;sharp.context.innerHeight=390;sharp.events.resize();assert.deepEqual([sharp.canvas.width,sharp.canvas.height],before,'returning to landscape restores exact resolution');
assert.equal(profile(1280,720,2,false).config.canvasResizePolicy,2,'desktop keeps native resize policy');
console.log('MOBILE RESOLUTION PASS');

