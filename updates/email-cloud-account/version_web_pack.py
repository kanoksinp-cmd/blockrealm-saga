from pathlib import Path
import re,json,hashlib,sys
folder=Path(sys.argv[1]);pack=folder/'index.pck';page=folder/'index.html'
s=page.read_text(encoding='utf-8-sig');match=re.search(r'const GODOT_CONFIG = (\{[^\n]+\});',s)
assert match,'Godot web configuration not found'
cfg=json.loads(match.group(1));name='index.pck?build='+hashlib.sha256(pack.read_bytes()).hexdigest()[:16]
cfg['mainPack']=name;cfg['fileSizes'][name]=pack.stat().st_size
s=s[:match.start(1)]+json.dumps(cfg,separators=(',',':'))+s[match.end(1):]
page.write_text(s,encoding='utf8');print('Versioned game pack:',name)
