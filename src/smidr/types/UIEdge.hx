package smidr.types;

/**
	A viewport/box edge or direction. Shared by directional features — animation entry/exit
	(`UIAnimation` fly presets), callout tails, docking sides.

	An `enum abstract` over `Int`, so it is just an `Int` at runtime. Usable unqualified where a
	`UIEdge` is expected; `from`/`to Int` keep it interchangeable with plain ints.
**/
enum abstract UIEdge(Int) from Int to Int {
	var LEFT = 0;
	var TOP = 1;
	var RIGHT = 2;
	var BOTTOM = 3;
}
