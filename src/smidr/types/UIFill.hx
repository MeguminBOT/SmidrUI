package smidr.types;

import smidr.UITheme;

/**
	What fills a themed rectangle: a theme slot (follows theme swaps) or a fixed `0xAARRGGBB`
	colour (stays put). One `Int` at runtime — the six slot ids live in the alpha-zero range no
	real colour occupies, so `resolve()` tells them apart with a single branch.

	`from Int` means both forms read naturally where a `UIFill` is expected: slot names resolve
	unqualified (`new UIPanel(w, h, CARD)`) and any colour literal is accepted as a fixed fill
	(`new UIPanel(w, h, 0xFF1E1E21)`).

	The encoding reserves alpha == 0, so a fully transparent fixed fill can't be expressed —
	use a non-blocking group or the widget's `alpha` instead.

	- `BG` -> `UITheme.bg`        (window/backdrop)
	- `PANEL` -> `UITheme.panel`  (base surface)
	- `PANEL2` -> `UITheme.panel2`(raised surface)
	- `PANEL3` -> `UITheme.panel3`(highest surface)
	- `CARD` -> `UITheme.card`    (grouped content)
	- `INPUT` -> `UITheme.inputBg`(recessed input well)
**/
enum abstract UIFill(Int) from Int to Int {
	var BG = 0;
	var PANEL = 1;
	var PANEL2 = 2;
	var PANEL3 = 3;
	var CARD = 4;
	var INPUT = 5;

	/**
		The ARGB colour this fill paints right now: theme slots re-read the live palette (so
		widgets calling this in `render()` follow theme swaps), fixed colours return themselves.
		@return the resolved `0xAARRGGBB` colour
	**/
	public inline function resolve():Int {
		return if ((this >>> 24) != 0) this else switch (this : UIFill) {
			case BG: UITheme.bg;
			case PANEL: UITheme.panel;
			case PANEL2: UITheme.panel2;
			case PANEL3: UITheme.panel3;
			case CARD: UITheme.card;
			case INPUT: UITheme.inputBg;
			default: UITheme.panel;
		}
	}
}
