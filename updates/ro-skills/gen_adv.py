import re
# job:branch:tier -> (strike, guard, mastery), each (name, desc, thai_name, thai_desc[, bonus])
SPEC = {
 "swordsman:a:4": (("Ignition Break", "A burst of rune fire that hits every enemy around you.", "อิกนิชั่นเบรก", "ระเบิดพลังรูนเพลิงใส่ศัตรูทุกตัวรอบตัว"),
   ("Stonehard Skin", "Rune of stone: DEF and max HP up.", "สโตนฮาร์ดสกิน", "รูนหิน: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 2, "MAXHP_PCT": 2}'),
   ("Rune Mastery", "Know your runes: HIT and SP regen up.", "รูนมาสเตอรี", "เข้าใจพลังรูน: เพิ่ม HIT และการฟื้น SP", '{"HIT": 2, "SPREGEN": 5}')),
 "swordsman:a:5": (("Storm Slash", "A storm of sword slashes all around you.", "สตอร์มสแลช", "ฟาดดาบเป็นพายุรอบตัว โดนศัตรูทุกตัว"),
   ("Vigor", "Dragon blood boils: ATK and max HP up.", "วิกอร์", "เลือดมังกรเดือด: เพิ่ม ATK และ HP สูงสุด", '{"ATK_PCT": 2, "MAXHP_PCT": 2}'),
   ("Two-Handed Weapon Mastery", "Masters of the great sword: ATK and HIT up.", "ความชำนาญอาวุธสองมือ", "เชี่ยวชาญอาวุธสองมือ: เพิ่ม ATK และ HIT", '{"ATK": 3, "HIT": 2}')),
 "swordsman:b:4": (("Earth Drive", "Smash your shield into the ground: holy shockwave around you.", "เอิร์ธไดรฟ์", "กระแทกโล่ลงพื้น เกิดคลื่นศักดิ์สิทธิ์รอบตัว"),
   ("Prestige", "A royal guard's pride: DEF and max HP up.", "เพรสทีจ", "ศักดิ์ศรีองครักษ์: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 3, "MAXHP_PCT": 2}'),
   ("Force of Vanguard", "Stand in front: max HP and HP regen up.", "ฟอร์สออฟแวนการ์ด", "ยืนแนวหน้า: เพิ่ม HP สูงสุดและการฟื้น HP", '{"MAXHP_PCT": 2, "HPREGEN": 5}')),
 "swordsman:b:5": (("Grand Judgement", "Swing your spear in a wide holy arc around you.", "แกรนด์จัดจ์เมนต์", "กวาดหอกเป็นวงศักดิ์สิทธิ์รอบตัว"),
   ("Guard Stance", "Plant your shield: DEF way up.", "การ์ดสแตนซ์", "ตั้งโล่มั่น: เพิ่ม DEF มาก", '{"DEF": 4, "MAXHP_PCT": 1}'),
   ("Shield Mastery", "Shield training: DEF and HIT up.", "ความชำนาญโล่", "ฝึกใช้โล่: เพิ่ม DEF และ HIT", '{"DEF": 1, "HIT": 2}')),
 "archer:a:4": (("Arrow Storm", "A storm of arrows on the target area.", "แอร์โรว์สตอร์ม", "ยิงลูกธนูเป็นพายุลงพื้นที่เป้าหมาย"),
   ("Camouflage", "Blend into the field: FLEE and CRIT up.", "คาโมฟลาจ", "พรางตัว: เพิ่ม FLEE และ CRIT", '{"FLEE": 3, "CRIT": 1}'),
   ("Trap Research", "Study traps: max SP and SP regen up.", "แทร็ปรีเสิร์ช", "ศึกษากับดัก: เพิ่ม SP สูงสุดและการฟื้น SP", '{"MAXSP_PCT": 2, "SPREGEN": 5}')),
 "archer:a:5": (("Gale Storm", "A whirlwind of arrows tears through an area.", "เกลสตอร์ม", "ลูกธนูหมุนเป็นพายุลมฉีกพื้นที่"),
   ("Wind Sign", "The wind is with you: ASPD and FLEE up.", "วินด์ไซน์", "ลมอยู่ข้างเรา: เพิ่มความเร็วโจมตีและ FLEE", '{"ASPD": 2, "FLEE": 2}'),
   ("Hawk Mastery", "Train your hawk: DEX and HIT up.", "ฮอว์กมาสเตอรี", "ฝึกเหยี่ยว: เพิ่ม DEX และ HIT", '{"DEX": 1, "HIT": 2}')),
 "archer:b:4": (("Severe Rainstorm", "A downpour of arrows on the target area.", "ซีเวียร์เรนสตอร์ม", "ห่าฝนลูกธนูลงพื้นที่เป้าหมาย"),
   ("Echo Song", "A song that echoes off your armour: DEF up.", "เอคโค่ซอง", "เพลงสะท้อนเกราะ: เพิ่ม DEF", '{"DEF": 3, "MAXHP_PCT": 1}'),
   ("Song of Mana", "Your voice restores mana: SP regen and max SP up.", "ซองออฟมานา", "เสียงเพลงคืนมานา: เพิ่มการฟื้น SP และ SP สูงสุด", '{"SPREGEN": 6, "MAXSP_PCT": 1}')),
 "archer:b:5": (("Rose Blossom", "Arrows bloom like roses over an area.", "โรสบลอสซัม", "ลูกธนูผลิบานดั่งกุหลาบทั่วพื้นที่"),
   ("Mystic Symphony", "A soaring symphony: DEF and max HP up.", "มิสติกซิมโฟนี", "ซิมโฟนีลึกลับ: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 2, "MAXHP_PCT": 2}'),
   ("Stage Manner", "Perform like a star: DEX and HIT up.", "สเตจแมนเนอร์", "แสดงอย่างซูเปอร์สตาร์: เพิ่ม DEX และ HIT", '{"DEX": 1, "HIT": 2}')),
 "mage:a:4": (("Comet", "Pull a blazing comet down on the target area.", "โคเม็ท", "ดึงดาวหางลุกไฟลงพื้นที่เป้าหมาย"),
   ("Recognized Spell", "Every spell hits at full power: ATK up.", "เรคคอกไนซ์สเปล", "เวททุกบทแรงเต็มที่: เพิ่ม ATK", '{"ATK_PCT": 2, "DEF": 1}'),
   ("Radius", "Shorter casts and wider spells.", "เรเดียส", "ร่ายเร็วขึ้นและเวทกว้างขึ้น", '{"CAST": 2, "SPREGEN": 3}')),
 "mage:a:5": (("Rain of Crystal", "Shards of crystal rain on an area.", "เรนออฟคริสตัล", "เศษคริสตัลโปรยลงพื้นที่"),
   ("Climax", "Push your magic to its peak: ATK and cast speed up.", "ไคลแมกซ์", "เวทถึงจุดสูงสุด: เพิ่ม ATK และร่ายเร็วขึ้น", '{"ATK_PCT": 2, "CAST": 2}'),
   ("Spell Enchanting", "Magic soaks into your gear: INT and SP regen up.", "สเปลเอนแชนติ้ง", "เวทซึมเข้าอุปกรณ์: เพิ่ม INT และการฟื้น SP", '{"INT": 1, "SPREGEN": 5}')),
 "mage:b:4": (("Psychic Wave", "Waves of mind force crash over an area.", "ไซคิกเวฟ", "คลื่นพลังจิตซัดใส่พื้นที่"),
   ("Striking", "Charge your weapon with elemental power: ATK and DEF up.", "สไตรค์กิ้ง", "อัดพลังธาตุใส่อาวุธ: เพิ่ม ATK และ DEF", '{"ATK": 3, "DEF": 1}'),
   ("Elemental Analysis", "Read the elements around you: SP regen and max SP up.", "เอเลเมนทัลอนาไลซิส", "อ่านธาตุรอบตัว: เพิ่มการฟื้น SP และ SP สูงสุด", '{"SPREGEN": 6, "MAXSP_PCT": 1}')),
 "mage:b:5": (("Elemental Buster", "Your elemental spirits blast an area.", "เอเลเมนทัลบัสเตอร์", "วิญญาณธาตุระเบิดพื้นที่"),
   ("Elemental Veil", "A veil of spirits: DEF and max HP up.", "เอเลเมนทัลเวล", "ม่านวิญญาณธาตุ: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 2, "MAXHP_PCT": 2}'),
   ("Spirit Mastery", "Bond with your spirits: INT and SP regen up.", "สปิริตมาสเตอรี", "ผูกพันกับวิญญาณ: เพิ่ม INT และการฟื้น SP", '{"INT": 1, "SPREGEN": 5}')),
 "acolyte:a:4": (("Adoramus", "A spear of holy light strikes an area and blinds.", "อโดรามุส", "หอกแสงศักดิ์สิทธิ์ทิ่มพื้นที่และทำให้ตาบอด"),
   ("Praefatio", "A holy barrier for you and your party: DEF and max HP up.", "พรีฟาติโอ", "บาเรียศักดิ์สิทธิ์: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 2, "MAXHP_PCT": 2}'),
   ("Clementia", "Mercy of the gods: healing and SP regen up.", "เคลเมนเทีย", "เมตตาแห่งเทพ: เพิ่มการรักษาและการฟื้น SP", '{"HEAL_PCT": 3, "SPREGEN": 5}')),
 "acolyte:a:5": (("Pneumaticus Procella", "A storm of holy wind over an area.", "นิวแมติคัสโพรเซลลา", "พายุลมศักดิ์สิทธิ์ทั่วพื้นที่"),
   ("Presens Acies", "Sharpened senses: DEF and CRIT up.", "พรีเซนส์อาซีส", "ประสาทสัมผัสเฉียบคม: เพิ่ม DEF และ CRIT", '{"DEF": 2, "CRIT": 1}'),
   ("Mace Book Mastery", "Fight with mace and book: ATK and HIT up.", "ความชำนาญคทาและคัมภีร์", "สู้ด้วยคทาและคัมภีร์: เพิ่ม ATK และ HIT", '{"ATK": 3, "HIT": 2}')),
 "acolyte:b:4": (("Rampage Blast", "Release your spheres in a blast over an area.", "แรมเพจบลาสต์", "ปล่อยลูกพลังระเบิดใส่พื้นที่"),
   ("Lightning Walk", "Step aside like lightning: FLEE and DEF up.", "ไลท์นิ่งวอล์ก", "หลบเร็วดั่งสายฟ้า: เพิ่ม FLEE และ DEF", '{"FLEE": 3, "DEF": 1}'),
   ("Raising Dragon", "The dragon within: max HP and SP regen up.", "เรซซิ่งดราก้อน", "มังกรในกาย: เพิ่ม HP สูงสุดและการฟื้น SP", '{"MAXHP_PCT": 2, "SPREGEN": 5}')),
 "acolyte:b:5": (("Massive Flame Blaster", "Holy flames explode across an area.", "แมสซีฟเฟลมบลาสเตอร์", "เปลวไฟศักดิ์สิทธิ์ระเบิดทั่วพื้นที่"),
   ("Second Faith", "Faith made solid: DEF and max HP up.", "เซคันด์เฟธ", "ศรัทธาเป็นเกราะ: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 2, "MAXHP_PCT": 2}'),
   ("Will of Faith", "Fists of the faithful: ATK and HIT up.", "วิลออฟเฟธ", "หมัดแห่งศรัทธา: เพิ่ม ATK และ HIT", '{"ATK": 3, "HIT": 2}')),
 "merchant:a:4": (("Axe Tornado", "Spin your axe in a tornado around you.", "แอกซ์ทอร์นาโด", "หมุนขวานเป็นพายุรอบตัว"),
   ("Mainframe Restructure", "Reinforce your mado gear: DEF and max HP up.", "เมนเฟรมรีสตรัคเจอร์", "เสริมโครงมาโดเกียร์: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 3, "MAXHP_PCT": 1}'),
   ("Madogear License", "Pilot like a pro: HIT and move speed up.", "ใบขับขี่มาโดเกียร์", "ขับเก่ง: เพิ่ม HIT และความเร็วเดิน", '{"HIT": 2, "MOVE": 1}')),
 "merchant:a:5": (("Axe Stomp", "Stomp the ground with your axe: shockwave around you.", "แอกซ์สตอมป์", "กระทืบขวานลงพื้น เกิดคลื่นกระแทกรอบตัว"),
   ("Two Axe Defending", "Guard with two axes: DEF and FLEE up.", "ทูแอกซ์ดีเฟนดิ้ง", "ป้องกันด้วยขวานคู่: เพิ่ม DEF และ FLEE", '{"DEF": 2, "FLEE": 2}'),
   ("Two-Axe Mastery", "Master the axe: ATK and HIT up.", "ความชำนาญขวานคู่", "เชี่ยวชาญขวาน: เพิ่ม ATK และ HIT", '{"ATK": 3, "HIT": 2}')),
 "merchant:b:4": (("Cart Tornado", "Swing your cart in a full circle.", "คาร์ททอร์นาโด", "เหวี่ยงรถเข็นหมุนรอบตัว"),
   ("Cart Boost", "Push your cart hard: move and attack speed up.", "คาร์ทบูสต์", "เข็นรถเต็มแรง: เพิ่มความเร็วเดินและโจมตี", '{"MOVE": 2, "ASPD": 1}'),
   ("Research Report", "Notes from the lab: max HP and SP regen up.", "รีเสิร์ชรีพอร์ต", "บันทึกจากห้องแล็บ: เพิ่ม HP สูงสุดและการฟื้น SP", '{"MAXHP_PCT": 1, "SPREGEN": 5}')),
 "merchant:b:5": (("Explosive Powder", "A blast of alchemical powder around you.", "เอ็กซ์โพลซีฟพาวเดอร์", "ผงเล่นแร่ระเบิดรอบตัว"),
   ("Mayhemic Thorns", "A barrier of thorny vines: DEF up.", "เมย์เฮมมิกธอร์นส์", "บาเรียเถาหนาม: เพิ่ม DEF", '{"DEF": 3, "MAXHP_PCT": 1}'),
   ("Bionic Pharmacy", "Brew better medicine: healing and HP regen up.", "ไบโอนิกฟาร์มาซี", "ปรุงยาได้ดีขึ้น: เพิ่มการรักษาและการฟื้น HP", '{"HEAL_PCT": 3, "HPREGEN": 5}')),
 "thief:a:4": (("Counter Slash", "Whirl your blades through every enemy nearby.", "เคาน์เตอร์สแลช", "หมุนใบมีดฟันศัตรูรอบตัว"),
   ("Hallucination Walk", "Leave phantoms behind: FLEE way up.", "ฮาลูซิเนชั่นวอล์ก", "ทิ้งเงาลวงตา: เพิ่ม FLEE มาก", '{"FLEE": 4, "DEF": 1}'),
   ("Research New Poison", "Brew new poisons: ATK and poison chance up.", "รีเสิร์ชนิวพอยซัน", "คิดค้นยาพิษใหม่: เพิ่ม ATK และโอกาสติดพิษ", '{"ATK": 2, "POISON": 1}')),
 "thief:a:5": (("Impact Crater", "Spin into the ground and blast a crater around you.", "อิมแพกต์เครเตอร์", "หมุนตัวกระแทกพื้นจนเป็นหลุมรอบตัว"),
   ("Shadow Exceed", "Wrap yourself in shadow: FLEE and CRIT up.", "แชโดว์เอ็กซีด", "ห่อหุ้มด้วยเงา: เพิ่ม FLEE และ CRIT", '{"FLEE": 3, "CRIT": 2}'),
   ("Dagger and Throwing Mastery", "Knives in hand and in the air: ATK and CRIT up.", "ความชำนาญมีดและอาวุธขว้าง", "มีดในมือและมีดขว้าง: เพิ่ม ATK และ CRIT", '{"ATK": 3, "CRIT": 1}')),
 "thief:b:4": (("Fatal Menace", "Slash everything around you and vanish.", "เฟทัลเมนาซ", "ฟันทุกสิ่งรอบตัวแล้วหายตัว"),
   ("Shadow Form", "Let your shadow take the hits: FLEE and DEF up.", "แชโดว์ฟอร์ม", "ให้เงารับแทน: เพิ่ม FLEE และ DEF", '{"FLEE": 3, "DEF": 1}'),
   ("Auto Shadow Spell", "Copied spells fire on their own: CRIT and SP regen up.", "ออโต้แชโดว์สเปล", "เวทที่ก๊อปมาร่ายเอง: เพิ่ม CRIT และการฟื้น SP", '{"CRIT": 1, "SPREGEN": 5}')),
 "thief:b:5": (("Abyss Square", "Open the abyss under everyone around you.", "อะบิสสแควร์", "เปิดหุบเหวใต้ศัตรูรอบตัว"),
   ("From the Abyss", "Power from the abyss: DEF and max HP up.", "ฟรอมดิอะบิส", "พลังจากหุบเหว: เพิ่ม DEF และ HP สูงสุด", '{"DEF": 2, "MAXHP_PCT": 2}'),
   ("Abyss Mastery", "Fight like a chaser: ATK and CRIT up.", "อะบิสมาสเตอรี", "สู้แบบผู้ไล่ล่า: เพิ่ม ATK และ CRIT", '{"ATK": 3, "CRIT": 1}')),
}
src=open(__import__('os').path.join(__import__('os').path.dirname(__file__), '../career-level80/scripts/game/skill_db.gd')).read().split('\n')
adv=[l for l in src if re.match(r'\t"\w+_[ab]_[45]_(strike|guard|mastery)"', l)]
assert len(adv)==72, len(adv)
out=[]; th={}
for l in adv:
    m=re.match(r'\t"(\w+)_([ab])_([45])_(strike|guard|mastery)"', l)
    key="%s:%s:%s"%m.groups()[:3]; kind=m.group(4)
    sp=SPEC[key][["strike","guard","mastery"].index(kind)]
    l=re.sub(r'"name": "[^"]*"', '"name": "%s"'%sp[0], l)
    l=re.sub(r'"desc": "[^"]*"', '"desc": "%s"'%sp[1], l)
    if len(sp)>4: l=re.sub(r'"bonus": \{[^}]*\}', '"bonus": %s'%sp[4], l)
    if kind=="strike": l=l.replace('"color": Color(0.7, 0.8, 1.0), ', '').replace('"req": {}', '"cast0": 1.0, "cast1": 0.0, "cd": 1.0')
    if kind=="guard": l=l.replace('"time1": 3}', '"time1": 3, "cd": 1.0}')
    out.append(l); th[sp[0]]=sp[2]; th[sp[1]]=sp[3]
open('adv_table.txt','w').write('\n'.join(out)+'\n')
import json; json.dump(th, open('adv_th.json','w'), ensure_ascii=False, indent=0)
print(out[0]); print(out[1]); print(len(th))
