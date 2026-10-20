extends RefCounted
## Height of the island for the story-map miniature (game/map/island_miniature.tscn).
## It is the game's real terrain (tools/build_common.gd G(), including the village hollow) plus four
## PROPOSED changes that the real terrain does not have yet, so the whole route has somewhere to go:
##   - a summit: the mountain is mirrored at SUMMIT_Z so it peaks and falls away behind
##   - a west coast: the island ends in the sea beyond x = -372 (cliffs), north beyond z = -690, east beyond x = 140
##   - a cove on the west coast (the colonial wreck) cut into those cliffs
##   - the river on the west plateau, a channel cut along the "water" side route in story/map.json
## None of this changes the real level scenes; edit the numbers here to move the coast or the summit.

const C := preload("res://tools/build_common.gd")

const MAP_PATH := "res://story/map.json"
const SUMMIT_Z := -560.0
const COVE := Vector2(-352.0, -300.0)
const SEA := -10.0


static var _river: Array = []


static func river() -> Array:
	if _river.is_empty():
		var f := FileAccess.open(MAP_PATH, FileAccess.READ)
		if f != null:
			var map = JSON.parse_string(f.get_as_text())
			for sr in map.get("side_routes", []):
				if sr.get("style", "") == "water":
					_river = sr["route"]
		if _river.is_empty():
			_river = [[0, 0], [0, 0]]
	return _river


static func river_distance(x: float, z: float) -> float:
	var r := river()
	var best := INF
	for i in r.size() - 1:
		best = minf(best, C.seg_dist(x, z, r[i][0], r[i][1], r[i + 1][0], r[i + 1][1]))
	return best


static func H(x: float, z: float) -> float:
	var ze := z if z >= SUMMIT_Z else 2.0 * SUMMIT_Z - z
	var h := C.G(x, ze)
	# the river: a channel about 3 m deep and 10 m wide
	var rd := river_distance(x, z)
	if rd < 12.0:
		h -= 3.2 * (1.0 - C.ss(3.0, 12.0, rd))
	# the cove: a beach that slopes into the sea, cut into the cliffs
	var cd := Vector2(x, z).distance_to(COVE)
	if cd < 62.0:
		var floor_h := lerpf(-6.0, 3.0, C.ss(-392.0, -345.0, x)) + (C.fbm(x * 0.2, z * 0.2, 2) - 0.5) * 1.2
		h = lerpf(h, floor_h, 1.0 - C.ss(30.0, 62.0, cd))
	# coasts
	h = lerpf(SEA, h, C.ss(-398.0, -372.0, x))
	h = lerpf(SEA, h, C.ss(172.0, 140.0, x))
	h = lerpf(SEA, h, C.ss(-715.0, -690.0, z))
	h = lerpf(h, SEA, C.ss(140.0, 160.0, z))
	return h
