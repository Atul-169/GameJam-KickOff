# Cinematic Intro Changelog

## New controller

Created `res://scripts/cutscenes/prologue_cinematic.gd`.

It owns:

- cinematic state progression;
- input locking;
- scripted Arin and Niko movement;
- scripted football movement;
- cinematic Camera2D focus;
- Astra appearance and particles;
- automatic dialogue sequencing;
- gameplay HUD handoff;
- Tween cancellation and scene-exit cleanup.

## Removed Prologue dependencies

The story no longer depends on:

- Target 1 or Target 2;
- football kick collisions;
- charged football kicks;
- forest destination Area2D;
- football X position;
- player forest traversal;
- player pressing E at the seal.

## First player action

After Astra says `BEGIN WITH A KICK`, control unlocks and the objective becomes `Kick the Ancient Seal`. The seal kick is the first required gameplay action.

## Dialogue

Manual story-dialogue input is disabled. The existing queue auto-advances every line, preserves order, keeps locked sequences locked between lines, and clears safely on restart or scene change.

## Restart

The chosen behavior is a full Prologue reload. Restarting before or after control begins replays the entire cinematic from the establishing shot.

## Godot target

`project.godot` now declares Godot 4.7 with GL Compatibility.
