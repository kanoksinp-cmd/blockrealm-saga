from pathlib import Path
root=Path(__file__).parent
source=Path('C:/Users/Guide/Documents/blockrealm-saga-clone/play/index.js').read_text(encoding='utf-8')
old='static addAt(index){const newBus=GodotAudio.Bus.create();if(index!==newBus.getId())'
new='static addAt(index){const newBus=GodotAudio.Bus.create();if(index>=0&&index!==newBus.getId())'
assert source.count(old)==1
(root/'index.js').write_text(source.replace(old,new),encoding='utf-8',newline='\n')
print('Patched append-sentinel audio bus routing')
