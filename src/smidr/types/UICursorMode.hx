package smidr.types;

/**
	How the `smidr.flixel.FlxSmidr` bridge manages the cursor while the pointer is over UI.

	An `enum abstract` over `Int`, so it is just an `Int` at runtime (no allocation) while giving
	named, type-safe values. Where a `UICursorMode` is expected the name can be written unqualified,
	e.g. `FlxSmidr.cursorMode = CURSOR_SYSTEM_OVER_UI`; elsewhere use
	`UICursorMode.CURSOR_SYSTEM_OVER_UI`. `from`/`to Int` keep it interchangeable with plain ints.

	- `CURSOR_NONE` — no cursor management (default)
	- `CURSOR_SYSTEM_OVER_UI` — restore the system cursor while over UI, hide it again off UI
**/
enum abstract UICursorMode(Int) from Int to Int {
	var CURSOR_NONE = 0;
	var CURSOR_SYSTEM_OVER_UI = 1;
}
