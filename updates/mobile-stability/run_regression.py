from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import subprocess,os,json
r=Path(__file__).resolve().parent;repo=Path('C:/Users/Guide/Documents/blockrealm-saga-clone')
exe='C:/Users/Guide/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
tests=[('background',r/'background_qa.gd',1),('gold',repo/'updates/resource-travel-scroll/qa_gold.gd',1),('map-gather',repo/'updates/mobile-map-auto-gather/qa.gd',1),('scroll',repo/'updates/resource-travel-scroll/qa_scroll.gd',1),('sale',repo/'updates/sell-all-item/qa.gd',1),('lifecycle',repo/'updates/game-audit-20261107/lifecycle_audit.gd',1),('ui-mobile',repo/'updates/game-audit-20261107/ui_audit.gd',1)]
def run(t):
 name,script,mobile=t;env=os.environ.copy();env.update(APPDATA=str(r/('runtime-final-'+name)),BR_MOBILE=str(mobile),BR_CSS_SHORT='390')
 try:
  p=subprocess.run([exe,'--headless','--main-pack',str(r/'index.pck'),'--script',str(script),'--resolution','844x390','--quit-after','3500'],env=env,capture_output=True,timeout=100)
  log=p.stdout.decode('utf-8','replace')+p.stderr.decode('utf-8','replace');code=p.returncode
 except subprocess.TimeoutExpired as e:log=(e.stdout or b'').decode('utf-8','replace')+(e.stderr or b'').decode('utf-8','replace');code=-1
 (r/(name+'-final.log')).write_text(log,encoding='utf-8')
 result={'test':name,'passed':code==0 and 'SCRIPT ERROR' not in log and '\nFAIL ' not in log,'result':[s for s in log.splitlines() if any(w in s for w in ['PASS','SCRIPT ERROR','FAIL','AUDIT_'])]}
 print(json.dumps(result,ensure_ascii=False),flush=True);return result
with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(run,tests))
(r/'regression_results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
raise SystemExit(0 if all(v['passed'] for v in results) else 1)
