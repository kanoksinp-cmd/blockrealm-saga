from pathlib import Path
import hashlib, json, re, shutil, sys

folder = Path(sys.argv[1])
bridge = Path(__file__).with_name('account-bridge.js')
shutil.copy2(bridge, folder / 'account-bridge.js')
page = folder / 'index.html'
text = page.read_text(encoding='utf-8-sig')
text = re.sub(r'<script src="account-bridge\.js[^\"]*"></script>\s*', '', text)
version = hashlib.sha256(bridge.read_bytes()).hexdigest()[:16]
text = text.replace('<head>', '<head>\n<script src="account-bridge.js?build=' + version + '"></script>', 1)
match = re.search(r'const GODOT_CONFIG = (\{[^\n]+\});', text)
assert match
config = json.loads(match.group(1))
pack = folder / 'index.pck'
name = 'index.pck?build=' + hashlib.sha256(pack.read_bytes()).hexdigest()[:16]
config['mainPack'] = name
config['fileSizes'] = {k:v for k,v in config['fileSizes'].items() if not k.startswith('index.pck?')}
config['fileSizes'][name] = pack.stat().st_size
text = text[:match.start(1)] + json.dumps(config,separators=(',',':')) + text[match.end(1):]
page.write_text(text,encoding='utf8')
print('Email callback and versioned game pack prepared')
