package smidr.types;

/**
	The easing curve for a `UITween`.

	An `enum abstract` over `Int`, so it is just an `Int` at runtime (no allocation) while giving
	named, type-safe values. Where a `UIEase` is expected the name can be written unqualified, e.g.
	`UITween.to(setP, 0, 1, 155, OUT_QUAD)`; elsewhere use `UIEase.OUT_QUAD`. `from`/`to Int` keep
	it interchangeable with plain ints.

	- `LINEAR` — no easing
	- `OUT_QUAD` — decelerate (the default for most UI motion)
	- `OUT_BACK` — decelerate with a slight overshoot
	- `IN_QUAD` — accelerate
**/
enum abstract UIEase(Int) from Int to Int {
	var LINEAR = 0;
	var OUT_QUAD = 1;
	var OUT_BACK = 2;
	var IN_QUAD = 3;
}
