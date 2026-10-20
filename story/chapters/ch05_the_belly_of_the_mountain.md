# Chapter 05 — The Belly of the Mountain

> **Design Document (v8) — Stages `S09–S14` (`A12–A19`).**
> **Target Playtime:** ~35 minutes.
> **Core Vibe:** Pure Lovecraftian abyssal horror (*The Shadow over Innsmouth* + *SOMA*). You are plunged from the mountain's pine forest all the way down to sea level (`1 m`), face-to-face with the risen Black Stone, forced to crawl through Captain Locke's 1784 shipwreck and climb 200 metres up through the hollow, bioluminescent interior of the mountain where **The Sleeper in the Trench** dreams—before finally finding the real **Sgt. Elias** inside Sub-Level Bunker B.

---

## Summary
After The Shepherd smashes the Old Stream Plank Bridge on the Lit Service Path (`A07`), the player slides down the steep **West Gully (`S09`)** and washes up on the black volcanic sand of the West Cove. Offshore, the **Black Stone** towers above the waves, vibrating with a sub-bass hum that ripples the tide in geometric patterns. Blocking the cove is the rotting 1784 hull of Captain Alistair Locke's brig, the ***HMS Madrigal* (`S10`)**.

Navigating the ship's flooded gun-deck between rising ocean swells, the player finds Locke's melted iron ritual cage and a waterproof pack dropped by **Sgt. Elias** two days ago. Wading through the surf into the **Sea Cave (`S11`)**, they discover Locke's 1784 crew fused like living white coral into the limestone walls. In the **Smuggler's Tunnel (`S12`)**, The Shepherd hunts the player through chest-deep water; with no lockers here, the player hides in submerged air-alcoves and uses the **Pale Shard** at an ancient resonance totem to blind the creature.

Emerging into the **Abyssal Caverns (`S13`)**—a 170-metre vertical chasm inside the mountain where The Shepherd dares not enter—the player climbs past hundreds of petrified villagers of the **Deep Chorus** while a cathedral-sized luminescent **Eye** shifts beneath the subterranean river below. Attuning three harmonic stone bridges with the Pale Shard, the player reaches the cave hatch of **Sub-Level Bunker B (`S14`)**. Inside sits the real **Sgt. Elias**, dying of the Deep Sickness with **Tide-Stone #3** clutched to his chest. Elias reveals that the voice on the radios is **Julian Vane**—fused into the island's electrical grid—and makes the player promise to destroy Vane's Siphon Pod and shatter the third stone at the summit. As Elias dies in peace, Vane drops his disguise over the Bunker PA and unlocks the 75-metre freight elevator up to the Research Center.

---

## Location & Areas (`res://game/levels/`)
| # | Area | Stage | Elev. | Contents |
|---|------|-------|-------|----------|
| A12 | West Gully | S09 | 120 → 3 m | Collapsed bridge debris, steep scree chute, dead pine gorge, first close view of the Black Stone offshore |
| A13 | Wreck of *HMS Madrigal* | S10 | 3 → 1 m | Beached 1784 wooden hull, tidal lower gun-deck, Captain's cabin, melted iron cage, Elias's waterproof pack |
| A14 | The Sea Cave | S11 | 1 → 2 m | Surf entrance under the cliff, tide pools, Locke's 1784 sailors calcified into the rock walls |
| A15 | Smuggler's Tunnel | S12 | 2 → 28 m | Old 1784 ship-timbers meeting modern concrete shore-supports, flooded floor, submerged hiding alcoves, Resonance Totem |
| A16–A18 | Abyssal Caverns (Deep Chorus) | S13 | 28 → 200 m | 170 m vertical cavern, subterranean river, the Sleeper's Eye in the abyss below, petrified Deep Chorus villagers, 3 Harmonic Chime Bridges |
| A19 | Sub-Level Bunker B | S14 | 200 → 290 m | Heavy cave blast hatch, generator junction, the real **Sgt. Elias**, **Tide-Stone #3**, CCTV camera, 75 m Freight Lift shaft |

- **Proposed Markers:** `Mk_Ch05_GullyLanding`, `Mk_Ch05_CoveVista`, `Mk_Ch05_ShipBreach`, `Mk_Ch05_GunDeck`, `Mk_Ch05_IronCage`, `Mk_Ch05_EliasPack`, `Mk_Ch05_SeaCaveMouth`, `Mk_Ch05_CalcifiedCrew`, `Mk_Ch05_WaterAlcove_1..3`, `Mk_Ch05_ResonanceTotem`, `Mk_Ch05_AbyssVista`, `Mk_Ch05_DeepChorus`, `Mk_Ch05_Chime_1..3`, `Mk_Ch05_BunkerHatch`, `Mk_Ch05_EliasBody`, `Mk_Ch05_FreightLift`
- **Animated Level Nodes:** `Dynamic/TideSwell` (gun-deck water level), `Dynamic/PaleShardFlash`, `Dynamic/HarmonicBridge_1..3`, `Dynamic/BunkerHatch`, `Dynamic/BunkerCamera`, `Dynamic/FreightLift`

---

## Characters Present
- **Protagonist** (carries the **Pale Shard** from Ch4; acquires **Tide-Stone #3** at the end of Ch5).
- **The Shepherd (Capt. Alistair Locke):** Stalks the *HMS Madrigal* (`A13`) and Smuggler's Tunnel (`A15`); stops at the threshold of the Abyssal Caverns (`A16`).
- **The Deep Chorus (1784 Crew & Ancient Villagers):** Environmental living statues—Locke's crew calcified in agony in `A14`; the villagers sitting in peaceful harmonic meditation in `A16–A18`.
- **The Sleeper in the Trench (*Y'ha-Nthlei*):** Glimpsed only as a colossal, bioluminescent silhouette and cathedral-scale eye beneath the black subterranean river in `A17`.
- **Dr. Mara Chen (Echo):** Speaks briefly through the Pale Shard at the harmonic chimes.
- **Sgt. Elias (The Real Brother):** Found alive in his final moments in `A19` (`S14`).
- **Julian Vane:** Completely absent in `S09–S13` (no electricity); drops his "Elias" mask on the PA in `S14` once Elias dies.

---

## Beats
| # | Beat | Stage / Area | Target Playtime | Notes (Camera / Sound / Gameplay) |
|---|------|--------------|-----------------|-----------------------------------|
| 1 | Chapter Card: "Chapter 5 — The Belly of the Mountain" | — | 0:00 | Sound of crashing surf and a deep, rhythmic sub-bass thrum |
| 2 | **The West Gully Descent:** Sliding down loose scree from the broken bridge (`A07`) to the black-sand cove; no way back up | S09 · A12 | 3 min | One-way vertical drop; flashlight flickers; radio is dead static |
| 3 | **The Risen Spire:** Stepping onto the West Cove beach; out across the water, the **Black Stone** towers like an obelisk veined with cold blue-white bioluminescence | S09 · A12 | 1 min | Wide vista; the seawater vibrates in concentric Chladni patterns |
| 4 | **Boarding the *HMS Madrigal*:** Entering the rotting timber ribs of Captain Locke's 1784 brig wedged into the cliff | S10 · A13 | 2 min | Creaking wet oak; brass ship's bell tolling with the waves |
| 5 | **Tidal Gun-Deck Puzzle:** The lower deck floods every 12 seconds as the swell surges through the hull breach; move between elevated air-pockets while drowned 18th-century debris floats past | S10 · A13 | 4 min | Environmental timing puzzle; water muffles all sound |
| 6 | **The Captain's Cabin & Iron Cage:** A rusted iron ritual cage melted outward like wax; beside it, **Elias's waterproof pack** and flare gun case | S10 · A13 | 2 min | Elias's note explains how he fled Vane's cameras through the caves |
| 7 | **The Sea Cave & The Calcified Crew:** Wading along the cliff waterline into `A14`; Locke's 1784 mutineers are fused into the limestone walls like white coral—their eyes still wet and tracking your light | S11 · A14 | 4 min | Slow dread; shining your flashlight directly on their faces makes them whisper |
| 8 | **Stalked in the Smuggler's Tunnel:** The Shepherd drops through a timber shaft behind you; hide chest-deep in dark **water alcoves** while he drags his hook along the beams | S12 · A15 | 4 min | Stealth without lockers; holding breath muffles player audio |
| 9 | **The Totem Flash:** Cornered at the tunnel gate, hold the **Pale Shard** to an ancient carved totem to unleash a **Harmonic Flash**, blinding The Shepherd and escaping through the rock fissure | S12 · A15 | 2 min | Teaches the Pale Shard defensive mechanic for the finale |
| 10 | **The Abyssal Caverns (The Deep Chorus):** Stepping onto a wet basalt ledge inside a 170 m vertical cavern; hundreds of ancient villagers sit in salt-crystal meditation, humming a warm chord | S13 · A16 | 3 min | Awe and cosmic terror; The Shepherd refuses to cross the threshold |
| 11 | **The Eye in the Chasm:** Crossing the lower natural bridge (`A17`); looking down into the flooded trench below, a colossal bioluminescent **Eye** opens slowly in the dark water | S13 · A17 | 2 min | If the player stares straight down too long, screen edges warp with ocean hallucinations |
| 12 | **The Three Harmonic Bridges:** Attune three ancient stone chimes along the 170 m ascent using the **Pale Shard** (guided by Dr. Mara's Echo) to calm the psychic pressure and cross to the upper ledge (`200 m`) | S13 · A18 | 3 min | Acoustic matching puzzle |
| 13 | **Sub-Level Bunker B — Finding Elias:** Prying open the rusted cave hatch into concrete Bunker B (`A19`); **Sgt. Elias** sits propped against the elevator door, black coral veins on his neck, holding **Tide-Stone #3** | S14 · A19 | 3 min | Emotional heart of the story; first real human conversation |
| 14 | **The Promise & The Passing:** Elias tells the truth about Julian Vane's Siphon Array and Dr. Mara Chen, hands you **Tide-Stone #3**, and makes you swear to shatter it at the summit; as he lets go of the stone, he dies peacefully | S14 · A19 | 1 min | Player receives `TideStone_3` |
| 15 | **Vane Drops the Mask:** The bunker CCTV camera whirs toward you; over the PA speaker, **Julian Vane** drops the spliced "Elias" voice and speaks in his own cold, static-laced voice, unlocking the 75 m Freight Lift | S14 · A19 | 1 min | Ride the freight lift up toward `300 m`; fade to Chapter 6 |

---

## Puzzles & Survival Mechanics
1. **The Tidal Swell (`S10` Gun-Deck):** Every oceanic pulse raises the water in the tilted gun-deck to the ceiling for 5 seconds. The player must read the sub-bass rumble of the Black Stone, sprint between raised cannon carriages/air pockets during the trough, and unbar the bow hatch.
2. **Water-Alcove Stealth & Totem Overload (`S12` Smuggler's Tunnel):** No metal lockers exist underground. Crouching in dark flooded side-niches submerges the player to the chin (invisible to The Shepherd if the flashlight is off). At the end of the tunnel, attuning the **Pale Shard** to a carved monolith overloads it, stunning The Shepherd long enough to crank the iron sluice gate.
3. **The Harmonic Chimes (`S13` Abyssal Caverns):** The psychic pressure of the Sleeper blocks the upper ledges with deafening resonance distortion. Using the **Pale Shard**, the player listens for Dr. Mara's clear three-note harmonic hum and strikes the corresponding basalt chimes at `38 m`, `102 m`, and `162 m` to clear the path.

---

## Key Dialogue & Lore Texts (Draft)

### 1. Locke's Final Log — Found beside the Melted Iron Cage (`A13`)
> *"December 14th, 1784. We brought the three black stones down into the sea-vault and bolted the iron frame to receive the god's blood. It did not bleed. The water stood upright like a wall. Finch and Mercer have run into the limestone—their bones are part of the cliff, yet their mouths still move. My coat will not come off my skin. It is calling my name in the voices of the dead villagers."*

### 2. Elias's Waterproof Note — Found in the Captain's Cabin (`A13`)
> *"If anyone from the mainland ever finds this: DO NOT GO UP BY THE CABLE LINE. Vane isn't dead, and he isn't human anymore. He's in the wires. Every camera, every radio, every powered lock on the mountain is him. I pulled the third stone out of his machine at the summit and brought it down here where there's no copper in the walls. I'm taking the old tunnel up to seal Bunker B from the inside. — Sgt. E."*

### 3. Sgt. Elias — In Person (`A19` Sub-Level Bunker B)
1. *(Weak, wet cough; looks up as your flashlight hits his face)* "...No. No, kiddo, tell me I'm hallucinating. Tell me you stayed home."
2. "Listen to me—don't touch the radio. That voicemail you got? That wasn't me. I never called you."
3. "It's Vane. Julian Vane. He built a siphon under the summit to steal immortality from the thing under the island... and he used Mara—Dr. Chen—as the fuse."
4. "When I pulled this third stone out of the circle to save her, the whole circuit blew back into Vane's pod. It burned his mind straight into the island's power grid. He's in the generators, the speakers, the doors... but he doesn't have hands."
5. *(Presses the heavy black **Tide-Stone #3** into your hands)* "This stone is the only thing keeping me breathing, and it's turning me into salt from the inside out. Take it."
6. "Vane needs you to carry this up to the Summit Circle so he can finish his siphon before his body in the upper lab rots into another Shepherd. Don't do it. Smash his pod in the Second Facility... and break this stone on the summit rocks. Let me go, kiddo. Promise me."

### 4. Julian Vane — Bunker PA Speaker (After Elias Dies, `A19`)
1. *(A sharp burst of static; Elias's voice speaks two words—)* *"Kiddo, please—"* *(—then cuts off with a mechanical click into a cold, raspy, older man's voice layered over electrical hum)*
2. "There. No more splices. It was exhausting speaking through your brother's limited vocabulary anyway."
3. "Look at what his nobility bought him. A cold floor in the dark. Do you really think smashing that stone will save him?"
4. "His mind—and Dr. Chen's—are trapped inside the breach above the mountain right now. Break that stone, and the thing in the trench digests them both forever. Put the stone back in my circle... and I can pull them out. The elevator is unlocked. Come up, and see what is at stake."
