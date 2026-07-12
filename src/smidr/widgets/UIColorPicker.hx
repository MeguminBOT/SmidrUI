package smidr.widgets;

import openfl.display.GradientType;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;

/**
	An inline HSV colour picker: a saturation/value square, a vertical hue strip, a live
	swatch + hex readout, and a row of preset swatches. Dragging the square sets saturation
	(x) and value (y); dragging the strip sets hue; clicking a preset jumps to it. `onChange`
	fires continuously while dragging with the opaque `0xFFRRGGBB` colour.

	The square and strip are gradient fills (no bitmaps), so the widget is cheap and repaints
	only when the selection moves. It reuses `UIColor.hsv` / `UIColor.toHSV`.
**/
final class UIColorPicker extends UIComponent {
	/** Fired continuously as the colour changes. **/
	public var onChange:Int->Void = null;

	/** The current colour (opaque `0xFFRRGGBB`). **/
	public var color(get, set):Int;

	/** Preset swatches shown in the bottom row (opaque colours). **/
	public var presets:Array<Int> = [
		UIColor.opaque(0xE23D3D), UIColor.opaque(0xE2913D), UIColor.opaque(0xE2D63D),
		UIColor.opaque(0x53C24E), UIColor.opaque(0x3DB7E2), UIColor.opaque(0x4E63C2),
		UIColor.opaque(0x9B4EC2), UIColor.opaque(0xE2E2E2), UIColor.opaque(0x2A2A2E)
	];

	static inline var CTRL_NONE:Int = 0;
	static inline var CTRL_SV:Int = 1;
	static inline var CTRL_HUE:Int = 2;

	var hue:Float = 0;
	var saturation:Float = 1;
	var value:Float = 1;
	var activeControl:Int = CTRL_NONE;

	final hexField:TextField;

	// geometry, recomputed from the layout width
	var squareW:Float = 0;
	var squareH:Float = 0;
	var stripX:Float = 0;
	var stripW:Float = 0;
	var presetY:Float = 0;
	var presetSize:Float = 0;
	var presetGap:Float = 0;

	/**
		@param width layout width
		@param initialColor the starting colour (default red)
		@param onChange fired continuously while the colour changes
	**/
	public function new(width:Float, ?initialColor:Int, ?onChange:Int->Void) {
		super(true, true);
		this.onChange = onChange;
		hoverCursor = openfl.ui.MouseCursor.BUTTON;
		hexField = UIFonts.make(UITheme.fs(12), UITheme.text);
		addChild(hexField);
		if (initialColor != null)
			applyColor(initialColor);
		resize(width, UITheme.px(198));
		render();
	}

	inline function get_color():Int {
		return UIColor.hsv(hue, saturation, value);
	}

	function set_color(next:Int):Int {
		applyColor(next);
		invalidate();
		return next;
	}

	function applyColor(rgba:Int):Void {
		var hsv = UIColor.toHSV(rgba);
		hue = hsv.hue;
		saturation = hsv.saturation;
		value = hsv.value;
	}

	function computeLayout():Void {
		stripW = UITheme.px(18);
		var gap:Float = UITheme.px(12);
		squareW = w - stripW - gap;
		squareH = UITheme.px(140);
		stripX = w - stripW;
		presetSize = UITheme.px(20);
		presetGap = UITheme.px(6);
		presetY = squareH + UITheme.px(34);
	}

	override function onPress(localX:Float, localY:Float):Void {
		computeLayout();
		if (localX <= squareW && localY <= squareH) {
			activeControl = CTRL_SV;
			updateSV(localX, localY);
			beginCapture();
			return;
		}
		if (localX >= stripX && localY <= squareH) {
			activeControl = CTRL_HUE;
			updateHue(localY);
			beginCapture();
			return;
		}
		if (localY >= presetY && localY <= presetY + presetSize) {
			var index:Int = Std.int(localX / (presetSize + presetGap));
			if (index >= 0 && index < presets.length && localX <= (index + 1) * (presetSize + presetGap) - presetGap) {
				applyColor(presets[index]);
				emit();
			}
		}
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		var local:Point = globalToLocal(new Point(stageX, stageY));
		if (activeControl == CTRL_SV)
			updateSV(local.x, local.y);
		else if (activeControl == CTRL_HUE)
			updateHue(local.y);
	}

	override function onDragEnd():Void {
		activeControl = CTRL_NONE;
	}

	function updateSV(localX:Float, localY:Float):Void {
		saturation = clamp01(localX / squareW);
		value = clamp01(1 - localY / squareH);
		emit();
	}

	function updateHue(localY:Float):Void {
		hue = clamp01(localY / squareH) * 360;
		emit();
	}

	inline function clamp01(amount:Float):Float {
		return (amount < 0) ? 0 : (amount > 1 ? 1 : amount);
	}

	function emit():Void {
		invalidate();
		if (onChange != null)
			onChange(color);
	}

	override public function render():Void {
		computeLayout();
		graphics.clear();

		var hueColor:Int = UIColor.rgb(UIColor.hsv(hue, 1, 1));
		var radius:Float = UITheme.px(6);

		// saturation/value square: white->hue horizontally, then transparent->black vertically
		var mtx:Matrix = new Matrix();
		mtx.createGradientBox(squareW, squareH, 0, 0, 0);
		graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, hueColor], [1, 1], [0, 255], mtx);
		graphics.drawRoundRect(0, 0, squareW, squareH, radius, radius);
		graphics.endFill();
		mtx.createGradientBox(squareW, squareH, Math.PI / 2, 0, 0);
		graphics.beginGradientFill(GradientType.LINEAR, [0x000000, 0x000000], [0, 1], [0, 255], mtx);
		graphics.drawRoundRect(0, 0, squareW, squareH, radius, radius);
		graphics.endFill();

		// SV cursor ring
		var cursorX:Float = saturation * squareW;
		var cursorY:Float = (1 - value) * squareH;
		graphics.lineStyle(UITheme.px(2), (value > 0.5 && saturation < 0.5) ? 0x000000 : 0xFFFFFF);
		graphics.drawCircle(cursorX, cursorY, UITheme.px(5));
		graphics.lineStyle();

		// hue strip
		var mtxH:Matrix = new Matrix();
		mtxH.createGradientBox(stripW, squareH, Math.PI / 2, stripX, 0);
		graphics.beginGradientFill(GradientType.LINEAR, [0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF, 0xFF0000],
			[1, 1, 1, 1, 1, 1, 1], [0, 42, 85, 128, 170, 213, 255], mtxH);
		graphics.drawRoundRect(stripX, 0, stripW, squareH, radius, radius);
		graphics.endFill();
		// hue marker
		var markerY:Float = (hue / 360) * squareH;
		graphics.lineStyle(UITheme.px(2), 0xFFFFFF);
		graphics.drawRoundRect(stripX - UITheme.px(1), markerY - UITheme.px(2), stripW + UITheme.px(2), UITheme.px(4), UITheme.px(2), UITheme.px(2));
		graphics.lineStyle();

		// swatch + hex
		var swatchY:Float = squareH + UITheme.px(8);
		var swatchSize:Float = UITheme.px(20);
		graphics.beginFill(UIColor.rgb(color));
		graphics.drawRoundRect(0, swatchY, swatchSize * 1.4, swatchSize, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(UITheme.border2));
		graphics.drawRoundRect(0.5, swatchY + 0.5, swatchSize * 1.4 - 1, swatchSize - 1, radius, radius);
		graphics.lineStyle();

		UIFonts.restyle(hexField, UITheme.fs(12), UITheme.text);
		var hex:String = "#" + StringTools.hex(UIColor.rgb(color), 6);
		if (hexField.text != hex)
			hexField.text = hex;
		hexField.x = swatchSize * 1.4 + UITheme.px(10);
		hexField.y = swatchY + (swatchSize - hexField.height) / 2;

		// presets
		var current:Int = color;
		for (i in 0...presets.length) {
			var px:Float = i * (presetSize + presetGap);
			graphics.beginFill(UIColor.rgb(presets[i]));
			graphics.drawRoundRect(px, presetY, presetSize, presetSize, UITheme.px(4), UITheme.px(4));
			graphics.endFill();
			graphics.lineStyle(1, UIColor.rgb((presets[i] == current) ? UITheme.accent : UITheme.border2));
			graphics.drawRoundRect(px + 0.5, presetY + 0.5, presetSize - 1, presetSize - 1, UITheme.px(4), UITheme.px(4));
			graphics.lineStyle();
		}
	}
}
