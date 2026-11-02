class_name SideQuests
extends RefCounted
const TASKS = [{"id": "side_00", "title": "คำร้อง: ช่วยจัดการ Poring", "giver": "Guide Lumi", "target": "Poring", "need": 5, "level": 1, "exp": 34, "zeny": 170}, {"id": "side_01", "title": "คำร้อง: ช่วยจัดการ Lunatic", "giver": "Merchant Toma", "target": "Lunatic", "need": 5, "level": 3, "exp": 114, "zeny": 310}, {"id": "side_02", "title": "คำร้อง: ช่วยจัดการ Picky", "giver": "Blacksmith Doran", "target": "Picky", "need": 5, "level": 8, "exp": 664, "zeny": 660}, {"id": "side_03", "title": "คำร้อง: ช่วยจัดการ Poporing", "giver": "Captain Aldric", "target": "Poporing", "need": 6, "level": 12, "exp": 1464, "zeny": 940}, {"id": "side_04", "title": "คำร้อง: ช่วยจัดการ Spore", "giver": "Old Sage Bren", "target": "Spore", "need": 6, "level": 15, "exp": 2274, "zeny": 1150}, {"id": "side_05", "title": "คำร้อง: ช่วยจัดการ Peco Peco", "giver": "Guild Clerk Mira", "target": "Peco Peco", "need": 6, "level": 18, "exp": 3264, "zeny": 1360}, {"id": "side_06", "title": "คำร้อง: ช่วยจัดการ Wolf", "giver": "Guide Lumi", "target": "Wolf", "need": 7, "level": 32, "exp": 10264, "zeny": 2340}, {"id": "side_07", "title": "คำร้อง: ช่วยจัดการ Orc Warrior", "giver": "Merchant Toma", "target": "Orc Warrior", "need": 7, "level": 36, "exp": 12984, "zeny": 2620}, {"id": "side_08", "title": "คำร้อง: ช่วยจัดการ Mummy", "giver": "Blacksmith Doran", "target": "Mummy", "need": 7, "level": 42, "exp": 17664, "zeny": 3040}, {"id": "side_09", "title": "คำร้อง: ช่วยจัดการ Marin", "giver": "Captain Aldric", "target": "Marin", "need": 8, "level": 45, "exp": 20274, "zeny": 3250}, {"id": "side_10", "title": "คำร้อง: ช่วยจัดการ Sohee", "giver": "Old Sage Bren", "target": "Sohee", "need": 8, "level": 49, "exp": 24034, "zeny": 3530}, {"id": "side_11", "title": "คำร้อง: ช่วยจัดการ Minorous", "giver": "Guild Clerk Mira", "target": "Minorous", "need": 8, "level": 54, "exp": 29184, "zeny": 3880}, {"id": "side_12", "title": "คำร้อง: ช่วยจัดการ Nightmare", "giver": "Guide Lumi", "target": "Nightmare", "need": 9, "level": 58, "exp": 33664, "zeny": 4160}, {"id": "side_13", "title": "คำร้อง: ช่วยจัดการ Raydric", "giver": "Merchant Toma", "target": "Raydric", "need": 9, "level": 62, "exp": 38464, "zeny": 4440}, {"id": "side_14", "title": "คำร้อง: ช่วยจัดการ Wraith", "giver": "Blacksmith Doran", "target": "Wraith", "need": 9, "level": 65, "exp": 42274, "zeny": 4650}, {"id": "side_15", "title": "คำร้อง: ช่วยจัดการ Evil Druid", "giver": "Captain Aldric", "target": "Evil Druid", "need": 10, "level": 69, "exp": 47634, "zeny": 4930}, {"id": "side_16", "title": "คำร้อง: ช่วยจัดการ Baphomet Jr.", "giver": "Old Sage Bren", "target": "Baphomet Jr.", "need": 10, "level": 75, "exp": 56274, "zeny": 5350}, {"id": "side_17", "title": "คำร้อง: ช่วยจัดการ Deviruchi", "giver": "Guild Clerk Mira", "target": "Deviruchi", "need": 10, "level": 79, "exp": 62434, "zeny": 5630}]
static func g() -> Node:return (Engine.get_main_loop() as SceneTree).root.get_node("Game")
static func available(nm: String) -> Dictionary:
	for task in TASKS:
		if task.giver == nm and not g().quests.has(task.id) and g().base_level >= task.level:return task
	return {}
static func marker(nm: String) -> String:
	for task in TASKS:
		if task.giver == nm and g().quests.get(task.id, {}).get("state", "") == "done":return "?"
	return "!" if not available(nm).is_empty() else ""
static func claim(id: String) -> bool:
	var spec := {}
	for task in TASKS:
		if task.id == id:spec=task;break
	if spec.is_empty() or g().quests.get(id, {}).get("state", "") != "done":return false
	g().quests[id].state="finished"
	g().add_exp(int(spec.exp));g().add_zeny(int(spec.zeny));g().add_item("potion_red",3)
	g().save_game();g().quest_changed.emit();return true
static func interact(npc: Node, ui, fallback: Callable) -> bool:
	for task in TASKS:
		if task.giver != npc.npc_name:continue
		if g().quests.get(task.id, {}).get("state", "") == "done":
			ui.dialog(npc.npc_name,"ขอบใจที่ช่วยเหลือ! รางวัล %d EXP / %d Zeny" % [task.exp,task.zeny],["รับรางวัล", "คุยเรื่องอื่น"],func(i: int) -> void:
				if i==0:claim(task.id)
				else:fallback.call())
			return true
	var task := available(npc.npc_name)
	if task.is_empty():return false
	ui.dialog(npc.npc_name,"ข้าต้องการความช่วยเหลือ: กำจัด %s จำนวน %d ตัว แล้วกลับมารายงานข้า\nรางวัล %d EXP / %d Zeny" % [task.target,task.need,task.exp,task.zeny],["รับคำร้อง", "คุยเรื่องอื่น"],func(i: int) -> void:
		if i==0:
			g().start_quest(task.id,task.title,task.target,task.need,task.giver);g().save_game()
		else:fallback.call())
	return true
