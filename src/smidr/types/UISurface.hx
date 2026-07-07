package smidr.types;

/**
	A theme surface role for `UIPanel`. A panel is bound to a `UISurface` by default, so it
	re-reads the matching `UITheme` value every render and follows theme swaps; pass a fixed colour
	via `UIPanel.solid` only for the rare static case.

	An `enum abstract` over `Int`, so it is just an `Int` at runtime. Unlike the value-carrying
	types it is `to Int` only (no `from Int`), so a theme colour int can't be mistaken for a role.

	- `BG` -> `UITheme.bg`        (window/backdrop)
	- `PANEL` -> `UITheme.panel`  (base surface)
	- `PANEL2` -> `UITheme.panel2`(raised surface)
	- `PANEL3` -> `UITheme.panel3`(highest surface)
	- `CARD` -> `UITheme.card`    (grouped content)
	- `INPUT` -> `UITheme.inputBg`(recessed input well)
**/
enum abstract UISurface(Int) to Int {
	var BG = 0;
	var PANEL = 1;
	var PANEL2 = 2;
	var PANEL3 = 3;
	var CARD = 4;
	var INPUT = 5;
}
