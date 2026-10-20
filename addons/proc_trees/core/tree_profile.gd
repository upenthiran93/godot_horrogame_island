@tool
@icon("res://addons/proc_trees/icons/tree_profile.svg")
class_name TreeProfile
extends Resource
## Recipe for one kind of procedural tree. TreeBuilder grows it (plus a variant number) into LOD meshes;
## ProcTree shows one tree, TreeForest / TreeInstances draw thousands. Ready-made recipes: TreeProfile.preset("realistic_palm"),
## or the saved copies in res://addons/proc_trees/presets/. Edit a copy in the inspector: trees update live.
## Also implements the scatter-item API (get_lod_count / get_lod_mesh / get_item_info / get_cache_key) that
## TreeInstances and forest/scatter plugins use. See the README.

enum Style { REALISTIC, STYLIZED }
enum Archetype { BROADLEAF, CONIFER, PALM, DEAD }
enum Crown { SPHERE, CONE, DOME, CYLINDER, FLAME }

## REALISTIC: bark textures + alpha-cut leaf cards. STYLIZED: toon-shaded solid canopy (puffs, tiers, fronds).
@export var style := Style.REALISTIC
@export var archetype := Archetype.BROADLEAF
## The random shape of the tree. Other settings keep the shape when you change them; change this to get a new one.
@export var shape_seed := 0
@export_tool_button("Reroll shape", "RandomNumberGenerator") var reroll_action := reroll

@export_group("Trunk")
@export_range(1.0, 60.0, 0.1, "suffix:m") var height := 12.0
## Random height spread between variants.
@export_range(0.0, 0.5) var height_jitter := 0.15
## Broadleaf/dead: how much of the height is bare trunk before the crown takes over.
@export_range(0.2, 1.0) var trunk_length := 0.65
@export_range(0.02, 3.0, 0.01, "suffix:m") var trunk_radius := 0.3
## Radius at the top of the trunk, as a fraction of the base radius.
@export_range(0.0, 1.0) var trunk_taper := 0.3
@export_range(0.0, 3.0) var root_flare := 0.5
## Root buttresses (jungle giants). 0 = round flare.
@export_range(0, 8) var buttresses := 0
@export_range(0.0, 1.0) var lean := 0.05
## Pulls a leaning trunk back up towards vertical (palms).
@export_range(0.0, 1.0) var curve := 0.0
@export_range(0.0, 1.0) var gnarl := 0.15

@export_group("Branches")
@export_range(0, 3) var levels := 2
## Children per parent for branch level 1, 2, 3.
@export var branch_count := Vector3i(7, 4, 3)
## Where on the trunk (0..1) the first branches start.
@export_range(0.0, 0.95) var branch_start := 0.35
## Angle from the parent, in degrees, per level.
@export var branch_angle := Vector3(55, 45, 40)
## Length relative to the parent, per level.
@export var branch_length := Vector3(0.6, 0.45, 0.5)
## Child thickness relative to the parent at the joint.
@export_range(0.1, 1.0) var branch_radius := 0.55
@export_range(-1.0, 2.0) var branch_droop := 0.15
@export_range(-1.0, 2.0) var branch_upturn := 0.25
## Silhouette of level-1 branch lengths along the trunk.
@export var crown := Crown.SPHERE
## Conifers: level-1 branches per whorl.
@export_range(2, 12) var whorl_size := 5

@export_group("Foliage")
@export_range(0.0, 3.0) var leaf_density := 1.0
## Leaf card size (realistic), needle spray size (conifer), frond width (palm).
@export_range(0.05, 4.0, 0.01, "suffix:m") var leaf_size := 0.8
## Realistic: leaf tint A. Stylized: lit/outer canopy colour.
@export var leaf_color := Color(0.2, 0.33, 0.09)
## Realistic: leaf tint B (mixed per card). Stylized: inner/shadow canopy colour.
@export var leaf_color_2 := Color(0.33, 0.42, 0.12)
@export_range(0.0, 1.5) var translucency := 0.6
## Stylized broadleaf: canopy puff size.
@export_range(0.2, 4.0) var blob_size := 1.0
## Stylized conifer: tier width.
@export_range(0.3, 2.0) var crown_width := 1.0
@export_range(3, 30) var frond_count := 14
@export_range(0.5, 10.0, 0.1, "suffix:m") var frond_length := 3.5
@export_range(0.0, 2.0) var frond_droop := 0.8
## Hanging moss strands under the branches (any archetype).
@export_range(0.0, 1.0) var hanging_moss := 0.0
@export var moss_color := Color(0.42, 0.45, 0.33)

@export_group("Bark")
@export var bark_color := Color(0.36, 0.3, 0.24)
@export var bark_color_2 := Color(0.17, 0.14, 0.11)
## Moss on the upper sides of branches and around the trunk base.
@export_range(0.0, 1.0) var bark_moss := 0.0
@export_range(0.0, 2.0) var bark_normal := 1.0

@export_group("Detail")
## Trunk sides at LOD0 (branches use fewer, far LODs fewer still).
@export_range(3, 24) var radial_segments := 8
@export_range(0.5, 6.0) var rings_per_meter := 1.5

@export_group("Wind")
@export_range(0.0, 3.0) var wind_bend := 1.0
@export_range(0.0, 3.0) var wind_branch := 1.0
@export_range(0.0, 3.0) var wind_flutter := 1.0


## Hash of every setting. Meshes/materials are cached by it, and editor nodes poll it to rebuild live.
func cache_key() -> int:
	var vals := []
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.usage & PROPERTY_USAGE_STORAGE:
			vals.append(get(prop.name))
	return hash(vals)


## New random shape, same settings.
func reroll() -> void:
	shape_seed = randi() % 1000000
	emit_changed()
	notify_property_list_changed()


# --- scatter-item API (TreeInstances, forest/scatter plugins) -------------------------------------------------

func get_lod_count() -> int:
	return TreeBuilder.LOD_COUNT


## Mesh for one variant (any int; each is a different seed) at one LOD (0 = full detail). Cached and shared.
func get_lod_mesh(variant: int, lod: int) -> Mesh:
	return TreeBuilder.build(self, variant, lod)


## Unscaled size facts for placement, culling and collision:
## {height, trunk_radius, crown_radius, collision_radius, collision_height}.
func get_item_info(variant: int) -> Dictionary:
	return TreeBuilder.info(self, variant)


## Changes whenever any setting changes (poll it in the editor to refresh).
func get_cache_key() -> int:
	return cache_key()


const PRESET_NAMES := [
	"realistic_broadleaf", "realistic_jungle", "realistic_pine", "realistic_palm", "realistic_dead",
	"stylized_broadleaf", "stylized_pine", "stylized_palm", "stylized_dead",
]


static func preset(preset_name: String) -> TreeProfile:
	var p := TreeProfile.new()
	p.resource_name = preset_name
	var v: Dictionary = _PRESETS.get(preset_name, {})
	assert(not v.is_empty(), "unknown tree preset " + preset_name)
	for k in v:
		p.set(k, v[k])
	return p


const _PRESETS := {
	"realistic_broadleaf": {
		"style": Style.REALISTIC, "archetype": Archetype.BROADLEAF,
		"height": 13.0, "height_jitter": 0.18, "trunk_length": 0.55, "trunk_radius": 0.3, "trunk_taper": 0.35,
		"root_flare": 0.6, "lean": 0.06, "gnarl": 0.18,
		"levels": 3, "branch_count": Vector3i(8, 5, 4), "branch_start": 0.4, "branch_angle": Vector3(68, 50, 40),
		"branch_length": Vector3(0.95, 0.55, 0.5), "branch_radius": 0.6, "branch_droop": 0.2, "branch_upturn": 0.25,
		"crown": Crown.SPHERE, "leaf_size": 1.3, "leaf_density": 1.2,
		"leaf_color": Color(0.2, 0.33, 0.09), "leaf_color_2": Color(0.33, 0.42, 0.12),
		"bark_color": Color(0.36, 0.3, 0.24), "bark_color_2": Color(0.17, 0.14, 0.11), "bark_moss": 0.2,
	},
	"realistic_jungle": {
		"style": Style.REALISTIC, "archetype": Archetype.BROADLEAF,
		"height": 20.0, "height_jitter": 0.2, "trunk_length": 0.72, "trunk_radius": 0.5, "trunk_taper": 0.3,
		"root_flare": 1.4, "buttresses": 5, "lean": 0.03, "gnarl": 0.12,
		"levels": 3, "branch_count": Vector3i(7, 5, 3), "branch_start": 0.75, "branch_angle": Vector3(80, 55, 40),
		"branch_length": Vector3(0.7, 0.55, 0.5), "branch_radius": 0.6, "branch_droop": 0.12, "branch_upturn": 0.15,
		"crown": Crown.DOME, "leaf_size": 1.5, "leaf_density": 1.2,
		"leaf_color": Color(0.12, 0.26, 0.07), "leaf_color_2": Color(0.22, 0.35, 0.08),
		"bark_color": Color(0.42, 0.38, 0.3), "bark_color_2": Color(0.2, 0.18, 0.14), "bark_moss": 0.6,
		"hanging_moss": 0.35, "moss_color": Color(0.36, 0.4, 0.26),
	},
	"realistic_pine": {
		"style": Style.REALISTIC, "archetype": Archetype.CONIFER,
		"height": 17.0, "height_jitter": 0.2, "trunk_radius": 0.26, "trunk_taper": 0.05, "root_flare": 0.4,
		"lean": 0.03, "gnarl": 0.06,
		"levels": 2, "branch_count": Vector3i(35, 4, 0), "branch_start": 0.18, "branch_angle": Vector3(100, 35, 0),
		"branch_length": Vector3(0.3, 0.4, 0.0), "branch_radius": 0.35, "branch_droop": 0.5, "branch_upturn": 0.25,
		"crown": Crown.CONE, "whorl_size": 5, "leaf_size": 1.05, "leaf_density": 1.6,
		"leaf_color": Color(0.1, 0.2, 0.1), "leaf_color_2": Color(0.16, 0.26, 0.12), "translucency": 0.35,
		"bark_color": Color(0.33, 0.24, 0.18), "bark_color_2": Color(0.15, 0.11, 0.09),
	},
	"realistic_palm": {
		"style": Style.REALISTIC, "archetype": Archetype.PALM,
		"height": 9.0, "height_jitter": 0.25, "trunk_radius": 0.17, "trunk_taper": 0.65, "root_flare": 0.5,
		"lean": 0.4, "curve": 0.45, "gnarl": 0.05, "levels": 0,
		"frond_count": 16, "frond_length": 3.8, "frond_droop": 0.9, "leaf_size": 1.2,
		"leaf_color": Color(0.24, 0.36, 0.1), "leaf_color_2": Color(0.36, 0.44, 0.14), "translucency": 0.8,
		"bark_color": Color(0.45, 0.4, 0.33), "bark_color_2": Color(0.27, 0.23, 0.18), "rings_per_meter": 2.5,
	},
	"realistic_dead": {
		"style": Style.REALISTIC, "archetype": Archetype.DEAD,
		"height": 10.0, "trunk_length": 0.65, "trunk_radius": 0.28, "trunk_taper": 0.25, "root_flare": 0.7,
		"lean": 0.12, "gnarl": 0.45,
		"levels": 3, "branch_count": Vector3i(6, 4, 3), "branch_start": 0.4, "branch_angle": Vector3(50, 45, 40),
		"branch_length": Vector3(0.7, 0.5, 0.45), "branch_radius": 0.55, "branch_droop": -0.05, "branch_upturn": 0.1,
		"bark_color": Color(0.4, 0.38, 0.35), "bark_color_2": Color(0.18, 0.17, 0.16),
		"hanging_moss": 0.35, "moss_color": Color(0.42, 0.44, 0.36),
	},
	"stylized_broadleaf": {
		"style": Style.STYLIZED, "archetype": Archetype.BROADLEAF,
		"height": 7.0, "height_jitter": 0.2, "trunk_length": 0.55, "trunk_radius": 0.32, "trunk_taper": 0.45,
		"root_flare": 0.5, "lean": 0.05, "gnarl": 0.15,
		"levels": 2, "branch_count": Vector3i(5, 3, 0), "branch_start": 0.55, "branch_angle": Vector3(50, 40, 0),
		"branch_length": Vector3(0.8, 0.5, 0.0), "branch_radius": 0.6, "branch_droop": 0.0, "branch_upturn": 0.4,
		"blob_size": 1.1, "radial_segments": 7,
		"leaf_color": Color(0.45, 0.68, 0.22), "leaf_color_2": Color(0.13, 0.36, 0.16),
		"bark_color": Color(0.45, 0.3, 0.2), "bark_color_2": Color(0.3, 0.19, 0.13),
	},
	"stylized_pine": {
		"style": Style.STYLIZED, "archetype": Archetype.CONIFER,
		"height": 9.0, "height_jitter": 0.25, "trunk_radius": 0.22, "trunk_taper": 0.3, "root_flare": 0.4,
		"lean": 0.03, "gnarl": 0.05, "levels": 0, "crown_width": 1.0, "radial_segments": 6,
		"leaf_color": Color(0.25, 0.55, 0.35), "leaf_color_2": Color(0.08, 0.25, 0.2),
		"bark_color": Color(0.42, 0.28, 0.2), "bark_color_2": Color(0.26, 0.17, 0.12),
	},
	"stylized_palm": {
		"style": Style.STYLIZED, "archetype": Archetype.PALM,
		"height": 7.0, "height_jitter": 0.25, "trunk_radius": 0.18, "trunk_taper": 0.7, "root_flare": 0.4,
		"lean": 0.45, "curve": 0.5, "gnarl": 0.04, "levels": 0, "radial_segments": 7,
		"frond_count": 9, "frond_length": 3.0, "frond_droop": 1.0, "leaf_size": 1.0,
		"leaf_color": Color(0.5, 0.75, 0.25), "leaf_color_2": Color(0.18, 0.42, 0.15),
		"bark_color": Color(0.62, 0.48, 0.32), "bark_color_2": Color(0.42, 0.3, 0.2), "rings_per_meter": 2.0,
	},
	"stylized_dead": {
		"style": Style.STYLIZED, "archetype": Archetype.DEAD,
		"height": 6.0, "trunk_length": 0.6, "trunk_radius": 0.26, "trunk_taper": 0.25, "root_flare": 0.8,
		"lean": 0.15, "gnarl": 0.5, "radial_segments": 6,
		"levels": 2, "branch_count": Vector3i(5, 3, 0), "branch_start": 0.45, "branch_angle": Vector3(55, 45, 0),
		"branch_length": Vector3(0.8, 0.5, 0.0), "branch_radius": 0.5, "branch_droop": -0.1, "branch_upturn": 0.2,
		"bark_color": Color(0.38, 0.33, 0.4), "bark_color_2": Color(0.18, 0.15, 0.2),
		"hanging_moss": 0.3, "moss_color": Color(0.35, 0.4, 0.3),
	},
}
