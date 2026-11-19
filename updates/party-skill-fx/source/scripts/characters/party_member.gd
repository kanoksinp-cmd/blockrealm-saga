extends "res://scripts/characters/party_member_original.gdc"
## Keep the shipped party AI, navigation, damage and healing implementation intact.
## Party members now rotate through the real skills of their job line and show the
## same Ragnarok-style effects the player's skills have (ro_skill_fx.gd).
var _party_skill_queued := ""
var _party_rot := 0

const RoFX = preload("res://scripts/combat/ro_skill_fx.gd")
const EFX = preload("res://scripts/combat/element_fx.gd")
const PARTY_ELEMENTS = {"swordsman":"physical","merchant":"earth","thief":"shadow","archer":"wind","mage":"fire","acolyte":"holy"}
const SKILL_CD_SCALE := 0.6

func _physics_process(delta: float) -> void:
 if not _party_skill_queued.is_empty() and (not is_alive() or not model.is_attacking() or not _valid(_pending)):
  _party_skill_queued=""
  _pending=null
 _try_party_skill()
 super._physics_process(delta)


## Attack skills this member knows: its job line up to the party's tier (branch A).
func _party_skill_list() -> Array:
 var job := String(info.job)
 var out := []
 var top := clampi(int(Party.tier()), 1, 5)
 for t in range(1, top + 1):
  for id in SkillDB.tier_skills(job, t, "a"):
   var s := SkillDB.info(id)
   if String(s.get("type","")) in ["melee","bolt","aoe_self","aoe_target"] and not s.get("sp_all",false) \
     and not s.has("hp_pct") and not s.get("nodmg",false) and not s.has("zeny"):
    out.append(id)
 if out.is_empty():
  out = [{"swordsman":"bash","merchant":"cart_revolution","thief":"envenom","archer":"double_strafe","mage":"fire_bolt","acolyte":"holy_light"}.get(job,"bash")]
 return out


func _party_lv(id: String) -> int:
 return clampi(1 + int(Game.base_level) / 8, 1, int(SkillDB.info(id).get("max", 1)))


func _next_party_skill() -> String:
 var list := _party_skill_list()
 var id: String = list[_party_rot % list.size()]
 _party_rot += 1
 return id


func _elem(id: String) -> String:
 var p := _player()
 if p and p.has_method("_skill_element"):
  return String(p._skill_element(id))
 return PARTY_ELEMENTS.get(String(info.job),"physical")


func _try_party_skill() -> bool:
 if not is_alive() or _skill_cd>0.0 or not _valid(target) or model.is_attacking(): return false
 var leader := _player()
 if leader==null or leader.get("_dead")==true: return false
 if leader.global_position.distance_to(global_position)>26.0: return false
 if VillageBuilder.area_at(leader.global_position)!=VillageBuilder.area_at(global_position):return false
 var to := target.global_position-global_position;to.y=0.0
 if to.length()>float(_st.range)+target.body_radius*target.size:return false
 var id := _next_party_skill()
 if not model.skill_attack(SkillDB.anim_kind(id,model.weapon_kind,model.anim_style)):return false
 _pending=target
 _party_skill_queued=id
 _skill_cd=4.0
 _cool=maxf(_cool,float(_st.aspd))
 model.rotation.y=atan2(to.x,to.z)
 _announce(id)
 return true


func _announce(id: String) -> void:
 FX.popup(self,global_position+Vector3(0,2.35,0),tr(SkillDB.info(id).get("name",id))+"!",Color(1.0,0.9,0.55),36,0.5)
 var el := _elem(id)
 var s := SkillDB.info(id)
 load("res://scripts/combat/skill_power.gd").emit(self,global_position,el,"bolt" if s.type in ["bolt","aoe_target"] else "melee",1.1,0.95,"release")
 if el != "physical" and s.type in ["bolt","aoe_target"]:
  EFX.circle(self, el, global_position, 1.3, 0.7, self)


## The skill's real effect at the target, plus area damage for area skills.
func _skill_effect(id: String, victim: Node3D) -> void:
 if not is_instance_valid(victim):
  return
 var s := SkillDB.info(id)
 var lv := _party_lv(id)
 var el := _elem(id)
 var at := victim.global_position
 match String(s.type):
  "melee":
   FX.slash_x(self, at + Vector3(0,0.7,0), s.get("color", Color(1.0,0.85,0.5)), 1.2)
   RoFX.play(self, id, lv, at, 1.0, 0)
   if el != "physical":
    EFX.impact(self, el, at, 0.9)
  "bolt":
   var n := mini(SkillDB.hits(id, lv), 5)
   for i in n:
    get_tree().create_timer(0.1 * i).timeout.connect(func() -> void:
     if not is_instance_valid(victim): return
     var hit_at := victim.global_position + Vector3(0, 0.5, 0)
     if id == "lightning_bolt":
      RoFX.sky_lightning(self, victim.global_position)
     else:
      var from_at := RoFX.sky_start(id, victim.global_position)
      FX.projectile(self, global_position + Vector3(0,1.5,0) if from_at == Vector3.INF else from_at, hit_at,
       String(s.get("proj","magic")), func() -> void: pass, true))
   get_tree().create_timer(0.1 * n + 0.25).timeout.connect(func() -> void:
    if is_instance_valid(victim):
     RoFX.play(self, id, lv, victim.global_position, 0.8, 0)
     if el != "physical":
      EFX.impact(self, el, victim.global_position, 0.8))
  "aoe_self", "aoe_target":
   var center := global_position if s.type == "aoe_self" else at
   var rad := float(s.get("radius", 2.5))
   var waves := clampi(SkillDB.hits(id, lv), 1, 4)
   if s.type == "aoe_target":
    EFX.rune_circle(self, el, EFX.color(el), center, clampf(rad, 1.6, 4.0), 0.35 * waves + 0.6, null)
   FX.ring(self, center, s.get("color", Color(1,0.8,0.4,0.9)), rad)
   if RoFX.lead_time(id) > 0.0:
    RoFX.lead(self, id, lv, center, rad)
   for w in waves:
    get_tree().create_timer(RoFX.lead_time(id) + 0.35 * w).timeout.connect(func() -> void:
     if not is_inside_tree(): return
     if w == 0 and not RoFX.has(id):
      FX.burst(self, center, s.get("color", Color(1,0.8,0.4)), rad)
      if el != "physical":
       EFX.impact(self, el, center, rad * 0.7)
     RoFX.play(self, id, lv, center, rad, w)
     # area skills also hit the monsters around the target
     var dmg := int(float(_st.atk) * SkillDB.mult(id, lv) * 0.5 / waves)
     for m in get_tree().get_nodes_in_group("monster"):
      if m != victim and m.has_method("is_alive") and m.is_alive():
       var d: Vector3 = m.global_position - center
       d.y = 0.0
       if d.length() <= rad:
        m.take_damage(maxi(1, dmg), self))


func _announce_skill(victim: Node3D) -> void:
 var id := _next_party_skill()
 _announce(id)
 _skill_effect(id, victim)


func _on_hit() -> void:
 if _party_skill_queued.is_empty():
  var before := _skill_cd
  var victim: Node3D = _pending if _valid(_pending) else (target if _valid(target) else null)
  super._on_hit()
  if before <= 0.0 and _skill_cd > 0.0:   # the original AI just used its skill in this swing
   _skill_cd *= SKILL_CD_SCALE
   _announce_skill(victim)
  return
 var id := _party_skill_queued
 _party_skill_queued=""
 # The original skill-hit implementation owns the main target's damage and cooldowns.
 # Force its existing skill branch exactly once, at the skill animation's hit marker.
 if not is_alive() or not _valid(_pending):
  _pending=null
  return
 var victim := _pending
 _skill_cd=0.0
 super._on_hit()
 _skill_cd *= SKILL_CD_SCALE
 _skill_effect(id, victim)


func _try_heal(p: Node3D) -> void:
 if not is_alive():return
 var old_cd := _heal_cd
 super._try_heal(p)
 if _heal_cd>old_cd:
  FX.popup(self,global_position+Vector3(0,2.35,0),tr("Heal")+"!",Color(0.6,1.0,0.72),36,0.5)
  load("res://scripts/combat/skill_power.gd").emit(self,global_position,"holy","heal",1.15,1.0,"support")
  if is_instance_valid(p):
   RoFX.support(self, "heal", p.global_position)
   RoFX.aura(self, "heal", p.global_position)
