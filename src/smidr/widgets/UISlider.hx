package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;

/**
	A labelled horizontal slider: label left, track + knob right, current value drawn beside the
	knob. Dragging anywhere on the track seeks; `onChange(value)` fires while dragging.
**/
final class UISlider extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var value(default, set):Float;
	public var min:Float = 0;
	public var max:Float = 1;
	public var decimals:Int = 2;
	public var onChange:Float->Void = null;
	public var fontSize(default, set):Int = 12;

	/** Width of the track area on the right. **/
	public var controlWidth:Float;

	final labelField:TextField;
	final valueField:TextField;

	var dragging:Bool = false;

	/**
		@param label the row text on the left
		@param width layout width (the track sits at the right edge)
		@param min the range minimum
		@param max the range maximum
		@param value the initial value
		@param onChange fired while dragging/seeking
	**/
	public function new(label:String, width:Float, min:Float, max:Float, value:Float, ?onChange:Float->Void) {
		super(true, true);
		this.label = label;
		this.min = min;
		this.max = max;
		@:bypassAccessor this.value = value;
		this.onChange = onChange;
		controlWidth = UITheme.px(120);
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
		valueField = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		addChild(valueField);
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

	override function onPress(localX:Float, localY:Float):Void {
		var tx:Float = w - controlWidth;
		if (localX < tx - UITheme.px(6))
			return;
		dragging = true;
		beginCapture();
		seekTo(localX);
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (!dragging)
			return;
		var local = globalToLocal(new openfl.geom.Point(stageX, stageY));
		seekTo(local.x);
	}

	override function onDragEnd():Void {
		dragging = false;
	}

	function seekTo(localX:Float):Void {
		var tx:Float = w - controlWidth;
		var progress:Float = (localX - tx) / controlWidth;
		if (progress < 0)
			progress = 0;
		if (progress > 1)
			progress = 1;
		var next:Float = min + (max - min) * progress;
		var factor:Float = Math.pow(10, decimals);
		next = Math.round(next * factor) / factor;
		if (next == value)
			return;
		@:bypassAccessor value = next;
		invalidate();
		if (onChange != null)
			onChange(next);
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var tx:Float = w - controlWidth;
		var cy:Float = h / 2;
		var progress:Float = (max > min) ? (value - min) / (max - min) : 0;
		if (progress < 0)
			progress = 0;
		if (progress > 1)
			progress = 1;

		graphics.beginFill(UIColor.rgb(UITheme.panel3));
		graphics.drawRoundRect(tx, cy - UITheme.px(2), controlWidth, UITheme.px(4), UITheme.px(4), UITheme.px(4));
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(UITheme.accentDark));
		graphics.drawRoundRect(tx, cy - UITheme.px(2), controlWidth * progress, UITheme.px(4), UITheme.px(4), UITheme.px(4));
		graphics.endFill();
		var knob:Int = hovered || dragging ? UIColor.lighten(UITheme.accent, 0.15) : UITheme.accent;
		graphics.beginFill(UIColor.rgb(knob));
		graphics.drawCircle(tx + controlWidth * progress, cy, UITheme.px(6));
		graphics.endFill();

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), UITheme.text);
		var vs:String = formatValue();
		if (valueField.text != vs)
			valueField.text = vs;
		valueField.x = tx - valueField.width - UITheme.px(8);
		valueField.y = (h - valueField.height) / 2;
	}

	function formatValue():String {
		if (decimals <= 0)
			return Std.string(Std.int(value));
		var factor:Float = Math.pow(10, decimals);
		return Std.string(Math.round(value * factor) / factor);
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

	function set_value(next:Float):Float {
		if (value == next)
			return next;
		value = next;
		invalidate();
		return next;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
