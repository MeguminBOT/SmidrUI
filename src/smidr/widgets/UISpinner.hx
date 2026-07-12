package smidr.widgets;

import openfl.display.CapsStyle;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIRoot;
import smidr.UITheme;

/**
	An indeterminate busy spinner: a faint full ring with a brighter sweeping arc that rotates
	while `spinning`. It steps a `UIRoot` ticker (only while spinning) and repaints the arc each
	frame, so an idle spinner costs nothing. Pair it with `UIProgressBar` for determinate work.
**/
final class UISpinner extends UIComponent {
	/** Arc colour, or -1 for the theme accent. **/
	public var color:Int = -1;

	/** Base (unscaled) stroke thickness. **/
	public var thickness:Float = 3;

	/** Revolutions per second. **/
	public var speed:Float = 0.9;

	/** Whether the arc is rotating (starts/stops the ticker). **/
	public var spinning(default, set):Bool = false;

	var phase:Float = 0;
	var running:Bool = false;

	/**
		@param size base (unscaled) diameter
	**/
	public function new(size:Float = 28) {
		super(false, false);
		resize(UITheme.px(size), UITheme.px(size));
		spinning = true;
		render();
	}

	function set_spinning(value:Bool):Bool {
		if (spinning == value)
			return value;
		spinning = value;
		if (value)
			startTicker();
		else
			stopTicker();
		invalidate();
		return value;
	}

	function startTicker():Void {
		if (running)
			return;
		running = true;
		UIRoot.addTicker(tick);
	}

	function stopTicker():Void {
		if (!running)
			return;
		running = false;
		UIRoot.removeTicker(tick);
	}

	function tick(dtMs:Float):Void {
		phase += dtMs / 1000 * Math.PI * 2 * speed;
		if (phase > Math.PI * 2)
			phase -= Math.PI * 2;
		invalidate();
	}

	override public function render():Void {
		graphics.clear();
		var cx:Float = w / 2;
		var cy:Float = h / 2;
		var stroke:Float = UITheme.px(thickness);
		var radius:Float = (w < h ? w : h) / 2 - stroke;
		if (radius <= 0)
			return;

		graphics.lineStyle(stroke, UIColor.rgb(UITheme.border2), 0.5, false, null, CapsStyle.ROUND);
		drawArc(cx, cy, radius, 0, Math.PI * 2);

		var arcColor:Int = (color == -1) ? UITheme.accent : color;
		graphics.lineStyle(stroke, UIColor.rgb(arcColor), 1, false, null, CapsStyle.ROUND);
		drawArc(cx, cy, radius, phase, phase + Math.PI * 1.5);
		graphics.lineStyle();
	}

	function drawArc(cx:Float, cy:Float, radius:Float, from:Float, to:Float):Void {
		var segments:Int = 32;
		var step:Float = (to - from) / segments;
		graphics.moveTo(cx + Math.cos(from) * radius, cy + Math.sin(from) * radius);
		var i:Int = 1;
		while (i <= segments) {
			var angle:Float = from + step * i;
			graphics.lineTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
			i++;
		}
	}

	override public function dispose():Void {
		stopTicker();
		super.dispose();
	}
}
