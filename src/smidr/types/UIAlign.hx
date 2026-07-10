package smidr.types;

/**
	Cross-axis alignment for layout containers (e.g. `UIStack`).

	An `enum abstract` over `Int` (just an `Int` at runtime). Usable unqualified where a `UIAlign`
	is expected; `from`/`to Int` keep it interchangeable with plain ints.

	- `START` — left (horizontal) / top (vertical)
	- `CENTER` — centered on the cross axis
	- `END` — right (horizontal) / bottom (vertical)
**/
enum abstract UIAlign(Int) from Int to Int {
	var START = 0;
	var CENTER = 1;
	var END = 2;
}
