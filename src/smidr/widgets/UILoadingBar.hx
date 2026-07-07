package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.UITween;

/**
	A progress bar for any long-running operation (downloads, uploads, decompression, loading).

	Two modes:
	- **Determinate** — assign `progress` (0..1); the fill tweens smoothly to the new value
	  (`smoothing = false` snaps instead).
	- **Indeterminate** — set `indeterminate = true` for unknown-length work; an accent band
	  sweeps the track until turned off.

	Layout follows the labelled-row convention (label left, optional percent, bar right); an
	empty label makes the bar span the full width. Idle-free by construction: a per-frame
	ticker runs only while the sweep animation or a smoothing tween is active, so a settled
	bar performs zero work.
**/
final class UILoadingBar extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	/** Target progress 0..1 (clamped). Assigning tweens the fill when `smoothing` is on. **/
	public var progress(default, set):Float = 0;

	/** Unknown-length mode: a sweeping band replaces the fill until turned off. **/
	public var indeterminate(default, set):Bool = false;

	/** Renders a right-aligned percent readout beside the bar (hidden while indeterminate). **/
	public var showPercent(default, set):Bool = false;

	/** Tween `progress` assignments instead of snapping. **/
	public var smoothing:Bool = true;

	/** Explicit ARGB fill (e.g. `UITheme.danger` on failure); 0 uses the theme accent. **/
	public var fillOverride(default, set):Int = 0;

	/** Base (unscaled) font size for the label/percent. **/
	public var fontSize(default, set):Int = 12;

	/** Width of the bar area on the right when a label is present. **/
	public var barWidth:Float;

	/** Base (unscaled) bar thickness. **/
	public var thickness:Float = #if mobile 9 #else 6 #end;

	/** Full sweep period of the indeterminate band, in ms. **/
	public var sweepMs:Float = 1100;

	final tf:TextField;
	var pctTf:TextField = null;

	var shown:Float = 0;
	var phase:Float = 0;
	var fillTween:UITween = null;
	var ticking:Bool = false;

	/**
		@param label the row text on the left (empty = the bar spans the whole row)
		@param width layout width
		@param progress the initial progress 0..1
	**/
	public function new(label:String, width:Float, progress:Float = 0) {
		super(false, false);
		this.label = label;
		barWidth = UITheme.px(160);
		@:bypassAccessor this.progress = clamp(progress);
		shown = this.progress;
		tf = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(tf);
		resize(width, UITheme.px(24));
		render();
	}

	/**
		Switches the label to a localized string.
		@param key the translation key
		@param fallback the source-language text
	**/
	public function localize(key:String, fallback:String):Void {
		this.fallback = fallback;
		this.key = key;
	}

	/**
		Sets the progress with explicit control over animation.
		@param value the target progress 0..1 (clamped)
		@param animate `true` tweens the fill, `false` snaps immediately
	**/
	public function setProgress(value:Float, animate:Bool = true):Void {
		value = clamp(value);
		@:bypassAccessor progress = value;
		killTween();
		if (!animate || indeterminate) {
			shown = value;
			invalidate();
			return;
		}
		fillTween = UITween.to(applyShown, shown, value, 160, UITween.OUT_QUAD, clearTween);
	}

	/**
		Convenience for byte/item counters.
		@param done the amount completed
		@param total the total amount (<= 0 switches to indeterminate)
	**/
	public inline function setRatio(done:Float, total:Float):Void {
		if (total <= 0)
			indeterminate = true;
		else {
			indeterminate = false;
			setProgress(done / total, smoothing);
		}
	}

	/** Snaps to 0 and clears indeterminate mode (reuse between operations). **/
	public function reset():Void {
		indeterminate = false;
		setProgress(0, false);
	}

	function applyShown(v:Float):Void {
		shown = v;
		invalidate();
	}

	function clearTween():Void {
		fillTween = null;
	}

	function killTween():Void {
		if (fillTween != null) {
			fillTween.cancel();
			fillTween = null;
		}
	}

	function tick(dtMs:Float):Void {
		phase += dtMs / sweepMs;
		if (phase >= 1)
			phase -= 1;
		invalidate();
	}

	static inline function clamp(v:Float):Float {
		return (v < 0) ? 0 : (v > 1 ? 1 : v);
	}

	inline function barX():Float {
		return (label != "" || key != null) ? w - barWidth : (showPercent && !indeterminate ? UITheme.px(40) : 0);
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var bx:Float = barX();
		var bw:Float = w - bx;
		var t:Float = UITheme.px(thickness);
		var by:Float = (h - t) / 2;
		var r:Float = t;

		g.beginFill(UIColor.rgb(UITheme.panel3));
		g.drawRoundRect(bx, by, bw, t, r, r);
		g.endFill();

		var fill:Int = (fillOverride != 0) ? fillOverride : UITheme.accent;
		if (indeterminate) {
			// clamp the sweeping band to the track (rounded caps square off at the edges)
			var bandW:Float = bw * 0.3;
			var x0:Float = bx - bandW + phase * (bw + bandW);
			var x1:Float = x0 + bandW;
			if (x0 < bx)
				x0 = bx;
			if (x1 > bx + bw)
				x1 = bx + bw;
			if (x1 - x0 > 1) {
				g.beginFill(UIColor.rgb(fill));
				g.drawRoundRect(x0, by, x1 - x0, t, r, r);
				g.endFill();
			}
		} else if (shown > 0) {
			var fw:Float = bw * shown;
			if (fw < t)
				fw = t;
			g.beginFill(UIColor.rgb(fill));
			g.drawRoundRect(bx, by, fw, t, r, r);
			g.endFill();
		}

		UIFonts.restyle(tf, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (tf.text != resolved)
			tf.text = resolved;
		tf.visible = resolved != "";
		tf.x = 0;
		tf.y = (h - tf.height) / 2;

		var pctOn:Bool = showPercent && !indeterminate;
		if (pctOn) {
			if (pctTf == null) {
				pctTf = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
				addChild(pctTf);
			}
			UIFonts.restyle(pctTf, UITheme.fs(fontSize), UITheme.text);
			var ps:String = Std.int(shown * 100 + 0.5) + "%";
			if (pctTf.text != ps)
				pctTf.text = ps;
			pctTf.visible = true;
			pctTf.x = bx - pctTf.width - UITheme.px(8);
			pctTf.y = (h - pctTf.height) / 2;
		} else if (pctTf != null)
			pctTf.visible = false;
	}

	function startTicker():Void {
		if (ticking)
			return;
		ticking = true;
		UIRoot.addTicker(tick);
	}

	function stopTicker():Void {
		if (!ticking)
			return;
		ticking = false;
		UIRoot.removeTicker(tick);
	}

	override public function dispose():Void {
		killTween();
		stopTicker();
		super.dispose();
	}

	function set_progress(v:Float):Float {
		setProgress(v, smoothing);
		return progress;
	}

	function set_indeterminate(v:Bool):Bool {
		if (indeterminate == v)
			return v;
		indeterminate = v;
		if (v) {
			killTween();
			phase = 0;
			startTicker();
		} else {
			stopTicker();
			shown = progress;
		}
		invalidate();
		return v;
	}

	function set_showPercent(v:Bool):Bool {
		if (showPercent == v)
			return v;
		showPercent = v;
		invalidate();
		return v;
	}

	function set_fillOverride(v:Int):Int {
		fillOverride = v;
		invalidate();
		return v;
	}

	function set_key(v:String):String {
		key = v;
		invalidate();
		return v;
	}

	function set_label(v:String):String {
		label = v;
		invalidate();
		return v;
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
