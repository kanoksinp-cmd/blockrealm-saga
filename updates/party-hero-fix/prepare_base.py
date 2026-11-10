from pathlib import Path
import zstandard,struct
p=Path('Party_Hero_Fix/scripts_characters_party_member.gdc');b=p.read_bytes();n,=struct.unpack_from('<I',b,8);raw=zstandard.ZstdDecompressor().decompress(b[12:],max_output_size=n) if n else b[12:];cur=16;count,=struct.unpack_from('<I',raw)
old=bytes(x^0xb6 for x in 'PartyMember'.encode('utf-32-le'));new=bytes(x^0xb6 for x in 'PartyBaseAI'.encode('utf-32-le'))
assert len(old)==len(new);hits=[]
for i in range(count):
 ln,=struct.unpack_from('<I',raw,cur);cur+=4
 if raw[cur:cur+ln*4]==old:hits.append(cur)
 cur+=ln*4
assert len(hits)==1
at=hits[0];changed=raw[:at]+new+raw[at+len(old):];assert changed.replace(new,old)==raw
out=b[:8]+struct.pack('<I',len(changed))+zstandard.ZstdCompressor(level=3).compress(changed)
Path('Party_Hero_Fix/resources/scripts/characters/party_member_original.gdc').write_bytes(out)
print('Base AI preserved: only class identifier renamed to avoid global class collision')
