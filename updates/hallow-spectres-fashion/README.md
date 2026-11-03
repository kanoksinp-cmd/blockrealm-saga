# Hallow Spectres — แฟชั่นฮาโลวีน 3 ชุด (ใส่ได้ทุกอาชีพ + ค่าสถานะ) — 2026-11-04

แรงบันดาลใจจากธีมฮาโลวีนทั่วไป (ฟักทอง / โครงกระดูก / หุ่นไล่กา) ในภาพ Pinterest ที่ผู้ใช้ส่งมา
ดีไซน์ในเกมวาดใหม่ทั้งหมดด้วย BoxModel ในโค้ด ไม่ได้ลอกงานต้นฉบับของศิลปิน

| ชุด | หน้าตา | ค่าสถานะขณะสวม | สูตร (โดแรน → แฟชั่น) |
|---|---|---|---|
| Pumpkin Reaper | หมวกฟักทองแกะสลักแสงเทียน เกราะเหล็กดำขลิบถ่านแดง ผ้าคลุมสีไวน์ขาดรุ่ย | STR +3, VIT +2, ATK +12, HP สูงสุด +5% | Spirit Ember 10, Ash Cloth 8, Imp Horn 4, Boar Hide 6, 15,000 Zeny |
| Bone Oracle | หน้ากากกะโหลกเขาแกะม้วน ตาแสงวิญญาณฟ้า เสื้อคลุมน้ำเงินลายซี่โครง | INT +3, DEX +2, SP สูงสุด +10%, ฟื้น SP +15% | Shadow Shard 10, Bat Wing 8, Ash Cloth 6, Spirit Ember 4, 15,000 Zeny |
| Hollow Scarecrow | หัวกระสอบเย็บยิ้ม ตากระดุมเขียวเรือง หมวกปีกกว้างปลายงอ โค้ทปะผ้า ฟางโผล่ | AGI +3, LUK +2, FLEE +8, CRIT +3 | Living Vine 10, Wool 10, Spore Powder 6, Boar Hide 4, 15,000 Zeny |

## ใช้งาน
1. Blacksmith Doran → แท็บ "แฟชั่น" → คราฟชุด (ครั้งเดียว ปลดล็อกถาวรเฉพาะตัวละครนั้น)
2. กระเป๋า I → ปุ่ม "แฟชั่น" → เลือกชุด → สวม / ถอดแฟชั่น
ค่าสถานะบวกเฉพาะตอนสวม และหายเมื่อถอดหรือเปลี่ยนชุด อาวุธ โล่ และปีกยังแสดงตามเดิม

## Code
- `scripts/game/game_state.gd`: `FASHIONS` (jobs / bonus / recipe), `set_fashion`, `owns_fashion`,
  `fashion_allowed`, `worn_fashion`, `fashion_recipes`; bonus added in `gear_bonus()`; craft/save/load
  generalised (unknown unlocks dropped, unowned worn fashion cleared). Forest Mage unchanged (Mage only, no stats).
- `scripts/voxel/spectre_fashion.gd` (new): voxel models, attached to the existing rig pivots.
- `scripts/voxel/avatar.gd`: calls it from `assemble()`. `scripts/game/items.gd`: 3 recipe items with bonus text.
- `scripts/ui/ro_ui.gd`: inventory "แฟชั่น" chooser + detail dialog; smithy fashion tab lists all fashions.
Builds on updates/web-load-audio (includes all earlier account fixes). Godot 4.7.2; scripts spliced into play/index.pck.

## Validation
- `qa/fashion_test.gd`: 139 checks, 0 failures — all 6 jobs: craft rules, payment, no double craft,
  tampered recipe rejected, wear/switch/unequip stat changes, save/load, model parts, load sanitising.
- `qa/fashion_ui_test.gd`: inventory menu, locked/owned detail, wearing from the button, smithy tab.
- `hallow_spectres_preview.png`: rendered by the game (OpenGL), left = no fashion.
- Startup log, account login/load tests and main scene load time unchanged.
