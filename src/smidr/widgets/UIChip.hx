package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.types.UIEase;

/**
	A compact pill chip. With `hasDot = true` it's a stateful toggle showing a status dot
	(`on` flips on click, then `onToggle(on)` fires); without a dot it's a value chip whose
	text the owner updates and whose `onClick` typically cycles the value. Auto-sizes to its
	label.
**/
final class UIChip extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	/** Toggle state (only meaningful with `hasDot`). **/
	public var on(default, set):Bool;

	/** Fired after the chip flips its own state. **/
	public var onToggle:Bool->Void = null;

	public var fontSize(default, set):Int = 12;

	public final hasDot:Bool;

	final labelField:TextField;

	/**
		@param label the chip text
		@param hasDot `true` makes the chip a self-flipping toggle with a status dot
		@param on the initial toggle state (dot chips only)
		@param onToggle fired after the chip flips its own state
	**/
	public function new(label:String, hasDot:Bool = false, on:Bool = false, ?onToggle:Bool->Void) {
		super(true, true);
		this.hasDot = hasDot;
		@:bypassAccessor this.on = on;
		this.onToggle = onToggle;
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		addChild(labelField);
		this.label = label;
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

	var dotPop:Float = 1;

	override function click():Void {
		if (hasDot) {
			@:bypassAccessor on = !on;
			invalidate();
			if (on)
				smidr.UITween.to(function(p:Float):Void {
					dotPop = 1.6 - 0.6 * p;
					invalidate();
				}, 0, 1, 215, OUT_QUAD);
			if (onToggle != null)
				onToggle(on);
		}
		super.click();
	}

	override public function render():Void {
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		UIFonts.restyle(labelField, UITheme.fs(fontSize), (hasDot && !on) ? UITheme.text2 : UITheme.text);
		if (labelField.text != resolved)
			labelField.text = resolved;

		var padX:Float = UITheme.px(10);
		var dotSpace:Float = hasDot ? UITheme.px(16) : 0;
		var height:Float = UITheme.px(24);
		var width:Float = padX * 2 + dotSpace + labelField.width;
		w = width;
		h = height;

		var base:Int = (hasDot && on) ? UITheme.panel3 : UITheme.panel2;
		if (hovered)
			base = UIColor.lighten(base, 0.10);
		if (pressed)
			base = UIColor.darken(base, 0.12);
		var line:Int = (hasDot && on) ? UITheme.accentDark : UITheme.border;

		graphics.clear();
		var radius:Float = height / 2;
		graphics.beginFill(UIColor.rgb(base));
		graphics.drawRoundRect(0, 0, width, height, radius * 2, radius * 2);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(line));
		graphics.drawRoundRect(0.5, 0.5, width - 1, height - 1, radius * 2, radius * 2);
		graphics.lineStyle();
		if (hasDot) {
			graphics.beginFill(UIColor.rgb(on ? UITheme.success : UITheme.border2));
			graphics.drawCircle(padX + UITheme.px(4), height / 2, UITheme.px(4.5) * dotPop);
			graphics.endFill();
		}
		labelField.x = padX + dotSpace;
		labelField.y = (height - labelField.height) / 2;
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

	function set_on(value:Bool):Bool {
		if (on == value)
			return value;
		on = value;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
