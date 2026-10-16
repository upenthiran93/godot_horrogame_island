# Chapter 01 — The Old Harbor

## Summary
The captain drops the protagonist off the beach and leaves. They follow the overgrown trail inland (fallen tree, ruined wall, a shrine with fresh offerings), cross the ravine on a rotten scaffold that collapses behind them — no way back. At the old harbor a chained military gate blocks the way; the maintenance shed's sign-out sheet says Reyes took the bolt cutters up the watchtower and never came down. Something traps them in the shed, then lets them out. On the tower: Reyes's body, the cutters, and a searchlight that switches itself on to show a figure in the yard. They run, cut the chain, the gate opens — and far out at sea the black stone rises.

## Location
- **Levels (one scene per area):** A01 Beach, A02 Trail, A03 Ravine, A04 Old Harbor (`res://game/levels/a0N_*/`); A05 Base Camp is visible through the gate in the last shot
- **Markers used:** `Mk_Ch01_BoatAnchor`, `Mk_Ch01_Landing`, `Mk_Ch01_FallenTree`, `Mk_Ch01_RuinedWall`, `Mk_Ch01_Shrine`, `Mk_Ch01_ScaffoldBase`, `Mk_Ch01_ScaffoldPlatform`, `Mk_Ch01_CliffTop`, `Mk_Ch01_HarborEntry`, `Mk_Ch01_WarningBoard`, `Mk_Ch01_Gate`, `Mk_Ch01_Insignia`, `Mk_Ch01_ShedDoor`, `Mk_Ch01_SignOut`, `Mk_Ch01_TowerBase`, `Mk_Ch01_TowerTop`, `Mk_Ch01_ReyesBody`, `Mk_Ch01_StalkerSpot`, `Mk_Ch01_BlackStone`
- **Level nodes animated:** `Dynamic/Scaffold`, `ShedDoor`, `BoltCutters`, `Searchlight` (light + beam), `GateChain`, `GateLeft`, `GateRight`, `ShiftingRock`

## Characters present
Protagonist, the Captain (in the boat), Cpl. Reyes (body), the creature (glimpses).

## Beats
| # | Beat | Target time | Notes (camera / sound / mood) |
|---|------|-------------|-------------------------------|
| 1 | Title + chapter card | 0:00 | black |
| 2 | The crossing — the captain's warning (7 lines) | 0:10 | slow dolly in from the sea onto the beach |
| 3 | The boat leaves | 1:01 | locked-off, the boat's lamp shrinking |
| 4 | Ashore, fallen tree (crouch), ruined wall (climb) | 1:10 | follow cam → side cams |
| 5 | The shrine — whisper behind, offerings note | 1:39 | locked-off, first unease |
| 6 | Scaffold creaks, lurches | 1:55 | follow cam, three escalating creaks |
| 7 | Collapse — point of no return | 2:19 | wide, camera shake |
| 8 | The harbor, the chained gate, the insignia | 2:28 | |
| 9 | The shed: sign-out sheet → door slams → footfalls on the roof → door opens | 2:58 | 29 s locked-off — the slow scare |
| 10 | Tower climb, Reyes's body, cutters | 3:27 | crane-style cam tracks the climb |
| 11 | Searchlight snaps on: a figure in the yard, flicker, gone | 4:17 | stinger |
| 12 | Run for the gate, footsteps behind | 4:31 | |
| 13 | Cut the chain, the gate opens, figure beyond; the rumble — the stone rises | 4:41 | fade to black |

## Scares
| Setup | Payoff | Timing |
|-------|--------|--------|
| Shrine: offerings are fresh | Whisper right behind you | 1:44 |
| Scaffold creaks louder each time | It collapses behind you | 1:58 → 2:19 |
| Sign-out: "Reyes never came down" | Door slams; footfalls on the roof; door creaks open on its own | 3:10 → 3:20 |
| Searchlight is dead | It switches on by itself and shows the figure, then flickers off | 4:17 |
| Running alone | Footsteps and breathing right behind | 4:32 |
| Gate opens | A figure standing beyond it; then the ground rumbles | 4:45 → 4:55 |

## Narration / dialogue (placeholder text)
All lines are taken verbatim from `src/story/chapter1Text.js` (captain's intro, inner thoughts, notes: shrine, insignia, sign-out sheet, Reyes's body). Sound effects are shown as `[SFX]` captions top-left.

## Previs
- **Status:** draft
- **Scene:** `res://previs/chapters/ch01_the_old_harbor/chapter01_the_old_harbor.tscn`
- **Length:** 302.0 s (5:02), 20 shots, one camera per shot (`Cam_NN_Name`)
- **Views:** first person by default (`Cam_FP`, 1.64 m eye / 1.0 m crouched, built from the protagonist's blocking + `fp_gaze.json`); V switches to the cinematic coverage cameras.
- **Gaze script:** `res://previs/chapters/ch01_the_old_harbor/fp_gaze.json` — what the player looks at, per shot. Rebuild `Cam_FP` with `godot --headless --path . --script res://tools/add_fp_camera.gd`.

| Beat | Marker | Timestamp | Length | Area |
|------|--------|-----------|--------|------|
| Title | `s01_title` | 0:00.0 | 6.0 s | — |
| Chapter 1 | `s02_chapter_1` | 0:06.0 | 4.0 s | — |
| The crossing | `s03_the_crossing` | 0:10.0 | 51.0 s | AREA 01 · Beach |
| The boat leaves | `s04_the_boat_leaves` | 1:01.0 | 9.0 s | AREA 01 · Beach |
| Ashore | `s05_ashore` | 1:10.0 | 7.0 s | AREA 01 · Beach |
| The fallen tree | `s06_the_fallen_tree` | 1:17.0 | 12.0 s | AREA 02 · Trail |
| The ruined wall | `s07_the_ruined_wall` | 1:29.0 | 10.0 s | AREA 02 · Trail |
| The shrine | `s08_the_shrine` | 1:39.0 | 16.0 s | AREA 02 · Trail |
| The scaffold | `s09_the_scaffold` | 1:55.0 | 24.0 s | AREA 03 · Ravine |
| The collapse | `s10_the_collapse` | 2:19.0 | 9.0 s | AREA 03 · Ravine |
| The harbor | `s11_the_harbor` | 2:28.0 | 9.0 s | AREA 04 · Old Harbor |
| The gate | `s12_the_gate` | 2:37.0 | 13.0 s | AREA 04 · Old Harbor |
| The maintenance shed | `s13_the_maintenance_shed` | 2:50.0 | 8.0 s | AREA 04 · Old Harbor |
| The sign-out sheet | `s14_the_sign_out_sheet` | 2:58.0 | 29.0 s | AREA 04 · Old Harbor |
| Out to the tower | `s15_out_to_the_tower` | 3:27.0 | 9.0 s | AREA 04 · Old Harbor |
| The watchtower | `s16_the_watchtower` | 3:36.0 | 31.0 s | AREA 04 · Old Harbor |
| The body | `s17_the_body` | 4:07.0 | 10.0 s | AREA 04 · Old Harbor |
| The searchlight | `s18_the_searchlight` | 4:17.0 | 14.0 s | AREA 04 · Old Harbor |
| Run for the gate | `s19_run_for_the_gate` | 4:31.0 | 10.0 s | AREA 04 · Old Harbor |
| The chain | `s20_the_chain` | 4:41.0 | 21.0 s | AREA 04 · Old Harbor |

## Review notes
- 2026-10-14: First previs built from the prototype cinematic shot list (same timings, positions and text). Differences from the cinematic:
  - *The collapse* camera moved from (-8, 6.5, 30) to (-2.5, 7, 21): the original spot is inside the hillside pines in the Godot blockout.
  - *The chain* runs 21 s instead of 17 s and adds the rumble / rising stone + "(Was that... the ground? Or the sea?)" beat that `chapter1.js` plays when the gate opens, then fades to black.
- Things to judge on first watch: the crossing is 51 s of captain monologue before the protagonist sets foot ashore; the sign-out shot is a 29 s locked-off scare.
- 2026-10-14: First-person view added and made the default. Gaze choices to review: in the boat the player looks at the captain, out to the black stone on "the dark water past the point", and at the shore on "a trail in the brush", then is on the beach watching the boat go; at the shrine the player whips round on the whisper; in the shed they look at the door when it slams and track the footfalls across the ceiling; on the tower the player stands beside the searchlight housing (it blocked the view of the yard) so the figure is centre-frame in the beam.
- 2026-10-14: The shrine stop point moved 1.1 m back (to shrine.x + 2.4) — in first person the old spot was nose-to-plinth. Affects the cinematic shot too.
- 2026-10-14: The level is split into one scene per area (A01–A04 for this chapter); each shot loads only its area. The playblast slate (top-right) shows chapter · shot · area.
