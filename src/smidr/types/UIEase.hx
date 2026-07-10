package smidr.types;

/**
	The easing curve for a `UITween`.

	An `enum abstract` over `Int`, so it is just an `Int` at runtime (no allocation) while giving
	named, type-safe values. Where a `UIEase` is expected the name can be written unqualified, e.g.
	`UITween.to(setP, 0, 1, 155, OUT_QUAD)`; elsewhere use `UIEase.OUT_QUAD`. `from`/`to Int` keep
	it interchangeable with plain ints.

	The four originals (`LINEAR`/`OUT_QUAD`/`OUT_BACK`/`IN_QUAD`) keep their historical ids; the
	rest are the standard Penner families in `IN_*` (accelerate), `OUT_*` (decelerate) and
	`IN_OUT_*` (both) variants. `OUT_QUAD` is the sensible default for most UI motion.
**/
enum abstract UIEase(Int) from Int to Int {
	var LINEAR = 0;
	var OUT_QUAD = 1;
	var OUT_BACK = 2;
	var IN_QUAD = 3;

	var IN_OUT_QUAD = 4;

	var IN_CUBIC = 5;
	var OUT_CUBIC = 6;
	var IN_OUT_CUBIC = 7;

	var IN_QUART = 8;
	var OUT_QUART = 9;
	var IN_OUT_QUART = 10;

	var IN_QUINT = 11;
	var OUT_QUINT = 12;
	var IN_OUT_QUINT = 13;

	var IN_SINE = 14;
	var OUT_SINE = 15;
	var IN_OUT_SINE = 16;

	var IN_EXPO = 17;
	var OUT_EXPO = 18;
	var IN_OUT_EXPO = 19;

	var IN_CIRC = 20;
	var OUT_CIRC = 21;
	var IN_OUT_CIRC = 22;

	var IN_BACK = 23;
	var IN_OUT_BACK = 24;

	var IN_ELASTIC = 25;
	var OUT_ELASTIC = 26;
	var IN_OUT_ELASTIC = 27;

	var IN_BOUNCE = 28;
	var OUT_BOUNCE = 29;
	var IN_OUT_BOUNCE = 30;
}
