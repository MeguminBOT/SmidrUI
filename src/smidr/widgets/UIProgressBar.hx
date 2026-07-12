package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.UITween;
import smidr.types.UIEase;

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
final class UIProgressBar extends UIComponent {
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
	public var controlWidth:Float;

	/** Base (unscaled) bar thickness. **/
	public var thickness:Float = #if mobile 9 #else 6 #end;

	/** Full sweep period of the indeterminate band, in ms. **/
	public var sweepMs:Float = 1100;

	final labelField:TextField;
	var percentField:TextField = null;

	var shownProgress:Float = 0;
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
		controlWidth = UITheme.px(160);
		@:bypassAccessor this.progress = clamp(progress);
		shownProgress = this.progress;
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
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
			shownProgress = value;
			invalidate();
			return;
		}
		fillTween = UITween.to(applyShown, shownProgress, value, 160, OUT_QUAD, clearTween);
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

	function applyShown(value:Float):Void {
		shownProgress = value;
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

	static inline function clamp(value:Float):Float {
		return (value < 0) ? 0 : (value > 1 ? 1 : value);
	}

	inline function barX():Float {
		return (label != "" || key != null) ? w - controlWidth : (showPercent && !indeterminate ? UITheme.px(40) : 0);
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var bx:Float = barX();
		var bw:Float = w - bx;
		var barThickness:Float = UITheme.px(thickness);
		var by:Float = (h - barThickness) / 2;
		var radius:Float = barThickness;

		graphics.beginFill(UIColor.rgb(UITheme.panel3));
		graphics.drawRoundRect(bx, by, bw, barThickness, radius, radius);
		graphics.endFill();

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
				graphics.beginFill(UIColor.rgb(fill));
				graphics.drawRoundRect(x0, by, x1 - x0, barThickness, radius, radius);
				graphics.endFill();
			}
		} else if (shownProgress > 0) {
			var fw:Float = bw * shownProgress;
			if (fw < barThickness)
				fw = barThickness;
			graphics.beginFill(UIColor.rgb(fill));
			graphics.drawRoundRect(bx, by, fw, barThickness, radius, radius);
			graphics.endFill();
		}

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.visible = resolved != "";
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		var pctOn:Bool = showPercent && !indeterminate;
		if (pctOn) {
			if (percentField == null) {
				percentField = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
				addChild(percentField);
			}
			UIFonts.restyle(percentField, UITheme.fs(fontSize), UITheme.text);
			var ps:String = Std.int(shownProgress * 100 + 0.5) + "%";
			if (percentField.text != ps)
				percentField.text = ps;
			percentField.visible = true;
			percentField.x = bx - percentField.width - UITheme.px(8);
			percentField.y = (h - percentField.height) / 2;
		} else if (percentField != null)
			percentField.visible = false;
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

	function set_progress(value:Float):Float {
		setProgress(value, smoothing);
		return progress;
	}

	function set_indeterminate(value:Bool):Bool {
		if (indeterminate == value)
			return value;
		indeterminate = value;
		if (value) {
			killTween();
			phase = 0;
			startTicker();
		} else {
			stopTicker();
			shownProgress = progress;
		}
		invalidate();
		return value;
	}

	function set_showPercent(value:Bool):Bool {
		if (showPercent == value)
			return value;
		showPercent = value;
		invalidate();
		return value;
	}

	function set_fillOverride(value:Int):Int {
		fillOverride = value;
		invalidate();
		return value;
	}

	function set_key(value:String):String {
		key = value;
		invalidate();
		return value;
	}

	function set_label(value:String):String {
		label = value;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
