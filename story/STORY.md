# Tidewater — Story Bible

> **Genre:** First-Person Cosmic Survival Horror (~2.5 hours / 6 Chapters).
> **The game is first person.** Previs plays in first person by default (`Cam_FP`, the player's eyes); press V for the cinematic coverage cameras.
> **Lore & Mythos:** [`BACKSTORY.md`](BACKSTORY.md) · **Full Island Route:** [`MAP.md`](MAP.md) (`game/map/island_miniature.tscn`).

---

## Logline
Lured by a spliced voicemail from their missing brother, a sibling lands on a remote volcanic island bought by a dying billionaire. As an ancient black monolith rises from the sea and an 18th-century abyssal stalker hunts the fog, the player must descend through drowned colonial ruins and bioluminescent sea-caverns into the mountain's heart—before the billionaire trapped inside the island's electrical grid uses them to complete a forbidden cosmic ritual.

## Premise
**Sgt. Elias** served as head of security for **Research Detachment 9** (a front for **Julian Vane's** private biotech firm, **Program TIDEWATER**) on an uncharted island sitting above an oceanic trench. Beneath the island sleeps **Y'ha-Nthlei ("The Sleeper in the Trench")**—a vast cosmic entity whose resonance heals those who surrender their ego willingly, but mutates anyone who tries to steal its power by force into an immortal abyssal hound (**The Shepherd**).

Three nights ago, Vane tried to use a **Neural Siphon Array** at the mountain's summit to steal cellular immortality through lead researcher **Dr. Mara Chen**. Elias interrupted the ritual by ripping **Tide-Stone #3** from the circle. The backfire fused Vane's consciousness into the island's electrical grid while leaving his body rotting in a life-support pod, and infected Elias with the Deep Sickness as he fled into the unpowered caves below with the third stone. Using spliced recordings of Elias's voice, Vane lures the protagonist to the island to retrieve the stone for him.

---

## Setting & Structure
- **Location:** A steep volcanic island off a fog-bound fishing coast; dark conifer ridges, an overgrown ravine, the abandoned military harbor and base camp, a sunken 18th-century stone village, the 1784 wreck of the *HMS Madrigal*, bioluminescent subterranean caverns, and the brutalist research facilities crowning the summit crater.
- **Time period:** Present day, one night (from midnight until dawn).
- **Target playtime:** ~2.5 hours (150 minutes) across **6 Chapters** (17 stages, `S01–S17`).
- **Structure:** Linear, interconnected explorable areas with survival horror puzzles and stalker encounters, **one scene per area** (`res://game/levels/`), sharing world coordinates.

### Areas (Levels)
| # | Area | Stage | Chapter | Status / Notes |
|---|------|-------|---------|----------------|
| A01 | Beach | S01 | 1 | Built — landing; the Black Stone offshore |
| A02 | Trail | S02 | 1 | Built — fallen tree, ruined wall, three-hollow shrine |
| A03 | Ravine | S03 | 1 | Built — rotten scaffold (collapses: point of no return) |
| A04 | Old Harbor | S04 | 1 | Built — yard, shed, watchtower, Reyes's body, gate |
| A05 | Base Camp | S05 | 2 | Built — supply yard, substation, barracks, cable car lower station |
| A06 | Ropeway | S06–S07 | 3 | Built — the cable line, pylons, stopped car 2, ladder fall |
| A08 | Hollow Edge | S08 | 4 | Built — landing in the sunken village, drag marks, buried steps |
| A09 | Village Lanes | S08 | 4 | Built — homes, year marks, healing wall, guest house (1784 log) |
| A10 | Festival Ring | S08 | 4 | Built — standing-stone ring, Vane's dig site, generator, cargo lift |
| A11 | Burned Quarter | S08 | 4 | Built — 1784 massacre site, Pale Shard in skeleton's hand, The Shepherd |
| A07 | Service Path | S08→S09 | 4 / 5 | Built — lit fenced path, stream & plank bridge (Shepherd ambush drops player into West Gully) |
| A12 | West Gully | S09 | 5 | Proposed — steep scree descent (`120m → 3m`) to the West Cove |
| A13 | Wreck of *HMS Madrigal* | S10 | 5 | Proposed — 1784 colonial ship hull, tidal gun-deck puzzle, Locke's iron cage |
| A14 | The Sea Cave | S11 | 5 | Proposed — waterline cave, calcified 1784 crew in the limestone walls |
| A15 | Smuggler's Tunnel | S12 | 5 | Proposed — flooded timber-and-concrete tunnel; water-alcove stealth |
| A16–A18 | Abyssal Caverns | S13 | 5 | Proposed — 170m climb inside the mountain; the Deep Chorus statues, the Sleeper's Eye below |
| A19 | Sub-Level Bunker B | S14 | 5 | Proposed — sealed cave hatch; finding the real Elias & **Tide-Stone #3**; 75m lift shaft |
| A20–A21 | Research Center | S15 | 6 | Proposed — upper cable station, acoustics lab, Vane's automated building hazards |
| A22 | Neural Siphon Facility | S16 | 6 | Proposed — Vane's half-mutated body in the Faraday Pod; Siphon routing console |
| A23 | Summit Crater Circle | S17 | 6 | Proposed — the open Void Breach in the sky, the Three Sockets, final Shepherd encounter & 3 Endings |

---

## Cast
| Name | Role | Wants | Cosmic Horror Secret / Fate |
|------|------|-------|-----------------------------|
| **The Protagonist** | Elias's younger sibling; player character | Find Elias and bring him home | Lured by a fake voicemail; the only pair of living human hands Vane can use |
| **Sgt. Elias** | Missing brother; Head of Security, Det. 9 | Protect Dr. Mara Chen; keep Tide-Stone #3 away from Vane | Ripped Stone #3 from the Summit Circle 3 nights ago; dying of the Deep Sickness in Bunker B (`S14`) while guarding the stone |
| **Dr. Mara Chen** | Lead Marine Bio-Acoustician (Elias's partner) | Decode the village carvings; respect the Cosmic Law | Used by Vane as the unwilling Siphon Conduit; her body was consumed by the breach, her mind scattered as harmonic **Echoes** guiding the player via the Pale Shard |
| **Julian Vane** | Trillionaire founder of Vane Bio-Marine ("The Owner") | Cure his prion disease and achieve immortality *without* losing his ego | His mind was burned into the island's electrical grid during the blast; his physical body in `S16` is mutating into a second Shepherd unless you complete the Summit circuit |
| **Capt. Alistair Locke ("The Shepherd")** | 1784 Captain of the *HMS Madrigal*; the stalking creature | Drag all trespassers into the dark; guard the wound he made | Slaughtered the village in 1784 to steal the stones by force; cursed by the Sleeper into an 8-foot, barnacle-crusted abyssal stalker who mimics dead voices |
| **The Captain** | Mainland fishing boat skipper | Drop you off and clear the point before the stone rises | Knows the old coastal law: won't touch the sand while the Black Stone is dry |
| **Cpl. Reyes** | Det. 9 maintenance corporal (dead) | Keep the harbor searchlight working | Driven mad by Vane in the wires and Locke's voice mimicry; found dead on the watchtower (`A04`) |

---

## The Three Forces — Rules of the Horror & Gameplay

### 1. The Shepherd (Captain Alistair Locke — Physical Stalker)
- **Sight:** Sees you if you are close (~3m), in his front cone, or **your flashlight is on**.
- **Hearing:** Hears sprinting (~16m), walking (~7m), crouching (~2.5m), and **loud events** (generator pull-cord, wrong breaker bang, wrong keypad alarm).
- **Hiding:** Lockers (Ch2), stone ruins (Ch4), and submerged water alcoves (Ch5) conceal you.
- **Escalation:**
  - *Ch 1:* Glimpses and roof footfalls only.
  - *Ch 2:* Enters the barracks (locker hide) and charges the cable car platform.
  - *Ch 3:* Keeps pace with the cable car up the mountain slope.
  - *Ch 4:* Revealed in his 1784 naval coat in the Burned Quarter; stalks the village; ambushes you on the Service Path bridge.
  - *Ch 5:* Hunts you through his 1784 shipwreck and flooded tunnel (cannot enter the sacred Abyssal Caverns `S13`).
  - *Ch 6:* Climbs the cable line into the Research Center and confronts you at the Summit Crater.

### 2. Julian Vane (The Mind in the Electrical Grid)
- **Reach:** Can only see, speak, and act where **electric power is active** (Harbor searchlight, Base Camp, Village Dig Site *after* you start the generator, Bunker lift, Research Center, Siphon Lab). In unpowered ruins and caves, you are invisible to him.
- **Disguise & Reveal:** In Chapters 1–4, he speaks over intercoms and radios using **spliced audio recordings of Sgt. Elias**. In Chapter 5 (`S14`), after you find the real Elias, Vane drops the mask and speaks in his own static-warped voice.
- **Puzzle Rule (No Hands, Full of Lies):** Vane can toggle lights, lock magnetic doors, and broadcast audio, **but he cannot press physical keypads, pull manual breakers, or carry items**. Whenever he wants to herd you or hide evidence, **he lies about keypad codes** (e.g., giving `7392` instead of `2604` in Ch4), triggering loud alarms that attract The Shepherd.

### 3. The Pale Shard (Acquired in Chapter 4 — Burned Quarter)
- Picked up from a massacred villager's skeleton in `A11`.
- **Passive:** Hums and glows faintly with Dr. Mara's frequency near hidden carvings, truth-notes, and when The Shepherd is dangerously close in pitch dark.
- **Active (Ch 5 & Ch 6):** Can be charged at ancient resonance totems to unleash a brief **Harmonic Flash** that stuns/repels The Shepherd or attunes the harmonic bridges in the Abyssal Caverns (`S13`).

---

## Chapter Index (2.5-Hour Target Playtime)
| # | Title | Target Playtime | One-Line Beat | Levels / Stages | Previs Status |
|---|-------|-----------------|---------------|-----------------|---------------|
| **01** | **The Old Harbor** | ~20 min | Dropped on the beach, the ravine scaffold collapses; find Reyes on the tower and cut the gate chain as the Black Stone rises from the sea. | `A01–A04` (`S01–S04`) | Draft — 5:02, 20 shots |
| **02** | **Base Camp** | ~25 min | Discover Project TIDEWATER is a front; hide from The Shepherd in the barracks, power the substation, hear "Elias" on the intercom, and escape in Car 2. | `A05` (`S05`) | Draft — 4:49, 15 shots |
| **03** | **The Line** | ~15 min | Car 2 climbs into luminescent fog while The Shepherd races up the slope; Elias's sabotage stops the car at Pylon 3, and a broken ladder rung drops you into the hollow. | `A06–A07` (`S06–S07`) | Draft — 3:11, 12 shots |
| **04** | **The Old Village** | ~30 min | Piece together the 1784 massacre and the Cosmic Law in the unpowered ruins, survive Vane's false lift code, claim the **Pale Shard**, and ride the lift to the Service Path—where the bridge collapses into the West Gully. | `A08–A11` + `A07` (`S08`) | Draft — 8:23, 21 shots |
| **05** | **The Belly of the Mountain** | ~35 min | Survive the tidal hull of the 1784 *HMS Madrigal* and the calcified crew in the Sea Cave, ascend 170m through the bioluminescent **Deep Chorus** caverns, and find the dying **Elias** guarding **Tide-Stone #3** in Bunker B. | `A12–A19` (`S09–S14`) | Design complete (`ch05`) |
| **06** | **The Siphon & The Summit** | ~25 min | Ride the lift into the Research Center, survive Vane's automated building traps, confront Vane's mutating body in the **Neural Siphon Facility**, and choose the fate of the island at the **Summit Crater Circle**. | `A20–A23` (`S15–S17`) | Design complete (`ch06`) |

---

## Previs Slate
Every playblast shows, top-right: `CH 02 · SHOT 09 — Footsteps at the door` / `AREA 05 · Base Camp`. Shot names and areas come from each chapter's `chapter_meta.json`.

## Resolved Design Decisions (v8)
- **The Village Crystal:** The crystal in the villager skeleton's hand (`A11`) is a **Pale Shard** (a personal healing crystal), which the player picks up as a survival tool. The **Three Tide-Stones** (the large black resonance stones) were dug up from the Village Ring (`A10`) by Vane's team and taken to the Summit (`A23`)—except for **Tide-Stone #3**, which Elias stole and brought down to Bunker B (`A19` / `S14`).
- **Keeping Ch3 Service Path & Ch4 Cargo Lift:** Nothing built in Ch3 or Ch4 is wasted. You ride the Ch4 Cargo Lift (`A10`) up to the Lit Service Path (`A07`), walk across the Old Stream Plank Bridge, and **The Shepherd ambushes you on the bridge**, collapsing it into the West Gully (`S09`) to start Chapter 5 at sea level.
- **Two Ritual Circles:** The **Ancient Ring** is in the Old Village (`A10`); Vane built the **Modern Conduit Circle** at the Summit Crater (`A23`) directly above his Neural Siphon Lab (`A22`).
