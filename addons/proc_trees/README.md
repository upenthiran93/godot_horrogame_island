# Proc Trees (Godot 4.7 plugin)

Procedural trees, realistic or stylized, from one editable recipe (`TreeProfile`). Every tree is generated in the engine: there are no imported models, and the only texture is a leaf atlas the plugin paints itself. It includes 3 LODs, wind, cheap rendering for thousands of trees, and an API that a separate forest/scatter plugin can build on.

## Install

1. Copy the `addons/proc_trees/` folder into a Godot 4.4+ project (tested on 4.7, Forward+). Keep the folder name, because paths inside it start with `res://addons/proc_trees/`.
2. Go to **Project → Project Settings → Plugins** and enable **Proc Trees**. That adds the shader globals `tree_wind` and `tree_view_pos` to Project Settings. If a project never enables the plugin, they are registered at runtime instead, so exported games work either way.
3. A **Trees** menu appears in the 3D editor toolbar.

Demo: **Trees → Open Demo Scene** (or run `res://addons/proc_trees/demo/tree_demo.tscn`). Fly with the right mouse button + WASD (Q/E down/up, Shift fast). 1/2/3 sets the wind (calm, breeze, storm), F toggles the forests, and the HUD shows fps, draw calls and triangles.

## Making and editing trees

- **Trees → Add Tree → (preset)** adds a `ProcTree` where the editor camera is looking. It gets **its own copy** of the preset, so edit it freely in the inspector (Profile → expand). The tree rebuilds live.
- **Shape seed / Reroll shape** (on the profile) picks a new random shape. All other settings keep the current shape when you change them, so you can tune colours, sizes and density without the tree jumping around.
- **New variant** (on the `ProcTree`) shows another seed of the same profile. Forests mix variants.
- To save a recipe you like, use the inspector's resource menu on the profile and choose **Save As… → `my_tree.tres`**. Files in `presets/` show up in the **Add Tree** menu.
- **Bake mesh to file** (on a `ProcTree`, or **Trees → Bake Selected Trees**) exports a normal mesh resource (`res://baked_trees/…res`) for use anywhere.

Profile settings (inspector groups):
- **Style:** REALISTIC (bark texture, alpha-cut leaf cards, translucent leaves) or STYLIZED (toon light, solid canopy).
- **Archetype:** BROADLEAF, CONIFER, PALM or DEAD.
- **Trunk:** height, radius, taper, root flare, buttresses, lean, palm curve, gnarl.
- **Branches:** up to 3 levels, with count, angle, length, droop and crown shape per level.
- **Foliage:** leaf size, density and colours, translucency, puff size, conifer tiers, palm fronds, hanging moss.
- **Bark:** colours, moss, normal strength.
- **Detail:** sides and rings per metre at LOD0.
- **Wind:** bend, branch, flutter.

Nine presets come with the plugin: `realistic_broadleaf`, `realistic_jungle` (buttress roots, moss), `realistic_pine`, `realistic_palm`, `realistic_dead` (hanging moss), and `stylized_broadleaf`, `stylized_pine`, `stylized_palm`, `stylized_dead`.

## Nodes and classes

| | |
|---|---|
| `TreeProfile` (Resource) | The recipe. Also implements the scatter-item API below. |
| `ProcTree` (MeshInstance3D) | One hand-placed tree: hero trees, set dressing. Runtime trunk collider, bake button. |
| `TreeInstances` (Node3D) | **The renderer.** Add trees from code with `add_tree()` then `commit()`. Chunked MultiMeshes, LOD crossfade, cheap shadows, collision. This is what a forest plugin uses. |
| `TreeForest` (TreeInstances) | A simple scatter over a rectangle, snapped to ground colliders, with slope/height limits, a density-mask texture and `placement_filter`. Also the reference example for a forest plugin. |
| `TreeWind` (Node) | Global wind (direction, strength, gustiness). Animate `strength` for storms. |
| `TreeBuilder` | `TreeBuilder.build(profile, variant, lod)` returns a cached `ArrayMesh` (surface 0 bark, surface 1 foliage). |

## For a forest / scatter plugin

The future Forest plugin decides **where** trees go. This plugin handles **what** they look like and **how** they're drawn. Keep the Forest plugin depending on the three things below only, and the two plugins stay independent.

### 1. Draw through `TreeInstances` (recommended)

```gdscript
var trees := TreeInstances.new()          # or extend it, like TreeForest does
trees.lod_distances = Vector3(30, 80, 260)
my_forest_node.add_child(trees)
for p in my_points:                        # your placement: brushes, masks, biomes, rules...
	trees.add_tree(profile, variant, Transform3D(basis, p))   # local to `trees`; scale is fine
trees.commit()                             # build draws + collision; call again after changes
# trees.clear_trees() + add_tree()... + commit() to redo; trees.instance_count for stats
```

`add_tree(item, variant, transform, tint := Vector3.ZERO, phase := -1.0)`: `tint` is a small RGB offset for per-tree colour variation, and `phase` offsets the wind sway (random by default). In the editor, `TreeInstances` re-commits automatically when an item's settings change (`auto_refresh_items`).

### 2. The scatter-item API

`TreeInstances` accepts any `Resource` with these methods, not only `TreeProfile`. A forest plugin can therefore define rocks, bushes or grass clumps as items and draw them through the same renderer:

| Method | Returns |
|---|---|
| `get_lod_count() -> int` | number of LODs (1–3) |
| `get_lod_mesh(variant: int, lod: int) -> Mesh` | the mesh; should be cached and shared |
| `get_item_info(variant: int) -> Dictionary` | `height` (for culling); optional `collision_radius` + `collision_height` (trunk cylinder); `crown_radius` (spacing hint) |
| `get_cache_key() -> int` *(optional)* | changes when settings change, for editor auto-refresh |

`TreeProfile` also emits `changed` when edited in the inspector (the plugin does this), so a forest node can connect to it.

### 3. Drawing trees yourself (only if you need your own renderer)

Use `profile.get_lod_mesh()` and follow the shader contract:
- **Instance uniform** `lod_fade` (`Vector4` metres: fade-in start, end, fade-out start, end) on each `GeometryInstance3D`, e.g. `set_instance_shader_parameter("lod_fade", TreeInstances.lod_band(lod, 3, distances, fade))`.
- **MultiMesh custom data** (`use_custom_data = true`): rgb = tint offset, a = wind phase 0..1.
- **Call `TreeInstances.update_view_position(self)` every frame** so fades use the real camera. It's cheap and runs once per frame however often it's called.
- **Global wind:** use a `TreeWind` node, or `RenderingServer.global_shader_parameter_set("tree_wind", Vector4(dir_x, dir_z, strength, gustiness))`.

## Why it's fast

- **No node per tree.** Each chunk, item variant and LOD is one MultiMesh, and distant LODs use bigger chunks (32 / 64 / 128 m), so there are fewer draw calls.
- **Shared meshes.** Every tree of a profile+variant shares one mesh per LOD. `TreeForest` placement comes from a seed, so scenes only store settings.
- **3 LODs grown from one skeleton,** so the silhouette holds between them. Triangle budgets for the presets:

  | | LOD0 | LOD1 | LOD2 |
  |---|---|---|---|
  | realistic | ~1–6k | ~0.3–1.8k | ~0.1–0.5k |
  | stylized | ~0.4–2.4k | ~0.1–1.3k | <0.3k |

- **Per-tree dithered crossfade between LODs,** done in the shader. Two LODs fill complementary pixels, so there's no popping and everything stays opaque (alpha scissor, no sorting). Fully faded instances collapse in the vertex shader, and visibility ranges skip whole chunks outside a LOD's band.
- **Cheap shadows.** Shadows were about 2/3 of a forest's GPU cost in testing. LOD1 trees cast their shadow from the LOD2 mesh, and LOD2 casts none (`cheap_shadows`, `far_shadows`).
- **Wind runs entirely in the vertex shader** (trunk sway, branch bob, leaf flutter). Trunk collision goes straight to the PhysicsServer: one static body per chunk, no nodes.

Measured on an M3 Pro (demo, ~3,900 trees): build at load ~0.7 s, render CPU ~0.7 ms/frame. GPU cost depends mostly on shadows and on fill from realistic foliage. Stylized forests are much cheaper. Benchmark it:

```
godot --path . --disable-vsync res://addons/proc_trees/demo/tree_demo.tscn -- --bench [--no-shadows] [--only=realistic|stylized] [--lod=30,80,260]
```

## Tuning

- `lod_distances` (LOD0→1, LOD1→2, fade-out) is the biggest knob. With fog, the last value can drop to the fog distance.
- Each variant is its own draw call per chunk, so keep `variants` at 2–3.
- For the sun, `directional_shadow_max_distance` and the split count matter more than tree detail.
- `leaf_density` / `leaf_size` trade overdraw (fill rate) for fuller crowns.

## Files

`core/` (profile, builder, materials), `nodes/` (ProcTree, TreeInstances, TreeForest, TreeWind), `shaders/`, `textures/leaf_atlas.png` (painted by the tool), `presets/`, `demo/`, `icons/`, `plugin.gd`.

Regenerate the atlas, presets and demo with `godot --headless --path . --script res://addons/proc_trees/tools/build_assets.gd [-- --force]`. Without `--force` it never overwrites.
