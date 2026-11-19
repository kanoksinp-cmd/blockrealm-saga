"""Add Ragnarok-style weapon attacks and skill poses to knight_model.gd (run once on the copied source)."""
from pathlib import Path

p = Path(__file__).parent / 'source/scripts/characters/knight_model.gd'
t = p.read_text()


def dedent(s: str) -> str:
    return '\n'.join(l[1:] if l.startswith('\t') else l for l in s.split('\n'))


POSES = '''			"thrust":   # Pierce: low lunge, weapon straight ahead
				var back: = _ph(k, 0.0, 0.3, 0.5)
				var lunge: = _ph(k, 0.3, 0.42, 2.4)
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.2, -1.6, lunge), maxf(back, lunge) * rec), lerpf(0.0, 0.4 * (1.0 - lunge), back) * rec, -0.05)
				arm_r.position.z = (-0.1 * back + 0.28 * lunge) * rec
				torso.rotation.y += (0.45 * back - 0.5 * lunge) * rec
				torso.rotation.x += 0.25 * lunge * rec
				hips.position.z = (-0.08 * back + 0.4 * lunge) * rec
				hips.position.y -= 0.1 * lunge * rec
				leg_l.rotation.x = -0.9 * lunge * rec
				leg_r.rotation.x = 0.55 * lunge * rec
				if not _trail_sent and k >= 0.32:
					_trail_sent = true
					FX.trail(self, trail_color, -8.0, 8.0, 1.0, 0.0, 1.6)
			"spiral":   # Spiral Pierce: leap, spin and drive down
				var crouch: = _ph(k, 0.0, 0.2, 0.5)
				var rise: = _ph(k, 0.2, 0.5, 0.6)
				var dive: = _ph(k, 0.55, 0.68, 2.4)
				hips.position.y += (-0.12 * crouch * (1.0 - rise) + 1.1 * rise * (1.0 - dive) - 0.1 * dive) * rec
				hips.rotation.y += TAU * 1.5 * rise * rec
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.8, -1.0, dive), maxf(rise, dive) * rec), 0.0, -0.1)
				torso.rotation.x += (-0.3 * rise * (1.0 - dive) + 0.8 * dive) * rec
				leg_l.rotation.x = (-0.9 * rise * (1.0 - dive) - 0.4 * dive) * rec
				leg_r.rotation.x = (-0.6 * rise * (1.0 - dive) + 0.4 * dive) * rec
				if not _trail_sent and k >= 0.56:
					_trail_sent = true
					FX.trail(self, trail_color, 0.0, 359.0, 0.8, PI * 0.5, 1.4)
			"sweep":   # Brandish Spear: a wide horizontal arc
				var wind: = _ph(k, 0.0, 0.32, 0.5)
				var cut: = _ph(k, 0.32, 0.5, 2.2)
				arm_r.rotation = Vector3(lerpf(-0.6, -1.45, maxf(wind, cut) * rec), lerpf(0.0, lerpf(1.1, -1.3, cut), maxf(wind, cut) * rec), -0.2)
				torso.rotation.y += (0.9 * wind - 1.5 * cut) * rec
				hips.position.y -= 0.1 * cut * rec
				leg_l.rotation.x = -0.5 * cut * rec
				leg_r.rotation.x = 0.35 * cut * rec
				if not _trail_sent and k >= 0.34:
					_trail_sent = true
					FX.trail(self, trail_color, 80.0, -80.0, 1.35, 0.0, 1.2)
			"power_up":   # Two-Hand Quicken / Aura Blade / Frenzy: crouch, fists clenched, burst upward
				var gather: = _ph(k, 0.0, 0.45, 0.5)
				var burst: = _ph(k, 0.45, 0.6, 2.0)
				hips.position.y += (-0.14 * gather * (1.0 - burst) + 0.06 * burst) * rec
				arm_r.rotation = arm_r.rotation.lerp(Vector3(lerpf(-0.9, -0.3, burst), 0.0, lerpf(-0.2, -1.1, burst)), maxf(gather, burst) * rec)
				arm_l.rotation = arm_l.rotation.lerp(Vector3(lerpf(-0.9, -0.3, burst), 0.0, lerpf(0.2, 1.1, burst)), maxf(gather, burst) * rec)
				torso.rotation.x += (0.3 * gather * (1.0 - burst) - 0.25 * burst) * rec
				head.rotation.x += (0.25 * gather * (1.0 - burst) - 0.35 * burst) * rec
			"falcon":   # Blitz Beat / Falcon Assault: arm thrust out, sending the falcon
				var up: = _ph(k, 0.0, 0.3, 0.5)
				var send: = _ph(k, 0.32, 0.45, 2.0)
				arm_l.rotation = arm_l.rotation.lerp(Vector3(lerpf(-2.6, -1.5, send), 0.0, 0.25), maxf(up, send) * rec)
				arm_l.position.z = 0.15 * send * rec
				arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.3, 0.0, -0.4), up * rec)
				torso.rotation.y += (-0.3 * up + 0.4 * send) * rec
				leg_l.rotation.x = -0.35 * send * rec
			"set_trap":   # traps: kneel and set it on the ground
				var down: = _ph(k, 0.0, 0.4, 0.5)
				var place: = _ph(k, 0.4, 0.55, 1.5)
				hips.position.y -= 0.32 * down * rec
				torso.rotation.x += 0.7 * down * rec
				leg_l.rotation.x = -1.2 * down * rec
				leg_r.rotation.x = 0.9 * down * rec
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.0, -0.5, place), down * rec), 0.0, -0.1)
				arm_l.rotation = Vector3(lerpf(-0.2, -0.8, down * rec), 0.0, 0.2)
			"aim_shot":   # Sharp Shooting: a long, steady draw
				var hold_k: = _ph(k, 0.0, 0.2) * rec
				var draw: = _ph(k, 0.15, 0.6, 0.6) * (1.0 - _ph(k, 0.62, 0.68))
				arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.55, 0, 0.12), hold_k)
				arm_r.rotation = arm_r.rotation.lerp(Vector3(-1.5, -0.85 * draw, -0.6 * draw), hold_k)
				torso.rotation.y += -0.5 * hold_k
				hips.position.y -= 0.08 * hold_k
				leg_l.rotation.x = -0.45 * hold_k
				leg_r.rotation.x = 0.35 * hold_k
			"dash", "dash_stab":   # Cart Termination / Back Stab: burst forward and strike
				var lean: = _ph(k, 0.0, 0.25, 0.5)
				var go: = _ph(k, 0.25, 0.45, 1.6)
				hips.position.z = (-0.1 * lean + 0.9 * go) * rec
				hips.position.y += 0.08 * sin(go * PI) * rec
				torso.rotation.x += (0.35 * lean + 0.2 * go) * rec
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-0.4, -1.7, go), maxf(lean, go) * rec), 0.0, -0.1)
				arm_r.position.z = 0.2 * go * rec
				arm_l.rotation = Vector3(lerpf(-0.2, 0.5, lean) * rec, 0.0, 0.3)
				leg_l.rotation.x = (-0.3 * lean - 0.8 * go) * rec
				leg_r.rotation.x = (0.3 * lean + 0.6 * go) * rec
				if not _trail_sent and k >= 0.4:
					_trail_sent = true
					FX.trail(self, trail_color, -20.0, 20.0, 1.0, 0.0, 1.4)
			"flurry":   # Sonic Blow: eight blurred stabs, both arms
				var on: = _ph(k, 0.0, 0.1) * rec
				var a: = sin(k * PI * 16.0)
				arm_r.rotation = Vector3(lerpf(-0.6, -1.3 - 0.35 * a, on), lerpf(0.0, 0.3 * a, on), -0.1)
				arm_l.rotation = Vector3(lerpf(-0.2, -1.3 + 0.35 * a, on), lerpf(0.0, 0.3 * a, on), 0.1)
				arm_r.position.z = 0.15 * maxf(a, 0.0) * on
				arm_l.position.z = 0.15 * maxf(-a, 0.0) * on
				torso.rotation.y += 0.25 * a * on
				hips.position.y -= 0.08 * on
				leg_l.rotation.x = -0.5 * on
				leg_r.rotation.x = 0.35 * on
				if not _trail_sent and k >= 0.15:
					_trail_sent = true
					FX.trail(self, trail_color, -60.0, 60.0, 0.9, 0.3, 1.0)
			"ground_stab":   # Grimtooth: drive the weapon into the ground
				var up: = _ph(k, 0.0, 0.38, 0.5)
				var down: = _ph(k, 0.38, 0.5, 2.6)
				hips.position.y += (0.15 * up * (1.0 - down) - 0.3 * down) * rec
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.9, -0.1, down), maxf(up, down) * rec), 0.0, -0.1)
				arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-2.7, -0.2, down), maxf(up, down) * rec), 0.0, 0.1)
				torso.rotation.x += (-0.2 * up + 0.9 * down) * rec
				leg_l.rotation.x = -1.0 * down * rec
				leg_r.rotation.x = 0.8 * down * rec
			"asura":   # Asura Strike: gather glowing power, then a blinding dash-punch
				var gather: = _ph(k, 0.0, 0.62, 0.7)
				var strike: = _ph(k, 0.64, 0.76, 2.4)
				var shake: = sin(_t * 60.0) * 0.03 * gather * (1.0 - strike)
				hips.position.y += (-0.18 * gather * (1.0 - strike)) * rec
				hips.position.z = (0.04 * shake + 1.2 * strike) * rec
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(0.4, -1.6, strike), maxf(gather, strike) * rec), lerpf(0.0, 0.5 * (1.0 - strike), gather) * rec, -0.2)
				arm_r.position.z = (-0.12 * gather * (1.0 - strike) + 0.25 * strike) * rec
				arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-1.2, 0.4, strike), maxf(gather, strike) * rec), 0.0, 0.4)
				torso.rotation.y += (0.6 * gather * (1.0 - strike) - 0.4 * strike) * rec + shake
				torso.rotation.x += (0.2 * gather + 0.25 * strike) * rec
				leg_l.rotation.x = (-0.5 * gather - 0.5 * strike) * rec
				leg_r.rotation.x = (0.45 * gather + 0.4 * strike) * rec
			"cross_slash":   # Holy Cross: two diagonal cuts making an X
				var a1: = _ph(k, 0.1, 0.32, 2.0)
				var back: = _ph(k, 0.34, 0.44, 0.6)
				var a2: = _ph(k, 0.44, 0.58, 2.0)
				var z: = lerpf(lerpf(lerpf(-1.4, 0.8, a1), 0.9, back), -1.2, a2)
				var x: = lerpf(lerpf(lerpf(-2.6, -0.5, a1), -2.6, back), -0.5, a2)
				arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, lerpf(-0.3, z, rec))
				torso.rotation.y += (0.4 * (a1 - a2)) * rec
				torso.rotation.x += 0.2 * maxf(a1, a2) * rec
				leg_l.rotation.x = -0.4 * rec
				if not _trail_sent and k >= 0.2:
					_trail_sent = true
					FX.trail(self, Color(1.0, 0.92, 0.55), -60.0, 60.0, 1.1, PI * 0.25, 1.0)
					get_tree().create_timer(0.2).timeout.connect(func() -> void:
						if is_inside_tree():
							FX.trail(self, Color(1.0, 0.92, 0.55), 60.0, -60.0, 1.1, -PI * 0.25, 1.0))
			"shield_bash":   # Shield Charge: shoulder forward behind the shield
				var go: = _ph(k, 0.15, 0.36, 2.0)
				var lean: = _ph(k, 0.0, 0.15)
				arm_l.rotation = Vector3(lerpf(-0.2, -1.5, maxf(lean, go)) * rec, 0.0, 0.1)
				arm_l.position.z = 0.25 * go * rec
				arm_r.rotation = Vector3(-0.3 * rec, 0.0, -0.3)
				hips.position.z = 0.55 * go * rec
				torso.rotation.y += (-0.5 * lean + 0.3 * go) * rec
				torso.rotation.x += 0.3 * go * rec
				leg_l.rotation.x = -0.8 * go * rec
				leg_r.rotation.x = 0.5 * go * rec
			"cross_pose":   # Grand Cross / Gospel: arms spread wide, head back
				var open: = _ph(k, 0.0, 0.5, 0.5)
				var flare: = _ph(k, 0.5, 0.6, 2.0)
				arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.2, 0.0, -1.5), open * rec)
				arm_l.rotation = arm_l.rotation.lerp(Vector3(-0.2, 0.0, 1.5), open * rec)
				torso.rotation.x -= (0.15 * open + 0.15 * flare) * rec
				head.rotation.x -= (0.3 * open + 0.15 * flare) * rec
				hips.position.y += 0.1 * open * rec
			"cast_ground":   # Earth Spike / Heaven's Drive: palm slammed to the ground
				var up: = _ph(k, 0.0, 0.35, 0.5)
				var down: = _ph(k, 0.38, 0.5, 2.4)
				hips.position.y -= 0.35 * down * rec
				torso.rotation.x += (-0.2 * up + 0.8 * down) * rec
				arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-2.7, -0.3, down), maxf(up, down) * rec), 0.0, 0.2)
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.0, -0.5, down), maxf(up, down) * rec), 0.0, -0.25)
				leg_l.rotation.x = -1.1 * down * rec
				leg_r.rotation.x = 0.8 * down * rec
			"uppercut":   # Tiger Knuckle Fist / Occult Impaction: rising strike
				var dip: = _ph(k, 0.0, 0.3, 0.5)
				var rise: = _ph(k, 0.3, 0.45, 2.0)
				hips.position.y += (-0.15 * dip * (1.0 - rise) + 0.15 * rise) * rec
				arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-0.2, -2.8, rise), maxf(dip, rise) * rec), 0.0, -0.15)
				arm_l.rotation = Vector3(lerpf(-0.2, -1.0, dip) * rec, 0.0, 0.3)
				torso.rotation.x += (0.3 * dip * (1.0 - rise) - 0.25 * rise) * rec
				torso.rotation.y += (0.4 * dip - 0.5 * rise) * rec
				leg_l.rotation.x = -0.5 * rise * rec
			"chop":   # Mammonite / axe skills: big overhead chop
				var up: = _ph(k, 0.0, 0.4, 0.5)
				var hit: = _ph(k, 0.4, 0.52, 2.6)
				var x: = lerpf(lerpf(-0.6, -3.2, up), 0.05, hit)
				arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, -0.1)
				arm_l.rotation = Vector3(lerpf(-0.2, x * 0.9, rec), 0.0, 0.15)
				torso.rotation.x += (-0.4 * up + 0.75 * hit) * rec
				hips.position.y += (0.05 * up - 0.18 * hit) * rec
				leg_l.rotation.x = -0.6 * hit * rec
				leg_r.rotation.x = 0.35 * hit * rec
				if not _trail_sent and k >= 0.42:
					_trail_sent = true
					FX.trail(self, trail_color, 120.0, -40.0, 1.05, PI * 0.5, 1.2)
'''

WEAPON = '''## Ragnarok-style basic attack per weapon type (sword keeps the 3-hit slash combo).
func _weapon_attack(k: float) -> bool:
	var wind: = ease(clampf(k / 0.35, 0.0, 1.0), 0.5)
	var strike: = ease(clampf((k - 0.35) / 0.2, 0.0, 1.0), 2.2)
	var off: = 1.0 - ease(clampf((k - 0.6) / 0.4, 0.0, 1.0), 0.6)
	match weapon_kind:
		"spear":   # thrust from the hip
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.1, -1.55, strike), maxf(wind, strike) * off), lerpf(0.0, 0.35 * (1.0 - strike), wind) * off, -0.05)
			arm_r.position.z = (-0.1 * wind + 0.3 * strike) * off
			torso.rotation.y += (0.4 * wind - 0.45 * strike) * off
			hips.position.z = 0.25 * strike * off
			leg_l.rotation.x = -0.6 * strike * off
			leg_r.rotation.x = 0.35 * strike * off
			if not _trail_sent and k >= 0.36:
				_trail_sent = true
				FX.trail(self, trail_color, -6.0, 6.0, 1.0, 0.0, 1.5)
		"axe", "mace", "book":   # overhead chop / bonk, then a side swing
			if _combo == 1:
				return false
			var x: = lerpf(lerpf(-0.6, -3.0, wind), -0.1, strike)
			arm_r.rotation = Vector3(lerpf(-0.6, x, off), 0.0, -0.15)
			if hold == "two_hand" or not has_shield:
				arm_l.rotation = Vector3(lerpf(-0.2, x * (0.9 if hold == "two_hand" else 0.3), off), 0.0, 0.2)
			torso.rotation.x += (-0.3 * wind + 0.55 * strike) * off
			hips.position.y += (0.04 * wind - 0.12 * strike) * off
			leg_l.rotation.x = -0.5 * strike * off
			leg_r.rotation.x = 0.3 * strike * off
			if not _trail_sent and k >= 0.37:
				_trail_sent = true
				FX.trail(self, trail_color, 110.0, -30.0, 0.95, PI * 0.5, 1.0)
		"greatsword":   # heavy two-handed swings: diagonal, overhead, rising
			var z0: float = [-1.4, 0.0, 1.0][_combo]
			var x0: float = [-2.2, -3.0, -0.3][_combo]
			var x1: float = [-0.6, -0.1, -2.6][_combo]
			var z1: float = [0.9, 0.0, -0.9][_combo]
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(x0, x1, strike), maxf(wind, strike) * off), 0.0, lerpf(-0.2, lerpf(z0, z1, strike), maxf(wind, strike) * off))
			torso.rotation.y += ((0.6 * wind - 0.9 * strike) if _combo != 1 else 0.0) * off
			torso.rotation.x += (0.45 * strike if _combo == 1 else 0.15 * strike) * off
			hips.position.y -= 0.12 * strike * off
			leg_l.rotation.x = -0.6 * strike * off
			leg_r.rotation.x = 0.35 * strike * off
			if not _trail_sent and k >= 0.37:
				_trail_sent = true
				var a0: float = [-110.0, 110.0, 40.0][_combo]
				var a1: float = [70.0, -30.0, -120.0][_combo]
				var tilt: float = [0.15, PI * 0.5, -0.2][_combo]
				FX.trail(self, trail_color, a0, a1, 1.25, tilt, 1.2)
		"dagger":   # quick stab, slash, stab
			if _combo == 1:
				return false
			var fast: = ease(clampf((k - 0.25) / 0.15, 0.0, 1.0), 2.0)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-0.8, -1.6, fast), off), lerpf(0.3, -0.1, fast) * off, -0.1)
			arm_r.position.z = 0.22 * fast * off
			torso.rotation.y += (0.3 - 0.5 * fast) * off
			hips.position.z = 0.15 * fast * off
			leg_l.rotation.x = -0.45 * fast * off
			if not _trail_sent and k >= 0.3:
				_trail_sent = true
				FX.trail(self, trail_color, -10.0, 10.0, 0.85, 0.0, 1.2)
		"katar":   # Assassin: alternating left/right jabs with both katars
			var l: = _combo % 2 == 1
			var jab: = ease(clampf((k - 0.25) / 0.17, 0.0, 1.0), 2.0)
			var punch: = Vector3(lerpf(-0.9, -1.6, jab), 0.0, 0.0)
			var guard: = Vector3(-1.1, 0.0, 0.0)
			arm_r.rotation = (guard if l else punch).lerp(Vector3(-0.6, 0.0, -0.2), 1.0 - off)
			arm_l.rotation = (punch if l else guard).lerp(Vector3(-0.2, 0.0, 0.2), 1.0 - off)
			if l:
				arm_l.position.z = 0.22 * jab * off
			else:
				arm_r.position.z = 0.22 * jab * off
			torso.rotation.y += (0.35 if l else -0.35) * jab * off
			hips.position.y -= 0.06 * off
			leg_l.rotation.x = -0.45 * off
			leg_r.rotation.x = 0.3 * off
			if not _trail_sent and k >= 0.3:
				_trail_sent = true
				FX.trail(self, trail_color, -10.0, 10.0, 0.85, 0.0, 1.2)
		"knuckle", "none":   # Monk: jab, cross, uppercut
			var up: = _combo == 2
			var l: = _combo == 0
			var hit: = ease(clampf((k - 0.25) / 0.17, 0.0, 1.0), 2.0)
			var arm: Node3D = arm_l if l else arm_r
			var other: Node3D = arm_r if l else arm_l
			arm.rotation = Vector3(lerpf(-0.9, -2.6 if up else -1.6, hit), 0.0, 0.0).lerp(arm.rotation, 1.0 - off)
			other.rotation = Vector3(-1.1, 0.0, 0.0).lerp(other.rotation, 1.0 - off)
			arm.position.z = (0.08 if up else 0.22) * hit * off
			torso.rotation.y += (0.35 if l else -0.4) * hit * off
			hips.position.y += (0.1 * hit if up else -0.05) * off
			leg_l.rotation.x = -0.45 * off
			leg_r.rotation.x = 0.3 * off
		"lute":   # Bard: strum, then swing the instrument
			if _combo != 0:
				return false
			var beat: = sin(k * PI * 6.0)
			arm_r.rotation = Vector3(-1.0 + 0.3 * beat * off, 0.5, -0.25)
			arm_l.rotation = Vector3(-1.3, -0.4, 0.4)
			hips.position.y += absf(beat) * 0.04 * off
			head.rotation.z += 0.1 * beat * off
		"whip":   # Dancer: whip crack forward
			var back: = _ph(k, 0.0, 0.35, 0.5)
			var crack: = _ph(k, 0.35, 0.45, 2.6)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.8, -1.1, crack), maxf(back, crack) * off), 0.0, lerpf(-0.2, -0.6, back) * off)
			torso.rotation.y += (0.5 * back - 0.6 * crack) * off
			hips.rotation.z += 0.08 * crack * off
			leg_l.rotation.x = -0.4 * crack * off
			if not _trail_sent and k >= 0.37:
				_trail_sent = true
				FX.trail(self, trail_color, 90.0, -10.0, 1.6, PI * 0.5, 0.8)
		_:
			return false
	return true


'''

R = [
('''	"buff": [0.75, -1.0], "pray": [0.85, -1.0], "quick": [0.45, 0.4],
}''', '''	"buff": [0.75, -1.0], "pray": [0.85, -1.0], "quick": [0.45, 0.4],
	# Ragnarok-style signature moves
	"thrust": [0.55, 0.32], "spiral": [0.95, 0.66], "sweep": [0.72, 0.42], "power_up": [0.8, -1.0],
	"falcon": [0.65, 0.42], "set_trap": [0.7, 0.52], "aim_shot": [0.9, 0.64], "dash": [0.6, 0.42],
	"flurry": [0.8, 0.22], "ground_stab": [0.7, 0.46], "dash_stab": [0.55, 0.4], "asura": [1.0, 0.74],
	"cross_slash": [0.75, 0.52], "shield_bash": [0.55, 0.34], "cross_pose": [0.9, 0.56], "cast_ground": [0.75, 0.5],
	"uppercut": [0.6, 0.36], "chop": [0.7, 0.48],
}'''),
('''		_:
			_slash_attack(k)
	if hold == "two_hand" and kind in ["power_strike", "thrust_combo", "spin", "slam"]:''',
 dedent(POSES) + '''		_:
			_slash_attack(k)
	if hold == "two_hand" and kind in ["power_strike", "thrust_combo", "spin", "slam", "thrust", "spiral", "sweep", "chop", "dash"]:'''),
('''			_slash_attack(k)
			if hold == "two_hand":''', '''			if not _weapon_attack(k):
				_slash_attack(k)
			if hold == "two_hand":'''),
('''func _slash_attack(k: float) -> void:''', WEAPON + '''func _slash_attack(k: float) -> void:'''),
]
for a, b in R:
    assert t.count(a) == 1, a[:70]
    t = t.replace(a, b)
p.write_text(t)
print('patched')
