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
		var tween:UITween = (pool.length > 0) ? pool.pop() : new UITween();
		tween.setter = setter;
		tween.startValue = from;
		tween.endValue = to;
		tween.duration = (durationMs > 1) ? durationMs : 1;
		tween.elapsed = 0;
		tween.ease = ease;
		tween.onComplete = onComplete;
		tween.alive = true;
		setter(from);
		active.push(tween);
		return tween;
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
			var tween:UITween = active[i];
			if (tween.alive) {
				tween.elapsed += dtMs;
				var progress:Float = tween.elapsed / tween.duration;
				if (progress >= 1) {
					tween.setter(tween.endValue);
					tween.alive = false;
					if (tween.onComplete != null)
						tween.onComplete();
				} else {
					tween.setter(tween.startValue + (tween.endValue - tween.startValue) * applyEase(tween.ease, progress));
				}
			}
			if (!tween.alive) {
				active.splice(i, 1);
				tween.setter = null;
				tween.onComplete = null;
				pool.push(tween);
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

	static function applyEase(ease:UIEase, progress:Float):Float {
		switch (ease) {
			case LINEAR:
				return progress;

			case IN_QUAD:
				return progress * progress;
			case OUT_QUAD:
				return 1 - (1 - progress) * (1 - progress);
			case IN_OUT_QUAD:
				return (progress < 0.5) ? 2 * progress * progress : 1 - Math.pow(-2 * progress + 2, 2) / 2;

			case IN_CUBIC:
				return progress * progress * progress;
			case OUT_CUBIC:
				return 1 - Math.pow(1 - progress, 3);
			case IN_OUT_CUBIC:
				return (progress < 0.5) ? 4 * progress * progress * progress : 1 - Math.pow(-2 * progress + 2, 3) / 2;

			case IN_QUART:
				return progress * progress * progress * progress;
			case OUT_QUART:
				return 1 - Math.pow(1 - progress, 4);
			case IN_OUT_QUART:
				return (progress < 0.5) ? 8 * progress * progress * progress * progress : 1 - Math.pow(-2 * progress + 2, 4) / 2;

			case IN_QUINT:
				return progress * progress * progress * progress * progress;
			case OUT_QUINT:
				return 1 - Math.pow(1 - progress, 5);
			case IN_OUT_QUINT:
				return (progress < 0.5) ? 16 * progress * progress * progress * progress * progress : 1 - Math.pow(-2 * progress + 2, 5) / 2;

			case IN_SINE:
				return 1 - Math.cos((progress * Math.PI) / 2);
			case OUT_SINE:
				return Math.sin((progress * Math.PI) / 2);
			case IN_OUT_SINE:
				return -(Math.cos(Math.PI * progress) - 1) / 2;

			case IN_EXPO:
				return (progress == 0) ? 0 : Math.pow(2, 10 * progress - 10);
			case OUT_EXPO:
				return (progress == 1) ? 1 : 1 - Math.pow(2, -10 * progress);
			case IN_OUT_EXPO:
				if (progress == 0)
					return 0;
				if (progress == 1)
					return 1;
				return (progress < 0.5) ? Math.pow(2, 20 * progress - 10) / 2 : (2 - Math.pow(2, -20 * progress + 10)) / 2;

			case IN_CIRC:
				return 1 - Math.sqrt(1 - progress * progress);
			case OUT_CIRC:
				return Math.sqrt(1 - (progress - 1) * (progress - 1));
			case IN_OUT_CIRC:
				return (progress < 0.5) ? (1 - Math.sqrt(1 - (2 * progress) * (2 * progress))) / 2 : (Math.sqrt(1 - (-2 * progress + 2) * (-2 * progress + 2)) + 1) / 2;

			case IN_BACK: {
					var c1:Float = 1.70158;
					return (c1 + 1) * progress * progress * progress - c1 * progress * progress;
				}
			case OUT_BACK: {
					var c1:Float = 1.70158;
					var shifted:Float = progress - 1;
					return 1 + (c1 + 1) * shifted * shifted * shifted + c1 * shifted * shifted;
				}
			case IN_OUT_BACK: {
					var c2:Float = 1.70158 * 1.525;
					if (progress < 0.5)
						return (Math.pow(2 * progress, 2) * ((c2 + 1) * 2 * progress - c2)) / 2;
					return (Math.pow(2 * progress - 2, 2) * ((c2 + 1) * (2 * progress - 2) + c2) + 2) / 2;
				}

			case IN_ELASTIC:
				if (progress == 0)
					return 0;
				if (progress == 1)
					return 1;
				return -Math.pow(2, 10 * progress - 10) * Math.sin((progress * 10 - 10.75) * (2 * Math.PI) / 3);
			case OUT_ELASTIC:
				if (progress == 0)
					return 0;
				if (progress == 1)
					return 1;
				return Math.pow(2, -10 * progress) * Math.sin((progress * 10 - 0.75) * (2 * Math.PI) / 3) + 1;
			case IN_OUT_ELASTIC:
				if (progress == 0)
					return 0;
				if (progress == 1)
					return 1;
				return (progress < 0.5) ? -(Math.pow(2, 20 * progress - 10) * Math.sin((20 * progress - 11.125) * (2 * Math.PI) / 4.5)) / 2 : (Math.pow(2,
					-20 * progress + 10) * Math.sin((20 * progress - 11.125) * (2 * Math.PI) / 4.5)) / 2 + 1;

			case IN_BOUNCE:
				return 1 - bounceOut(1 - progress);
			case OUT_BOUNCE:
				return bounceOut(progress);
			case IN_OUT_BOUNCE:
				return (progress < 0.5) ? (1 - bounceOut(1 - 2 * progress)) / 2 : (1 + bounceOut(2 * progress - 1)) / 2;

			default:
				return progress;
		}
	}

	static inline function bounceOut(progress:Float):Float {
		var n1:Float = 7.5625;
		var d1:Float = 2.75;
		if (progress < 1 / d1)
			return n1 * progress * progress;
		if (progress < 2 / d1) {
			progress -= 1.5 / d1;
			return n1 * progress * progress + 0.75;
		}
		if (progress < 2.5 / d1) {
			progress -= 2.25 / d1;
			return n1 * progress * progress + 0.9375;
		}
		progress -= 2.625 / d1;
		return n1 * progress * progress + 0.984375;
	}
}
