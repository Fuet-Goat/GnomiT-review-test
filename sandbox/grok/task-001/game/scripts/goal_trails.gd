extends Control
signal arrived(amount: int)
var reduced_motion := false
var orbs: Array = []
var token_texture: Texture2D
var tint: Color=Color("91e9ff")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func launch(from_global: Vector2, to_global: Vector2, amount: int=1) -> void:
	if reduced_motion:
		arrived.emit(amount);return
	var inverse: Transform2D=get_global_transform().affine_inverse()
	var start: Vector2=inverse*from_global
	var finish: Vector2=inverse*to_global
	orbs.append({"from":start,"to":finish,"bend":start.lerp(finish,0.5)+Vector2(-70,-100),"age":0.0,"life":0.38,"amount":amount,"texture":token_texture,"tint":tint})
	while orbs.size()>64:
		arrived.emit(int(orbs[0].amount));orbs.pop_front()
func point(orb: Dictionary, t: float) -> Vector2:
	return Vector2(orb.from).lerp(orb.bend,t).lerp(Vector2(orb.bend).lerp(orb.to,t),t)
func _process(delta: float) -> void:
	for i in range(orbs.size()-1,-1,-1):
		orbs[i].age+=delta
		if orbs[i].age>=orbs[i].life:
			arrived.emit(int(orbs[i].amount));orbs.remove_at(i)
	queue_redraw()
func _draw() -> void:
	for orb in orbs:
		var t: float=clampf(float(orb.age)/float(orb.life),0,1)
		var p: Vector2=point(orb,t)
		for trail in range(7,0,-1):
			var behind: float=maxf(0,t-float(trail)*0.025)
			draw_circle(point(orb,behind),maxf(1,5-float(trail)*0.5),Color(0.28,0.84,1.0,0.07+0.04*float(8-trail)),true,-1,true)
		draw_circle(p,12,Color(0.22,0.72,1.0,0.12),true,-1,true)
		if orb.texture!=null:
			var extent:=Vector2.ONE*44.0*(1.0-t*0.25)
			draw_texture_rect(orb.texture,Rect2(p-extent*0.5,extent),false)
		else:draw_circle(p,7,orb.tint,true,-1,true)
		draw_circle(p,2.2,Color("fffbdc"),true,-1,true)
