package smidr;

import smidr.types.UIEase;

/**
	Minimal pooled tween used for UI motion (dropdown pops, button dips, toasts).

	One driver (`UIRoot`) calls `step(dtMs)` per frame; starting a tween reuses a pooled
	instance, so steady-state UI motion performs zero allocations. Values are plain floats
	delivered through a setter — no reflection, no `Dynamic`. Easing curves are `UIEase` values.
**/
final class UITween {
	static final pool:Array<UITween> = [];
	static final active:Array<UITween> = [];

	var setter:Float->Void = null;
	var startValue:Float = 0;
	var endValue:Float = 0;
	var duration:Float = 1;
	var elapsed:Float = 0;
	var ease:UIEase = OUT_QUAD;
	var onComplete:Void->Void = null;
	var alive:Bool = false;

	function new() {}

	/**
		Starts a tween from a pooled instance (the setter is called immediately with `from`).
		@param setter receives the interpolated value each step
		@param from the start value
		@param to the end value
		@param durationMs total duration in milliseconds (clamped to >= 1)
		@param ease the easing curve (`LINEAR`/`OUT_QUAD`/`OUT_BACK`/`IN_QUAD`)
		@param onComplete fired once after the final value is delivered
		@return the running tween (hold it only if you may `cancel()`)
	**/
	public static function to(setter:Float->Void, from:Float, to:Float, durationMs:Float, ease:UIEase = OUT_QUAD, ?onComplete:Void->Void):UITween {
		var t:UITween = (pool.length > 0) ? pool.pop() : new UITween();
		t.setter = setter;
		t.startValue = from;
		t.endValue = to;
		t.duration = (durationMs > 1) ? durationMs : 1;
		t.elapsed = 0;
		t.ease = ease;
		t.onComplete = onComplete;
		t.alive = true;
		setter(from);
		active.push(t);
		return t;
	}

	/** Stops the tween without completing it. **/
	public function cancel():Void {
		alive = false;
	}

	/**
		Advances all running tweens; called once per frame by `UIRoot`.
		@param dtMs elapsed time since the last step, in milliseconds
	**/
	public static function step(dtMs:Float):Void {
		var i:Int = active.length;
		while (--i >= 0) {
			var t:UITween = active[i];
			if (t.alive) {
				t.elapsed += dtMs;
				var p:Float = t.elapsed / t.duration;
				if (p >= 1) {
					t.setter(t.endValue);
					t.alive = false;
					if (t.onComplete != null)
						t.onComplete();
				} else {
					t.setter(t.startValue + (t.endValue - t.startValue) * applyEase(t.ease, p));
				}
			}
			if (!t.alive) {
				active.splice(i, 1);
				t.setter = null;
				t.onComplete = null;
				pool.push(t);
			}
		}
	}

	/** Cancels every running tween (state teardown). **/
	public static function cancelAll():Void {
		var i:Int = active.length;
		while (--i >= 0)
			active[i].alive = false;
		step(0);
	}

	static function applyEase(ease:UIEase, p:Float):Float {
		switch (ease) {
			case LINEAR:
				return p;

			case IN_QUAD:
				return p * p;
			case OUT_QUAD:
				return 1 - (1 - p) * (1 - p);
			case IN_OUT_QUAD:
				return (p < 0.5) ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;

			case IN_CUBIC:
				return p * p * p;
			case OUT_CUBIC:
				return 1 - Math.pow(1 - p, 3);
			case IN_OUT_CUBIC:
				return (p < 0.5) ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;

			case IN_QUART:
				return p * p * p * p;
			case OUT_QUART:
				return 1 - Math.pow(1 - p, 4);
			case IN_OUT_QUART:
				return (p < 0.5) ? 8 * p * p * p * p : 1 - Math.pow(-2 * p + 2, 4) / 2;

			case IN_QUINT:
				return p * p * p * p * p;
			case OUT_QUINT:
				return 1 - Math.pow(1 - p, 5);
			case IN_OUT_QUINT:
				return (p < 0.5) ? 16 * p * p * p * p * p : 1 - Math.pow(-2 * p + 2, 5) / 2;

			case IN_SINE:
				return 1 - Math.cos((p * Math.PI) / 2);
			case OUT_SINE:
				return Math.sin((p * Math.PI) / 2);
			case IN_OUT_SINE:
				return -(Math.cos(Math.PI * p) - 1) / 2;

			case IN_EXPO:
				return (p == 0) ? 0 : Math.pow(2, 10 * p - 10);
			case OUT_EXPO:
				return (p == 1) ? 1 : 1 - Math.pow(2, -10 * p);
			case IN_OUT_EXPO:
				if (p == 0)
					return 0;
				if (p == 1)
					return 1;
				return (p < 0.5) ? Math.pow(2, 20 * p - 10) / 2 : (2 - Math.pow(2, -20 * p + 10)) / 2;

			case IN_CIRC:
				return 1 - Math.sqrt(1 - p * p);
			case OUT_CIRC:
				return Math.sqrt(1 - (p - 1) * (p - 1));
			case IN_OUT_CIRC:
				return (p < 0.5) ? (1 - Math.sqrt(1 - (2 * p) * (2 * p))) / 2 : (Math.sqrt(1 - (-2 * p + 2) * (-2 * p + 2)) + 1) / 2;

			case IN_BACK: {
					var c1:Float = 1.70158;
					return (c1 + 1) * p * p * p - c1 * p * p;
				}
			case OUT_BACK: {
					var c1:Float = 1.70158;
					var q:Float = p - 1;
					return 1 + (c1 + 1) * q * q * q + c1 * q * q;
				}
			case IN_OUT_BACK: {
					var c2:Float = 1.70158 * 1.525;
					if (p < 0.5)
						return (Math.pow(2 * p, 2) * ((c2 + 1) * 2 * p - c2)) / 2;
					return (Math.pow(2 * p - 2, 2) * ((c2 + 1) * (2 * p - 2) + c2) + 2) / 2;
				}

			case IN_ELASTIC:
				if (p == 0)
					return 0;
				if (p == 1)
					return 1;
				return -Math.pow(2, 10 * p - 10) * Math.sin((p * 10 - 10.75) * (2 * Math.PI) / 3);
			case OUT_ELASTIC:
				if (p == 0)
					return 0;
				if (p == 1)
					return 1;
				return Math.pow(2, -10 * p) * Math.sin((p * 10 - 0.75) * (2 * Math.PI) / 3) + 1;
			case IN_OUT_ELASTIC:
				if (p == 0)
					return 0;
				if (p == 1)
					return 1;
				return (p < 0.5) ? -(Math.pow(2, 20 * p - 10) * Math.sin((20 * p - 11.125) * (2 * Math.PI) / 4.5)) / 2 : (Math.pow(2,
					-20 * p + 10) * Math.sin((20 * p - 11.125) * (2 * Math.PI) / 4.5)) / 2 + 1;

			case IN_BOUNCE:
				return 1 - bounceOut(1 - p);
			case OUT_BOUNCE:
				return bounceOut(p);
			case IN_OUT_BOUNCE:
				return (p < 0.5) ? (1 - bounceOut(1 - 2 * p)) / 2 : (1 + bounceOut(2 * p - 1)) / 2;

			default:
				return p;
		}
	}

	static inline function bounceOut(p:Float):Float {
		var n1:Float = 7.5625;
		var d1:Float = 2.75;
		if (p < 1 / d1)
			return n1 * p * p;
		if (p < 2 / d1) {
			p -= 1.5 / d1;
			return n1 * p * p + 0.75;
		}
		if (p < 2.5 / d1) {
			p -= 2.25 / d1;
			return n1 * p * p + 0.9375;
		}
		p -= 2.625 / d1;
		return n1 * p * p + 0.984375;
	}
}
