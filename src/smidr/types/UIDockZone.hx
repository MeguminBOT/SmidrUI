package smidr.types;

/**
	Where a panel lands when docked into a `UIDockGroup`: as another tab (`CENTER`) or by splitting
	the target and placing the panel on that side.

	An `enum abstract` over `Int` (just an `Int` at runtime). Usable unqualified where a `UIDockZone`
	is expected; `from`/`to Int` keep it interchangeable with plain ints.

	- `CENTER` — add as a new tab in the target group
	- `LEFT` / `RIGHT` — split horizontally, panel on that side
	- `TOP` / `BOTTOM` — split vertically, panel on that side
**/
enum abstract UIDockZone(Int) from Int to Int {
	var CENTER = 0;
	var LEFT = 1;
	var RIGHT = 2;
	var TOP = 3;
	var BOTTOM = 4;
}
