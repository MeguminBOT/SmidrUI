package smidr;

import openfl.display.DisplayObject;
import openfl.geom.Matrix;
import smidr.types.UIAnimationPreset;
import smidr.types.UIEase;
import smidr.types.UIEdge;

/** Optional overrides for `UIAnimation.play`. **/
typedef UIAnimOptions = {
	/** Duration in ms (preset-specific default when omitted). **/
	@:optional var duration:Float;

	/** Easing curve (preset-specific default when omitted). **/
	@:optional var ease:UIEase;

	/** Edge for the fly presets (default `BOTTOM`). **/
	@:optional var edge:UIEdge;

	/** Travel distance for the fly presets, in base pixels (default 64). **/
	@:optional var distance:Float;

	/** Fired once when the animation completes (not on manual `stop` unless `complete`). **/
	@:optional var onDone:Void->Void;
}

/**
	A preset transform animation on any `DisplayObject`, driven by one pooled `UITween` over a
	0..1 progress and applied through a center-pivoted matrix (so scale/rotate presets pivot on
	the object's centre, not its top-left origin). Entrance presets settle the target back to its
	captured resting transform; exit presets leave it hidden.

	```haxe
	UIAnimation.play(panel, POP);
	UIAnimation.play(toast, FLY_IN, {edge: TOP});
	UIAnimation.play(dialog, FADE_OUT, {onDone: dialog.dispose});
	```

	The resting transform (position, alpha) is captured at `play`, and the object's size is read
	then to find its centre — so start from a settled scale (1) and layout for the pivot to be
	right. `FLIP` is a 2D scale fake (OpenFL core has no 3D rotation).
**/
final class UIAnimation {
	final target:DisplayObject;
	final preset:UIAnimationPreset;
	final ease:UIEase;
	final duration:Float;
	final edgeX:Float;
	final edgeY:Float;
	final distance:Float;
	final amplitude:Float;
	final onDone:Void->Void;

	final baseX:Float;
	final baseY:Float;
	final baseAlpha:Float;
	final halfW:Float;
	final halfH:Float;

	final mtx:Matrix = new Matrix();
	var tween:UITween = null;

	/**
		Plays a preset animation on a display object.
		@param target the object to animate
		@param preset the animation preset
		@param opts optional duration/ease/edge/distance/onDone overrides
		@return the running animation (hold it only if you may `stop()`)
	**/
	public static function play(target:DisplayObject, preset:UIAnimationPreset, ?opts:UIAnimOptions):UIAnimation {
		var animation:UIAnimation = new UIAnimation(target, preset, opts);
		animation.start();
		return animation;
	}

	function new(target:DisplayObject, preset:UIAnimationPreset, ?opts:UIAnimOptions) {
		this.target = target;
		this.preset = preset;
		this.duration = (opts != null && opts.duration != null) ? opts.duration : defaultDuration(preset);
		this.ease = (opts != null && opts.ease != null) ? opts.ease : defaultEase(preset);
		this.onDone = (opts != null) ? opts.onDone : null;
		this.distance = UITheme.px((opts != null && opts.distance != null) ? opts.distance : 64);
		this.amplitude = UITheme.px(8);

		var edge:UIEdge = (opts != null && opts.edge != null) ? opts.edge : BOTTOM;
		edgeX = (edge == LEFT) ? -1 : (edge == RIGHT ? 1 : 0);
		edgeY = (edge == TOP) ? -1 : (edge == BOTTOM ? 1 : 0);

		baseX = target.x;
		baseY = target.y;
		baseAlpha = target.alpha;
		halfW = target.width * 0.5;
		halfH = target.height * 0.5;
	}

	function start():Void {
		tween = UITween.to(step, 0, 1, duration, ease, finish);
	}

	/**
		Stops the animation early.
		@param complete `true` jumps to and settles the end state (and fires `onDone`)
	**/
	public function stop(complete:Bool = false):Void {
		if (tween != null) {
			tween.cancel();
			tween = null;
		}
		if (complete)
			finish();
	}

	function finish():Void {
		tween = null;
		if (!isExit(preset))
			settle();
		if (onDone != null)
			onDone();
	}

	function step(progress:Float):Void {
		switch (preset) {
			case FLY_IN:
				apply(1, 1, 0, edgeX * (1 - progress) * distance, edgeY * (1 - progress) * distance, unit(progress));
			case FLY_OUT:
				apply(1, 1, 0, edgeX * progress * distance, edgeY * progress * distance, unit(1 - progress));
			case ZOOM_IN:
				apply(progress, progress, 0, 0, 0, unit(progress));
			case ZOOM_OUT:
				var scale:Float = 1 - progress;
				apply(scale, scale, 0, 0, 0, unit(scale));
			case FADE_IN:
				apply(1, 1, 0, 0, 0, unit(progress));
			case FADE_OUT:
				apply(1, 1, 0, 0, 0, unit(1 - progress));
			case POP:
				apply(progress, progress, 0, 0, 0, unit(progress * 1.4));
			case FLIP:
				var vv:Float = unit(progress);
				apply(-Math.cos(vv * Math.PI), 1, 0, 0, 0, (1 - Math.cos(vv * Math.PI)) / 2);
			case REVOLVE:
				apply(progress, progress, (1 - progress) * 2 * Math.PI, 0, 0, unit(progress));
			case SHAKE:
				apply(1, 1, 0, Math.sin(progress * Math.PI * 6) * amplitude * (1 - progress), 0, 1);
			case PULSE:
				var scale:Float = 1 + Math.sin(progress * Math.PI) * 0.08;
				apply(scale, scale, 0, 0, 0, 1);
			default:
		}
	}

	inline function apply(sx:Float, sy:Float, rot:Float, ox:Float, oy:Float, al:Float):Void {
		mtx.identity();
		mtx.translate(-halfW, -halfH);
		mtx.scale(sx, sy);
		if (rot != 0)
			mtx.rotate(rot);
		mtx.translate(baseX + halfW + ox, baseY + halfH + oy);
		target.transform.matrix = mtx;
		target.alpha = baseAlpha * al;
	}

	/** Restores a clean resting transform (no lingering matrix skew). **/
	inline function settle():Void {
		mtx.identity();
		mtx.translate(baseX, baseY);
		target.transform.matrix = mtx;
		target.alpha = baseAlpha;
	}

	static inline function isExit(preset:UIAnimationPreset):Bool {
		return preset == FLY_OUT || preset == ZOOM_OUT || preset == FADE_OUT;
	}

	static inline function unit(value:Float):Float {
		return (value < 0) ? 0 : (value > 1 ? 1 : value);
	}

	static function defaultDuration(preset:UIAnimationPreset):Float {
		return switch (preset) {
			case SHAKE: 420;
			case PULSE: 340;
			case FLY_OUT | ZOOM_OUT | FADE_OUT: 180;
			default: 240;
		}
	}

	static function defaultEase(preset:UIAnimationPreset):UIEase {
		return switch (preset) {
			case POP: OUT_BACK;
			case REVOLVE: OUT_CUBIC;
			case FLY_OUT | ZOOM_OUT | FADE_OUT: IN_QUAD;
			case SHAKE | PULSE: LINEAR;
			default: OUT_QUAD;
		}
	}
}
