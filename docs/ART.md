# Scrapfall launch art brief

The current sprites are cut from concept sheets. They are fine for testing,
but a launch build needs art made for the game camera, with animation. This
brief covers what to make and two ways to make it.

## What the game needs

The camera looks down at the arena at a steep 3/4 angle (roughly 50 to 60
degrees above the ground), like Clash Royale. Units are small on screen
(60 to 120 px tall on a 720 x 1280 screen), so silhouettes and faction
colours matter more than fine detail.

Per unit (24 deck cards):

| Item | Spec |
| --- | --- |
| View | 3/4 top-down, matching the arena camera |
| Directions | 8 (or 5 mirrored: S, SE, E, NE, N) |
| Animations | idle 8 frames, walk or fly 8 to 12, attack 8 to 12, death 8 to 12 |
| Size | 256 px tall frames, transparent PNG, feet at the bottom centre |
| Extras | projectile, muzzle or impact flash, card portrait (square, 512 px) |

Per faction: princess tower and king tower, each with idle, attack, and
damaged and destroyed states; tower ammo; a spell burst effect.

Name files `art/units/<card_id>/<anim>_<dir>_<frame>.png` (card ids are in
`scripts/cards.gd`), and the game can be switched to frame animation
without touching the gameplay code.

## Route A: 3D models rendered to sprites (recommended)

Most consistent, and every animation and angle comes for free once a model is rigged.

1. Turn each concept into a 3D model with an image-to-3D tool (for example
   Meshy, Tripo or Rodin). Feed it a single clean front view; the faction
   sheets already have front and back views for the main characters.
2. Rig and animate humanoids with Mixamo (free auto-rig and an animation library). Dragons, drones and vehicles need a hand rig or simple keyframes.
3. Render each animation from the game camera in 8 directions in Blender
   (orthographic camera, transparent background, consistent lighting from
   top-left), or import the models straight into Godot and switch the arena to 3D.

## Route B: AI-generated 2D sprite sheets

Faster to start, harder to keep consistent across frames.

1. For each character, generate a turnaround first, then the animation
   frames, always attaching the concept image as the reference. Example
   prompt:
   > Game sprite sheet of [Rivet Warden from the attached image], stylised
   > 3D render, 3/4 top-down view from above, walking cycle, 8 frames in a
   > single row, same character in every frame, plain transparent
   > background, even studio lighting from the top left, no text.
2. Clean up drift between frames by hand (an artist pass in Aseprite or
   Photoshop), then slice into the file layout above.

## Where to start

Do one faction end to end (Scrappers: 8 units, 2 towers) before the
others, and check it in game before making the rest. If you upload finished
frames or models to the project, they can be wired into the game.
