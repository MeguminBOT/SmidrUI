package smidr.types;

/**
	The theme text-colour ramp a widget tints itself with (`UILabel`, `UIIcon`).

	An `enum abstract` over `Int`, so it is just an `Int` at runtime (no allocation) while giving
	named, type-safe values. Where a `UITone` is expected the name can be written unqualified, e.g.
	`new UILabel("Saved", 13, SECONDARY)`; elsewhere use `UITone.SECONDARY`. `from`/`to Int` keep
	it interchangeable with plain ints, so passing a raw ramp index still compiles.

	- `PRIMARY` -> `UITheme.text`
	- `SECONDARY` -> `UITheme.text2`
	- `TERTIARY` -> `UITheme.text3`
**/
enum abstract UITone(Int) from Int to Int {
	var PRIMARY = 0;
	var SECONDARY = 1;
	var TERTIARY = 2;
}
