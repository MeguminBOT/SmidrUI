package smidr;

import openfl.display.GradientType;
import openfl.display.Graphics;
import openfl.geom.Matrix;

/**
	A linear or radial gradient fill, the richer opt-in alternative to a flat `UIFill`. Hold one on
	a widget that supports it (e.g. `UIPanel.gradient`) and it overrides the flat fill.

	Colours are ordinary `0xAARRGGBB` stops (alpha per stop is honoured). `paint`/`fillRect` build
	the gradient box matrix and call `Graphics.beginGradientFill` — decomposing the ARGB stops into
	OpenFL's separate RGB + alpha arrays through reused static buffers, so a steady-state repaint
	allocates nothing. Because these stops are fixed colours they do NOT follow theme swaps; derive
	them from `UITheme` values at build time (and rebuild on `UITheme.onChanged`) if you need them to.
**/
final class UIGradient {
	/** `LINEAR` or `RADIAL`. **/
	public var type:GradientType;

	/** The ARGB colour stops. **/
	public var colors:Array<Int>;

	/** Per-stop positions 0..255 (same length as `colors`). **/
	public var ratios:Array<Int>;

	/** Gradient direction in degrees for `LINEAR` (0 = left→right, 90 = top→bottom). **/
	public var angle:Float;

	static final mtx:Matrix = new Matrix();
	static final rgbBuf:Array<Int> = [];
	static final alphaBuf:Array<Float> = [];

	function new(type:GradientType, colors:Array<Int>, ratios:Array<Int>, angle:Float) {
		this.type = type;
		this.colors = colors;
		this.ratios = ratios;
		this.angle = angle;
	}

	/**
		A linear gradient across `colors`.
		@param colors the ARGB stops (2+)
		@param angle direction in degrees (0 = left→right, 90 = top→bottom)
		@param ratios optional per-stop positions 0..255 (evenly spread when omitted)
		@return the gradient
	**/
	public static function linear(colors:Array<Int>, angle:Float = 90, ?ratios:Array<Int>):UIGradient {
		return new UIGradient(GradientType.LINEAR, colors, (ratios != null) ? ratios : evenRatios(colors.length), angle);
	}

	/**
		A radial gradient from the centre outward.
		@param colors the ARGB stops (centre first)
		@param ratios optional per-stop positions 0..255 (evenly spread when omitted)
		@return the gradient
	**/
	public static function radial(colors:Array<Int>, ?ratios:Array<Int>):UIGradient {
		return new UIGradient(GradientType.RADIAL, colors, (ratios != null) ? ratios : evenRatios(colors.length), 0);
	}

	/**
		A two-stop top→bottom linear gradient.
		@param top the top colour (ARGB)
		@param bottom the bottom colour (ARGB)
		@return the gradient
	**/
	public static inline function vertical(top:Int, bottom:Int):UIGradient {
		return linear([top, bottom], 90);
	}

	/**
		A two-stop left→right linear gradient.
		@param left the left colour (ARGB)
		@param right the right colour (ARGB)
		@return the gradient
	**/
	public static inline function horizontal(left:Int, right:Int):UIGradient {
		return linear([left, right], 0);
	}

	static function evenRatios(count:Int):Array<Int> {
		if (count <= 1)
			return [0];
		var out:Array<Int> = [];
		for (i in 0...count)
			out.push(Std.int(i / (count - 1) * 255 + 0.5));
		return out;
	}

	/**
		Opens the gradient fill on `graphics` (the caller then draws the shape and `endFill`s). Use
		for non-rectangular shapes; `fillRect` covers the common rectangle case.
		@param graphics the target graphics
		@param x the fill box left
		@param y the fill box top
		@param width the fill box width
		@param height the fill box height
	**/
	public function beginFill(graphics:Graphics, x:Float, y:Float, width:Float, height:Float):Void {
		var count:Int = colors.length;
		rgbBuf.resize(count);
		alphaBuf.resize(count);
		for (i in 0...count) {
			var stop:Int = colors[i];
			rgbBuf[i] = stop & 0xFFFFFF;
			alphaBuf[i] = ((stop >>> 24) & 0xFF) / 255.0;
		}
		var rotation:Float = (type == GradientType.LINEAR) ? angle * Math.PI / 180 : 0;
		mtx.createGradientBox(width, height, rotation, x, y);
		graphics.beginGradientFill(type, rgbBuf, alphaBuf, ratios, mtx);
	}

	/**
		Fills a rectangle (optionally rounded) with the gradient.
		@param graphics the target graphics
		@param x the rect left
		@param y the rect top
		@param width the rect width
		@param height the rect height
		@param corner corner radius in pixels (0 = square)
	**/
	public function fillRect(graphics:Graphics, x:Float, y:Float, width:Float, height:Float, corner:Float = 0):Void {
		beginFill(graphics, x, y, width, height);
		if (corner > 0)
			graphics.drawRoundRect(x, y, width, height, corner, corner);
		else
			graphics.drawRect(x, y, width, height);
		graphics.endFill();
	}
}
