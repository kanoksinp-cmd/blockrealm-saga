from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import subprocess,os,json,time
r=Path(__file__).resolve().parent
repo=Path('C:/Users/Guide/Documents/blockrealm-saga-clone')
exe='C:/Users/Guide/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
tests=[('core',r/'core_audit.gd',0),('lifecycle',r/'lifecycle_audit.gd',0),('ui-pc',r/'ui_audit.gd',0),('ui-mobile',r/'ui_audit.gd',1),('map-gather',repo/'updates/mobile-map-auto-gather/qa.gd',1),('gold',repo/'updates/resource-travel-scroll/qa_gold.gd',1),('scroll',repo/'updates/resource-travel-scroll/qa_scroll.gd',1),('bosses',repo/'updates/verdant-rex-bosses/verdant_boss_test.gd',0),('damage',r/'damage_audit.gd',0),('arsenal',repo/'updates/forge-arsenal/arsenal_test.gd',0),('ruins-budget',repo/'updates/desert-ruins-art/qa.gd',1)]
def run(test):
 name,script,mobile=test;env=os.environ.copy();env.update(APPDATA=str(r/('runtime-suite-'+name)),BR_MOBILE=str(mobile),BR_CSS_SHORT='390');start=time.time()
 try:
  p=subprocess.run([exe,'--headless','--main-pack',str(r/'index.pck'),'--script',str(script),'--resolution','1055x488','--quit-after','5000'],env=env,capture_output=True,timeout=100)
  log=p.stdout.decode('utf-8','replace')+p.stderr.decode('utf-8','replace');code=p.returncode
 except subprocess.TimeoutExpired as e:log=(e.stdout or b'').decode('utf-8','replace')+(e.stderr or b'').decode('utf-8','replace');code=-1
 (r/(name+'-final.log')).write_text(log,encoding='utf-8')
 bad=code!=0 or 'SCRIPT ERROR' in log or '\nFAIL ' in log or 'already connected' in log
 output={'name':name,'passed':not bad,'seconds':round(time.time()-start,1),'highlights':[x for x in log.splitlines() if any(w in x for w in ['PASS','FAIL','AUDIT_','SCRIPT ERROR'])]}
 print(json.dumps(output,ensure_ascii=False),flush=True);return output
with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(run,tests))
(r/'suite_results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
raise SystemExit(0 if all(x['passed'] for x in results) else 1)
