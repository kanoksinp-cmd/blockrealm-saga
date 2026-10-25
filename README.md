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
