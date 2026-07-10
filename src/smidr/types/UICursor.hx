package smidr.types;

import openfl.ui.MouseCursor;

/**
	A named cursor shape, the friendly vocabulary for `UIComponent.hoverCursor` and
	`UICursors.set`.

	An `enum abstract` over `String` carrying OpenFL's cursor ids, with an implicit `@:to
	MouseCursor` so it drops straight into any OpenFL cursor slot (`comp.hoverCursor =
	UICursor.MOVE`). OpenFL only exposes `ARROW`/`AUTO`/`BUTTON`/`HAND`/`IBEAM` as public
	`MouseCursor` members; the rest here (move, wait, resize, crosshair) ride OpenFL's
	`from String` on their underlying ids.

	- `DEFAULT` — auto (shape chosen by the object under the pointer)
	- `ARROW` — plain arrow
	- `CLICK` — button-press hand (what `UIButton` uses)
	- `GRAB` — open/dragging hand
	- `TEXT` — I-beam
	- `MOVE` — four-way move
	- `WAIT` — busy/wait
	- `CROSSHAIR` — crosshair
	- `RESIZE_H` / `RESIZE_V` — horizontal / vertical resize
	- `RESIZE_NESW` / `RESIZE_NWSE` — diagonal resize
**/
enum abstract UICursor(String) from String to String {
	var DEFAULT = "auto";
	var ARROW = "arrow";
	var CLICK = "button";
	var GRAB = "hand";
	var TEXT = "ibeam";
	var MOVE = "move";
	var WAIT = "wait";
	var CROSSHAIR = "crosshair";
	var RESIZE_H = "resize_we";
	var RESIZE_V = "resize_ns";
	var RESIZE_NESW = "resize_nesw";
	var RESIZE_NWSE = "resize_nwse";

	/** The OpenFL cursor this maps to (implicit; lets a `UICursor` fill any `MouseCursor` slot). **/
	@:to public inline function toMouseCursor():MouseCursor {
		return (this : MouseCursor);
	}
}
