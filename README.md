# Blockrealm Saga

RPG แฟนตาซีโลกบล็อก 3 มิติ สร้างด้วย Godot 4.7 เล่นฟรีบนเบราว์เซอร์

## โครงสร้างไฟล์

```
index.html      หน้าเว็บโปรโมท (กด "เล่นเลย" แล้วเกมจะโหลดในกรอบ)
assets/         รูป, ฟอนต์, ธงอาชีพ
play/           ไฟล์เกมจาก Godot (Project → Export → Web)
.nojekyll       ให้ GitHub Pages ส่งไฟล์ทุกไฟล์ตามเดิม
```

## อัปเดตเกม

1. ใน Godot: Project → Export → Web → Export Project (เอาติ๊ก Export With Debug ออก)
2. คัดลอกไฟล์ `index.*` ทั้งหมดจาก `export/web` มาทับในโฟลเดอร์ `play/`
3. Commit แล้ว Push ขึ้น GitHub — เว็บจะอัปเดตภายใน 1–2 นาที

## เวอร์ชัน Windows

อัปไฟล์ `.zip` ที่มี `Blockrealm Saga.exe` ไว้ใน GitHub → Releases
ปุ่ม "ดาวน์โหลดสำหรับ Windows" บนหน้าเว็บจะลิงก์ไปที่ release ล่าสุดเอง

## เล่นออนไลน์ (ทุกคนเห็นกัน + แชท)

```
server/         เซิร์ฟเวอร์ออนไลน์ (Node.js + WebSocket ที่ /ws)
render.yaml     ตั้งค่า Render สำหรับเซิร์ฟเวอร์ (ชื่อ blockrealm-saga-server)
```

- เกมจะต่อเซิร์ฟเวอร์เองเมื่อเข้าสู่โลก ผู้เล่นทุกคนเห็นตัวละคร ชื่อ เลเวล ชุด และการเดินของกันและกัน
- แชท: กด Enter แล้วพิมพ์ (มือถือแตะช่องแชทใต้กล่องข้อความ)
- มอนสเตอร์ ไอเทม และเซฟ ยังแยกของใครของมัน
- ที่อยู่เซิร์ฟเวอร์ตั้งใน `index.html` (`window.BLOCKREALM_WS`) และค่าเริ่มต้นในเกม `scripts/game/net.gd`
- ทดสอบในเครื่อง: `cd server && npm install && npm start` แล้วเปิด http://localhost:8080/
- Render แผนฟรีจะหลับหลังไม่มีคนเล่น 15 นาที คนแรกที่เข้ามาจะรอเชื่อมต่อ ~30–60 วินาที (เกมลองเชื่อมต่อใหม่ให้อัตโนมัติ)
