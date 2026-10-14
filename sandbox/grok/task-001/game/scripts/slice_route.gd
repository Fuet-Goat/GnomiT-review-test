extends RefCounted
# Authored in descending_world_v2.png pixels (774 x 2032).
# The line follows the wooden bend; level badges remain UI, not route endpoints.
const SOURCE_SIZE := Vector2(774,2032)
const ROAD := [
 Vector2(437,563),Vector2(465,577),Vector2(488,598),
 Vector2(503,619),Vector2(512,641),Vector2(506,660),
 Vector2(490,678),Vector2(465,694),Vector2(438,706),
 Vector2(408,718),Vector2(376,728),Vector2(348,740),
 Vector2(322,754)]
const HALF_WIDTH := 38.0
var lengths: Array[float]=[0.0]
func _init() -> void:
 for i in range(1,ROAD.size()):lengths.append(lengths.back()+ROAD[i-1].distance_to(ROAD[i]))
func end_s() -> float:return lengths.back()
func dock_s(id: String) -> float:return lengths[2] if id=="entry" else end_s()
func point(s: float) -> Vector2:
 s=clampf(s,0,end_s())
 for i in range(ROAD.size()-1):
  if s<=lengths[i+1]:
   return ROAD[i].lerp(ROAD[i+1],(s-lengths[i])/maxf(0.001,lengths[i+1]-lengths[i]))
 return ROAD.back()
func closest(p: Vector2) -> Dictionary:
 var best={"s":0.0,"distance":INF,"point":ROAD.front()}
 for i in range(ROAD.size()-1):
  var delta: Vector2=ROAD[i+1]-ROAD[i]
  var t: float=clampf((p-ROAD[i]).dot(delta)/delta.length_squared(),0,1)
  var q: Vector2=ROAD[i]+delta*t
  var distance: float=p.distance_to(q)
  if distance<best.distance:best={"s":lengths[i]+delta.length()*t,"distance":distance,"point":q}
 return best
