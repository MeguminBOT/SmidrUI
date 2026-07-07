package smidr.types;

/**
	A theme surface role for `UIPanel`. Unlike an explicit fill colour, a panel bound to a
	`UISurface` re-reads the matching `UITheme` value every render, so it follows theme swaps.

	An `enum abstract` over `Int`, so it is just an `Int` at runtime. Use it via
	`UIPanel.themed(PANEL2, w, h)` or by assigning `panel.surface`.

	- `BG` -> `UITheme.bg`        (window/backdrop)
	- `PANEL` -> `UITheme.panel`  (base surface)
	- `PANEL2` -> `UITheme.panel2`(raised surface)
	- `PANEL3` -> `UITheme.panel3`(highest surface)
	- `CARD` -> `UITheme.card`    (grouped content)
	- `INPUT` -> `UITheme.inputBg`(recessed input well)
**/
enum abstract UISurface(Int) from Int to Int {
	var BG = 0;
	var PANEL = 1;
	var PANEL2 = 2;
	var PANEL3 = 3;
	var CARD = 4;
	var INPUT = 5;
}
