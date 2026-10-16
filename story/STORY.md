# Tidewater — Story Bible

> Originally taken from the Three.js prototype (story text, game script and cinematic shot list). The prototype was removed on 2026-10-14 (moved to the macOS Trash as `tidewater-threejs-prototype-2026-10-14`); this file and `story/chapters/` are now the source of truth.
>
> **The game is first person.** Previs plays in first person by default (`Cam_FP`, the player's eyes); press V for the cinematic coverage cameras.

> **Island map (PROPOSED, 2026-10-16):** [`MAP.md`](MAP.md) lays out the whole route from the beach to the summit ritual, with a 3D miniature (`game/map/island_miniature.tscn`). Stages after the Old Village are suggestions only; it also lists conflicts with the chapters and backstory below.

## Logline
Searching for their missing brother, a sibling lands on a remote island the military bought and abandoned. The black stone offshore rises, something comes out of the water, and the only way forward is the cable car up to the research center on the mountain.

## Premise
Sgt. **Elias** served with Research Detachment 9 of the Joint Maritime Intelligence Directorate on a small island bought in secret (program **TIDEWATER**). The island's original people were wiped out long ago, and their culture is gone; only ruins and a few mainland folk remember their warnings about the black stone. Behind the old harbor sits the detachment's **base camp**, a supply depot for a **research center at the top of the island's mountain**, reached only by a **cargo cable car**. The detachment has gone quiet; Elias went up the mountain. Elias's sibling pays a fishing captain to take them across. The captain won't set foot ashore: if the rock out past the point rises, no boat will come.

## Setting
- **Location:** an unnamed island off a fishing coast; dark conifer hills, an overgrown trail, a ravine, the old fishing harbor, and the closed military base behind a perimeter fence.
- **Time period:** present day, one night.
- **Structure:** linear, explorable areas with puzzles, **one scene per area** (loaded in and out as the player moves on). All areas share world coordinates so neighbours line up.
- **Areas (levels):** `res://game/levels/`
  | # | Area | Chapter | Notes |
  |---|------|---------|-------|
  | A01 | Beach | 1 | landing; the black stone offshore |
  | A02 | Trail | 1 | fallen tree, ruined wall, shrine |
  | A03 | Ravine | 1 | scaffold (collapses: no way back) |
  | A04 | Old Harbor | 1 | yard, shed, watchtower, gate |
  | A05 | Base Camp | 2 | supply yard, substation, barracks, cable car lower station; the mountain rises behind |
  | A06 | Ropeway: the line, pylons, the stopped car | 3 | built (first part) |
  | A07 | Service path: forest, scree, old stream + bridge | 3 | built (first part) |
  | A08 | Hollow Edge (landing in the old village) | 4 | blockout built |
| A09 | Village Lanes (homes, guest house, healing wall) | 4 | blockout built |
| A10 | Festival Ring (stone ring, dig site, generator, cargo lift) | 4 | blockout built |
| A11 | Burned Quarter (the massacre, the creature) | 4 | blockout built |
| A12+ | Research center approach | 5+ | not designed |

## Cast
| Name | Role | Wants | Fears / secret |
|------|------|-------|----------------|
| The protagonist (unnamed) | Elias's sibling; player character | Find Elias | That they came too late. (Previs stand-in: Synty female pawn, blue-grey.) |
| Sgt. Elias | Missing brother, duty sergeant of Det. 9 | Protect the survey team at the research center | Went up the mountain; sent car 1 back down for survivors and nobody came; tells whoever hears him not to follow |
| The Captain | Fishing boat skipper | To be gone before the stone rises | Won't touch the sand |
| Cpl. Reyes | Det. 9 maintenance (dead) | Fix the searchlight, see what walks the yard | Found on the watchtower, nails worn to the quick |
| Pvt. Okafor | Pier watch (mentioned only) | — | Heard knocking under the pier |
| "It" | The creature from the hollow | — | Stalks the player; tall, thin, black (previs stand-in: black primitive figure) |

## The threat — rules of the horror
From the prototype (`src/world/stalker.js`), keep consistent across chapters:
- It **sees** you if you're close, in front of it, or your torch is on.
- It **hears** you sprint (~16 m), walk (~7 m) or crouch (~2.5 m) — and loud events (the breaker bang).
- **Lockers** make you invisible to it. If it catches you → jumpscare → last checkpoint.
- Early on it only **appears and vanishes** (a figure that's gone when you look; footfalls on the roof; a figure under the searchlight). It escalates to entering rooms (Ch2 Encounters 1–2) and finally running at you (the hatch).
- Folklore: *When the black stone rises, go inside, do not answer.* If it calls you by name, don't answer.

## Themes & tone
Grief and guilt (the photo, "I'm sorry"), institutional cover-up versus local knowledge, isolation (the boat won't come back). Slow-burn dread: sound and absence first, the creature seen only in glimpses until the end of Chapter 2.

## Chapter index
| # | Title | One-line beat | Level | Previs status |
|---|-------|---------------|-------|---------------|
| 01 | The Old Harbor | Dropped on the beach, the way back collapses; Reyes's body on the tower; the gate chain is cut as the stone rises | A01–A04 | draft — 5:02, 20 shots |
| 02 | Base Camp | The camp supplies the research center up the mountain; power the cable car (generator, fuel, breakers), hear Elias on the intercom, leave in car 2 as it charges | A05 (+A04) | draft (reworked, beats **PROPOSED**) — 4:49, 15 shots |
| 03 | The Line | The ride up: car 2 shakes, something outside, the grip fails and the car stops; climb out; the lit fenced path through a forest, over an old stream | A06 + A07 | draft, first part only — the rest **not designed** |

| 04 | The Old Village | **PROPOSED:** the fall lands the player in the village ruins; the story is found in carvings, a log and dig tags; the creature is revealed as the colonist; leave by the cargo lift | A08–A11 | draft — 8:23.0, 21 shots |
| 05 | The Service Path | **PROPOSED:** the lit path, stream and forest (built in Ch3's previs for now), leading to the research center | A07 (+ A12+) | not started; shots currently live in Ch3 |

<!-- Previs status: not started · draft · in review · approved -->

## Previs slate
Every playblast shows, top-right: `CH 02 · SHOT 09 — Footsteps at the door` / `AREA 05 · Base Camp`. Use those numbers when giving notes. Shot names and areas come from each chapter's `chapter_meta.json`.

## Open questions
- Chapter 4 Old Village: is the crystal in the skeleton's hand pickable, and is it one of the three ritual crystals or a separate healing crystal? (Backstory Part 3 says one crystal stayed where the village stood; Part 4 says the company recovered all three from the ruins.)
- Chapter 3: what's inside car 1, is the creature on the line during the ride, what puzzles are on the mountain path?
- Is the black stone / "came out of the water" enough of an origin for the creature now the hollow is gone?
- Protagonist's name and gender are not set anywhere in the text; the previs uses a female Synty pawn purely as a readable stand-in.
- The prototype README mentions a survey post and a cable car to a hilltop research center "waiting on three decisions" — not in any chapter yet.
- Chapter 1's optional documents (memo, work order, Reyes's tape, pier knocking) exist in the game script but not in the cinematic; they're not in the previs playblast either.
