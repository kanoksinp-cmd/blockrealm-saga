from pathlib import Path
import hashlib
import struct

root = Path(__file__).parent
original = Path('C:/Users/Guide/Documents/blockrealm-saga-clone/play/index.pck').read_bytes()
base, directory = struct.unpack_from('<QQ', original, 24)
assert original[:8] == b'GDPC\x04\0\0\0'
count, = struct.unpack_from('<I', original, directory)
cursor = directory + 4
files = {}
for _ in range(count):
    length, = struct.unpack_from('<I', original, cursor)
    cursor += 4
    path = original[cursor:cursor + length].rstrip(b'\0').decode()
    cursor += length
    offset, size, checksum, flags = struct.unpack_from('<QQ16sI', original, cursor)
    cursor += 36
    data = original[base + offset:base + offset + size]
    assert not flags and hashlib.md5(data).digest() == checksum, path
    files[path] = data
assert cursor == len(original)
for path in (root / 'source/scripts').rglob('*.gd'):
    name = path.relative_to(root / 'source').as_posix()
    files.pop(name + '.remap', None)
    files.pop(name + 'c', None)
    files[name] = path.read_bytes()
for path in (root / 'resources').rglob('*'):
    if path.is_file():
        name = path.relative_to(root / 'resources').as_posix()
        files.pop(name + '.remap', None)
        files[name] = path.read_bytes()
pack = bytearray(original[:base])
entries = bytearray(struct.pack('<I', len(files)))
for path, data in sorted(files.items()):
    pack.extend(bytes(-len(pack) % 16))
    offset = len(pack) - base
    pack.extend(data)
    name = path.encode()
    name += bytes(-len(name) % 4)
    entries.extend(struct.pack('<I', len(name)) + name)
    entries.extend(struct.pack('<QQ16sI', offset, len(data), hashlib.md5(data).digest(), 0))
pack.extend(bytes(-len(pack) % 16))
struct.pack_into('<Q', pack, 32, len(pack))
pack.extend(entries)
(root / 'index.pck').write_bytes(pack)
print(len(pack), hashlib.sha256(pack).hexdigest()[:16])
