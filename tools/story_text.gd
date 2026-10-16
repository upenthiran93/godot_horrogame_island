extends RefCounted
## Story text used by tools/build_chapters.gd — copied from the prototype's
## src/story/chapter1Text.js and chapter2Text.js. The Markdown in story/ is the source of truth;
## this file only feeds the one-off chapter generator.

const BROTHER := "Elias"

const CAPTAIN_INTRO := [
	["Captain", "This is as close as I go. My boots don't touch that sand. Not for your money, not for anyone's."],
	["Captain", "See the dark water past the point? There's a rock out there that sleeps under the tide."],
	["Captain", "If it shows itself while you're ashore, nobody comes. Not me. Not any boat from the villages. Not at any price."],
	["Captain", "You'd wait till the sea swallows it again. Could be days. Could be a lot longer."],
	["Captain", "There's a trail in the brush. Runs up to the old harbor. That was there long before the soldiers came."],
	["Captain", "Scavengers come picking at the base sometimes. Keep your light low."],
	["Captain", "Find your brother quick. And if you hear something out there... you don't answer it."],
]
const AFTER_BOAT := [["", "(Elias... what were you doing out here?)"]]

const T1 := {
	"fallenTree": "(Too high to climb over. I could squeeze underneath.)",
	"wall": "(Old stonework. Older than anything military.)",
	"shrine": "(Someone's been leaving things here.)",
	"scaffold": "(That scaffolding has seen better decades.)",
	"creak": "(It's moving... keep going. Don't stop.)",
	"collapse": "(No... no way back down now.)",
	"harbor": "(The old harbor. And a military fence. Newer than everything else here.)",
	"gateNear": "(Chained shut. I'll need something to cut through that. There was a shed by the west wall...)",
	"doorSlam": "(The wind. It was the wind. It was the wind.)",
	"roof": "(Something is on the roof.)",
	"doorOpens": "(...It's letting me out.)",
	"towerBase": "(Reyes went up there and never came down.)",
	"towerMid": "(Don't think about the height. Keep climbing.)",
	"body": "(Reyes...)",
	"searchlight": "(The searchlight. Who turned on the searchlight?)",
	"lookedDown": "(It was watching me the whole time.)",
	"run": "(Get to the gate. Now. Don't look back.)",
	"gateOpen": "(Through. Whatever's in there... he's in there too.)",
	"rumble": "(Was that... the ground? Or the sea?)",
}

const NOTES1 := {
	"shrine": ["Stone Shrine", "A crude idol, slick with moss. Its face has been chiselled away, deliberately and long ago.\n\nAt its base: fish bones arranged in a spiral, a knot of fishing line, and a child's red bracelet.\n\nThe bones are fresh."],
	"insignia": ["Gate Insignia", "JOINT MARITIME INTELLIGENCE DIRECTORATE\nRESEARCH DETACHMENT 9\n\nRESTRICTED AREA\nUSE OF DEADLY FORCE AUTHORIZED\n\nThe anchor-and-eye crest is the same one stitched onto the jacket Elias stopped wearing home."],
	"signout": ["Equipment Sign-Out Sheet", "MAINTENANCE — EQUIPMENT SIGN-OUT\n\nWelding set — Pvt. Okafor — Pier pylons (again) — returned\nTorches x4 — Night crew — Perimeter walk — returned\nRope, 30m — Sgt. Elias — \"Survey\" — sandbar — NOT RETURNED\nBolt cutters — Cpl. Reyes — Watchtower — searchlight cable jammed — NOT RETURNED\n\n— in red grease pencil —\nREYES NEVER CAME DOWN.\nTOWER IS OFF LIMITS.\nDON'T GO UP THERE AT NIGHT."],
	"body": ["Cpl. Reyes", "The name tape on the jacket reads REYES.\n\nHe's sitting against the rail as if he sat down to rest. His fingernails are gone, worn down to the quick. The boards around him are covered in scratches.\n\nHis eyes are open. He was looking down at the yard when he died."],
}

const T2 := {
	"arrive": "(The ground is still shaking. If that was the rock rising... no boat is coming for me.)",
	"arrive2": "(Find out what happened here. Find Elias.)",
	"genDry": "(The tank's bone dry. There might be fuel in the barracks.)",
	"fuelPoured": "(That's all of it. Now the starter cord.)",
	"sputter0": "(Come on...)",
	"sputter1": "(Come ON.)",
	"genRunning": "(It's running. Now the breakers. Carefully.)",
	"wrongOrder": "(It tripped everything. And that bang was LOUD. Anything out there heard it.)",
	"powerOn": "(Power. The keypad on the command building should work now.)",
	"fuelGot": "(Fuel. Heavy. Now back to the generator.)",
	"atDoor": "(Footsteps. Something's at the door. HIDE.)",
	"photo": "(That's us. The summer before Elias enlisted.)",
	"inside": "(It's in the building.)",
	"escaped": "(Keep moving. The blast site. The hatch.)",
	"hatchStart": "(Rusted solid. Turn it. TURN IT.)",
	"hatchOpen": "(It's open. A ladder, going down into the dark.)",
	"blastSite": "(This is where it happened. Where Elias went down.)",
}

const DOOR_CODE := "2749"

const NOTES2 := {
	"panelNote": ["Restart Procedure", "SUBSTATION B — RESTART PROCEDURE\n\n1. Fuel and start the generator. (Pull the cord. She may take a few tries.)\n2. LIGHTING before COMMS. Comms draws off the lighting bus.\n3. MAIN goes LAST. Always. Main first and she trips the lot.\n\n— in pencil, underneath —\nand don't let her trip. it hears the bang."],
	"roster": ["Duty Roster — Barracks 2", "DUTY ROSTER — BARRACKS 2 — WEEK 31\n\nDuty Sergeant ........ Sgt. ELIAS\nMaintenance .......... Cpl. Reyes\nPier watch ........... Pvt. Okafor\nSurvey escort ........ (vacant)\n\nNOTICE: Following the incident, the COMMAND door code has been reset.\nNew code = LAST FOUR DIGITS of the current Duty Sergeant's service number.\nDo NOT write it down.\n\n(Someone wrote it down anyway, then scratched it out so hard the pen went through the paper.)"],
	"eliasLocker": ["Locker — Elias", "A folded jacket. A paperback with the cover torn off. His dog tags hang from the hook.\n\n    ELIAS\n    SVC NO. 30-118-2749\n    O NEG\n\nTucked behind the tags is a photograph: the two of you on the harbor wall back home. On the back, in his handwriting:\n\n\"If you're reading this, you came anyway. I'm sorry.\""],
	"incident": ["Incident Report (Preliminary)", "INCIDENT REPORT — PRELIMINARY — CLASSIFIED\n\n03:12  Containment chamber beneath Site 4 reports a pressure anomaly. The \"hollow\" has expanded 40 m since the last survey.\n03:20  Sgt. Elias descends AGAINST DIRECT ORDERS to retrieve the survey team. Contact lost at a depth of 60 m.\n03:41  Command authorizes a demolition charge to seal the hollow access.\n03:44  Detonation.\n\nRESULT: Surface structures at Site 4 destroyed. 11 personnel unaccounted for.\nThe hollow is NOT sealed. Acoustic sensors continue to register movement.\n\nRecommendation: abandon the island. Let the sea have it."],
	"map": ["Survey Map", "A survey map of the island. The blast site is circled and labelled HOLLOW ACCESS — SEALED. Someone has crossed out SEALED.\n\nOffshore, the sandbar is ringed in red pencil, over and over until the paper tore. Beside it:\n\n\"IT BREATHES WHEN THE STONE IS UP.\""],
	"photo": ["Unit Photograph", "Detachment 9 in front of this building. Eleven faces.\n\nElias is at the end of the row, the only one not smiling.\n\nSomeone has scratched out every face but his."],
}

# ---- Chapter 2 rework (2026-10-14): base camp → cable car. Lines marked PROPOSED in story/chapters/ch02_base_camp.md.
const T2B := {
	"supply": "(Rations. Diesel. Medical. All of it stamped for the upper station. This whole camp just feeds something up the mountain.)",
	"stationLine": "(A cable car. The line goes up into the fog... all the way to the top.)",
	"stationDead": "(Dead. Everything here must run off that substation.)",
	"powerOn": "(Power. The cable car should run now.)",
	"carLit": "(It's lit. It works.)",
	"moving": "(Moving. It's moving.)",
	"below": "(It's standing where I was. Watching me go up.)",
}

const NOTE_MANIFEST := ["Supply Manifest", "SUPPLY MANIFEST — BASE CAMP → UPPER STATION\nCARGO CAR 2 — LOADING ORDER\n\nRations (14 days) ........ 6 crates\nDiesel ........ 4 drums\nMedical ........ 2 crates\nSample cases (sealed) ........ DOWN ONLY\n\nAll personnel transfers to the Research Center by car only.\nThe mountain road is CLOSED.\n\n— in pencil —\nCar 1 never came back down."]

# Elias's transmission, rewritten: he went UP to the research center (no underground).
const RADIO_UP := [
	["Sgt. Elias (intercom)", "...if anyone's still on this frequency. This is Sergeant Elias, Detachment 9.", 5.0],
	["Sgt. Elias (intercom)", "I'm at the upper station. The research center. What's left of the survey team made it up here with me.", 6.0],
	["Sgt. Elias (intercom)", "The camp isn't safe. It came up out of the water, and it walks the yard every night.", 5.5],
	["Sgt. Elias (intercom)", "I sent car one back down for anyone still alive. Nobody came.", 4.5],
	["Sgt. Elias (intercom)", "If you're hearing this, whoever you are: do not follow me. And if it calls you by name, don't answer.", 6.0],
	["Sgt. Elias (intercom)", "...[static]... it's on the line. It's climbing the line—", 4.0],
]

# ---- Chapter 3 (2026-10-14, first part only). All PROPOSED — see story/chapters/ch03_the_line.md.
const T3 := {
	"lookDown": "(Don't look down. Don't look down.)",
	"tower": "(Just the tower. It's just passing the tower.)",
	"slope": "(There. On the slope. It's keeping up.)",
	"ahead": "(It's ahead of me now. How is it ahead of me?)",
	"noStop": "(No, no, no — don't stop. Not here.)",
	"getOut": "(It's not starting again. I have to get out.)",
	"ladder": "(The pylon ladder. Don't think about the height. Again.)",
	"lights": "(Lights. Someone keeps these lights on.)",
	"up": "(It goes up. Toward the top.)",
	"stream": "(Water. An old stream, cut into the rock long before the fence went up.)",
	"bridge": "(Planks. Someone built this across the water a long time ago. Don't stop on it.)",
	"fall": "(Gone. The car is gone. There is no way back up.)",
	"wake": "(Get up. Get up. Keep going up.)",
	"forest": "(Trees packed in on both sides. Loose rock under every step. Keep moving.)",
}

# [speaker, text, seconds]
const RADIO := [
	["Sgt. Elias (radio)", "...if anyone's still on this frequency. This is Sergeant Elias, Detachment 9.", 5.0],
	["Sgt. Elias (radio)", "The charge didn't seal it. It just woke it up. The hollow runs under the whole island. Under the sea. Out to the sandbar.", 6.5],
	["Sgt. Elias (radio)", "The stone isn't a rock. It's a lid. And when it lifts... it breathes. Everything down there breathes with it.", 6.5],
	["Sgt. Elias (radio)", "The survey team is still alive down there. I can hear them. I'm going back down, through the hatch at the blast site.", 6.0],
	["Sgt. Elias (radio)", "If you're hearing this, whoever you are: do not follow me. And if it calls you by name, don't answer.", 6.0],
	["Sgt. Elias (radio)", "...[static]... it's in the walls. It's been in the walls the whole—", 4.0],
]

# ---- Chapter 4: The Old Village (2026-10-16). All PROPOSED — see story/chapters/ch04_the_old_village.md.
# The villagers have no text (pictures only); the colonist's log pages and the company's dig notes below are the written voices.
const T4 := {
	"wake": "(...Elias? ...No. The phone's dead. Where am I?)",
	"drag": "(Something dragged me in here. These marks lead back to the foot of those steps.)",
	"lamps": "(The lamps on the rim. The path is right up there. I can see it.)",
	"buried": "(The steps are buried. No way up from this side. Only through.)",
	"houses": "(Houses. Roofless, old. Someone lived down here a long time ago.)",
	"marks": "(Tally marks, one by every door. Someone counted the years.)",
	"marks2": "(The last row stops half done. All of them. At the same year.)",
	"healing": "(A man lying down. Then the same man standing, holding a little stone. They were given something.)",
	"guest": "(Beds. Laid out in a row. For strangers.)",
	"log": "(A log. English. Not the villagers'.)",
	"creak": "(A floorboard. Upstairs. There is no upstairs.)",
	"window": "(Someone is standing in the lane.)",
	"gone": "(Gone. There are muddy prints on the sill. A heavy coat's hem.)",
	"ring": "(A ring of stones. Three sockets in the middle, empty. Something sat in each one.)",
	"dig": "(Trenches. Tags. Fresh. Someone dug here recently, with orders.)",
	"genUp": "(A generator. If it runs, I get light. And a radio.)",
	"genLoud": "(Too loud. The whole hollow heard that.)",
	"radio": "(...Elias? That's Elias's voice.)",
	"code": "(Seven, three, nine, two. It's asking for a card too.)",
	"wrong": "(Wrong. And it wants a keycard. Whoever sold me that code... wasn't telling the truth.)",
	"burned": "(Burned. All of it. They didn't leave. They were killed.)",
	"bones": "(They were all gathered here. One of them is still holding the stone.)",
	"guard": "(One of the company's. His keycard. He came down here and never left.)",
	"flare": "(A flare. Light it. Slowly.)",
	"stands": "(There's someone there. A long coat. It's... a man.)",
	"carving": "(The giver turned him black. A man in a coat on a cord. That's what's following me.)",
	"hide": "(Don't run. Don't breathe. Let it pass.)",
	"realCode": "(Not seven-three-nine-two. Two-six-zero-four. The radio lied.)",
	"lift": "(Go. Go. Please go.)",
	"top": "(It stopped at the edge of the light. It didn't follow. It just watched me go.)",
}

# Pages of the colonist's ship's log, found in the guest house. [title, body]
const LOG_PAGES := [
	["Ship's log — first page", "...the savages have kept us alive past all reason. Hartley's leg, broken in three places, was whole by morning. I have seen the stone they used. They show it freely..."],
	["Ship's log — second page", "...I have asked them how. They told us everything, down to the yearly gathering and the three stones. They think of me as a guest. I have not corrected them..."],
	["Ship's log — third page", "...My country must have this. I will join their feast. I will take what they will not sell..."],
]

# The company's tags and dig log (Elias's team worked this site for the owner).
const DIG_TAG := ["Dig tag", "SOCKET 1/3\nCRYSTAL RECOVERED\nE.R.\n\nDO NOT REMOVE — OWNER'S ORDERS"]
const DIG_LOG := ["Dig log — page 41", "...third socket cleared. E. (security) objected again to opening the circle. Overruled by the owner.\n\nThe researcher keeps asking what the stones are for. Nobody tells her.\n\n(the last page is stuck under the radio)"]
const DIG_LAST_PAGE := ["Dig log — last page", "LIFT CREW: cargo lift 2 code is 2 6 0 4.\nChange it after the ceremony.\n\nKeycard at the gate. Ask security."]
const NOTE_LIFT_BAD := ["Cargo Lift 2", "ENTER CODE:  7 3 9 2\n\nINVALID CODE\nINSERT KEYCARD"]
const NOTE_LIFT_GOOD := ["Cargo Lift 2", "ENTER CODE:  2 6 0 4\n[card accepted]\n\nCODE ACCEPTED\nLIFT STARTING"]
const NOTE_KEYCARD := ["Keycard", "SECURITY — LEVEL 2\nCARGO LIFT 2 / SERVICE PATH\n\n(taken from the guard's jacket)"]

# [speaker, text, seconds] — the owner, speaking through the dig radio in Elias's recorded voice.
const OWNER_RADIO := [
	["Sgt. Elias (radio)", "...is somebody there? Don't be afraid. It's me. It's Elias.", 5.0],
	["Sgt. Elias (radio)", "Stay where you are. The cargo lift at the ring will bring you up. The code is seven, three, nine, two.", 6.5],
	["Sgt. Elias (radio)", "Hurry. Don't go into the old houses. Come on, now.", 4.5],
]
