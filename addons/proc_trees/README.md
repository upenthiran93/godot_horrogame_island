# Tree system

Procedural trees for Godot 4.7 (Forward+). One recipe (`TreeProfile`) grows realistic or stylized trees, at any count, with 3 LODs. There are no imported models, and the only texture is a leaf atlas the tools paint for you.

**Demo:** run `res://game/systems/trees/demo/tree_demo.tscn`. Hold the right mouse button and use WASD to fly (Q/E down/up, Shift fast). 1/2/3 sets the wind (calm, breeze, storm), F toggles the forests, and the HUD shows fps, draw calls and triangles.

## Pieces

| | |
|---|---|
| `TreeProfile` (Resource) | The recipe: style (REALISTIC / STYLIZED), archetype (BROADLEAF / CONIFER / PALM / DEAD), trunk, branches, foliage, bark, wind. Edit it in the inspector and trees update live in the editor. |
| `presets/*.tres` | `realistic_broadleaf`, `realistic_jungle` (buttress roots, moss), `realistic_pine`, `realistic_palm`, `realistic_dead` (hanging moss), `stylized_broadleaf`, `stylized_pine`, `stylized_palm`, `stylized_dead`. Duplicate one before tweaking it. |
| `ProcTree` (MeshInstance3D) | One hand-placed tree (hero trees, set dressing). Has a runtime trunk collider. |
| `TreeForest` (Node3D) | Scatters thousands of trees over an area, snapped to the ground colliders. Supports slope and height limits, a density-mask texture, and a code filter (`placement_filter`). Use **Rebuild** in the inspector to regenerate. |
| `TreeWind` (Node) | Sets the global wind (direction, strength, gustiness). Animate `strength` for storms. |
| `TreeBuilder` | `TreeBuilder.build(profile, variant, lod)` returns an `ArrayMesh` (surface 0 bark, surface 1 foliage). Results are cached. |

Example: drop a `TreeForest` into a level such as `a02_trail.tscn`, set `area`, add a few presets to `profiles`, set `min_height` above the waterline, and it snaps to the level's terrain collider.

## Why it's fast

- **No node per tree.** Each chunk, tree type and LOD is one MultiMesh, and distant LODs use bigger chunks (32 / 64 / 128 m), so there are fewer draw calls.
- **Shared meshes.** Every tree of a profile+variant shares one mesh per LOD. Placement comes from a seed, so scenes only store settings and nothing is baked into `.tscn` files.
- **3 LODs grown from one skeleton,** so the silhouette holds between them. Triangle budgets for the presets:

  | | LOD0 | LOD1 | LOD2 |
  |---|---|---|---|
  | realistic | ~1–6k | ~0.3–1.8k | ~0.1–0.5k |
  | stylized | ~0.4–2.4k | ~0.1–1.3k | <0.3k |

- **Per-tree dithered crossfade between LODs,** done in the shader. Two LODs fill complementary pixels, so there is no popping and everything stays in the opaque pipeline (alpha scissor, no sorting). Fully faded instances collapse in the vertex shader. Visibility ranges skip whole chunks outside a LOD's band.
- **Cheap shadows.** Shadows were about 2/3 of the forest's GPU cost in testing. Trees in the LOD1 band cast their shadow from the LOD2 mesh, and LOD2 casts none (`cheap_shadows`, `far_shadows`).
- **Wind runs entirely in the vertex shader:** trunk sway, branch bob and leaf flutter, from weights baked into UV2 and vertex colour.
- **Trunk collision goes straight to the PhysicsServer** (one static body per chunk, no nodes). It's runtime only.
- **Compressed vertex attributes**, plus a coverage-preserving alpha trick so distant canopies don't thin out.

Measured on an M3 Pro: about 3,900 trees in the demo build in ~0.7 s at load. Render CPU is ~0.7 ms per frame, and a fly-through holds the 120 Hz display cap at 1152×648. At 1440p it averages ~117 fps with 1% lows of ~100. Benchmark it yourself:

```
godot --path . --disable-vsync res://game/systems/trees/demo/tree_demo.tscn -- --bench [--no-shadows] [--only=realistic|stylized] [--lod=30,80,260]
```

## Tuning

- `TreeForest.lod_distances` (LOD0→1, LOD1→2, fade-out) is the biggest knob. With the island's fog, the last value can drop to the fog distance.
- `variants` adds variety, but each variant is its own draw call per chunk, so keep it at 2–3.
- Sun shadows: `directional_shadow_max_distance` and the split count matter more than tree detail.
- Foliage cost is mostly overdraw from alpha-cut cards. `leaf_density` and `leaf_size` on the profile trade fill rate for fullness.

## Setup notes

- The shaders read two global uniforms, `tree_wind` and `tree_view_pos`, defined in `project.godot` under `[shader_globals]`. Copying the system to another project means copying those too.
- `TreeForest` sends the camera position to the shaders every frame (including the editor camera). If a scene uses only `ProcTree`s, LOD fades aren't used, so nothing is needed.
- Regenerate the atlas, presets and demo with `godot --headless --path . --script res://tools/build_tree_assets.gd [-- --force]`. Without `--force` it never overwrites.
