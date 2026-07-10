package smidr.types;

/**
	A named entrance / exit / attention animation for `UIAnimation.play`.

	An `enum abstract` over `Int` (just an `Int` at runtime). Entrance presets settle the target
	back to its resting transform; exit presets (`FLY_OUT`/`ZOOM_OUT`/`FADE_OUT`) leave it hidden
	for the caller to remove.

	- `FLY_IN` / `FLY_OUT` — slide in from / out toward an edge (with a fade)
	- `ZOOM_IN` / `ZOOM_OUT` — scale from / to nothing (with a fade)
	- `FADE_IN` / `FADE_OUT` — opacity only
	- `POP` — scale in with an overshoot
	- `FLIP` — a 2D horizontal flip-in (OpenFL has no true 3D, so this is a scale fake)
	- `REVOLVE` — spin in one turn while scaling up
	- `SHAKE` — a horizontal attention shake, settling back
	- `PULSE` — a single scale pulse, settling back
**/
enum abstract UIAnimationPreset(Int) from Int to Int {
	var FLY_IN = 0;
	var FLY_OUT = 1;
	var ZOOM_IN = 2;
	var ZOOM_OUT = 3;
	var FADE_IN = 4;
	var FADE_OUT = 5;
	var POP = 6;
	var FLIP = 7;
	var REVOLVE = 8;
	var SHAKE = 9;
	var PULSE = 10;
}
