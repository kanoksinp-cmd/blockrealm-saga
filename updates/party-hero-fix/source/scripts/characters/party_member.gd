extends "res://scripts/characters/party_member_original.gdc"
## Keep the shipped party AI, navigation, damage and healing implementation intact.
## Explicit skill animations are scheduled before normal attacks instead of hiding
## the skill choice inside the normal hit callback.
var _party_skill_queued := ""

const PARTY_SKILLS = {"swordsman":"bash","merchant":"mammonite","thief":"envenom", "archer":"double_strafe","mage":"fire_bolt","acolyte":"holy_light"}
const PARTY_ELEMENTS = {"swordsman":"physical","merchant":"earth","thief":"shadow","archer":"wind","mage":"fire","acolyte":"holy"}

func _physics_process(delta: float) -> void:
 if not _party_skill_queued.is_empty() and (not is_alive() or not model.is_attacking() or not _valid(_pending)):
  _party_skill_queued=""
  _pending=null
 _try_party_skill()
 super._physics_process(delta)

func _try_party_skill() -> bool:
 if not is_alive() or _skill_cd>0.0 or not _valid(target) or model.is_attacking(): return false
 var leader := _player()
 if leader==null or leader.get("_dead")==true: return false
 if leader.global_position.distance_to(global_position)>26.0: return false
 if VillageBuilder.area_at(leader.global_position)!=VillageBuilder.area_at(global_position):return false
 var to := target.global_position-global_position;to.y=0.0
 if to.length()>float(_st.range)+target.body_radius*target.size:return false
 var id: String=PARTY_SKILLS.get(String(info.job),"bash")
 if not model.skill_attack(SkillDB.anim_kind(id,model.weapon_kind,model.anim_style)):return false
 _pending=target
 _party_skill_queued=id
 _skill_cd=6.0
 _cool=maxf(_cool,float(_st.aspd))
 model.rotation.y=atan2(to.x,to.z)
 FX.popup(self,global_position+Vector3(0,2.35,0),tr(SkillDB.info(id).get("name",id))+"!",Color(1.0,0.9,0.55),36,0.5)
 load("res://scripts/combat/skill_power.gd").emit(self,global_position,PARTY_ELEMENTS.get(String(info.job),"physical"),"bolt" if info.job in ["mage","archer","acolyte"] else "melee",1.1,0.95,"release")
 return true

func _on_hit() -> void:
 if _party_skill_queued.is_empty():
  super._on_hit()
  return
 _party_skill_queued=""
 # The original skill-hit implementation owns all damage, projectiles and cooldowns.
 # Force its existing skill branch exactly once, at the skill animation's hit marker.
 if not is_alive() or not _valid(_pending):
  _pending=null
  return
 var victim := _pending
 _skill_cd=0.0
 super._on_hit()
 if is_instance_valid(victim):
  load("res://scripts/combat/skill_power.gd").emit(self,victim.global_position,PARTY_ELEMENTS.get(String(info.job),"physical"),"melee" if info.job not in ["mage","archer","acolyte"] else "bolt",1.15,1.0,"impact")

func _try_heal(p: Node3D) -> void:
 if not is_alive():return
 var old_cd := _heal_cd
 super._try_heal(p)
 if _heal_cd>old_cd:
  FX.popup(self,global_position+Vector3(0,2.35,0),tr("Heal")+"!",Color(0.6,1.0,0.72),36,0.5)
  load("res://scripts/combat/skill_power.gd").emit(self,global_position,"holy","heal",1.15,1.0,"support")
