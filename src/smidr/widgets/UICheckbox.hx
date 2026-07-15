package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;

/**
	A labelled checkbox row: label on the left, accent check square on the right (or standalone
	square when the label is empty). Clicking anywhere on the row toggles; `onToggle(checked)`
	fires after the flip.

	Under `UITheme.pillSwitches` (the mobile preset) the square renders as a sliding pill switch
	instead -- same API, the touch convention.
**/
final class UICheckbox extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;
	public var checked(default, set):Bool;
	public var onToggle:Bool->Void = null;
	public var fontSize(default, set):Int = 12;

	final labelField:TextField;

	/**
		@param label the row text (empty string = standalone check square)
		@param width layout width (the check square sits at the right edge)
		@param checked the initial state
		@param onToggle fired after the state flips
	**/
	public function new(label:String, width:Float, checked:Bool = false, ?onToggle:Bool->Void) {
		super(true, true);
		this.label = label;
		@:bypassAccessor this.checked = checked;
		this.onToggle = onToggle;
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

	override function click():Void {
		@:bypassAccessor checked = !checked;
		invalidate();
		if (onToggle != null)
			onToggle(checked);
		super.click();
	}

	override public function render():Void {
		graphics.clear();
		// invisible hit surface across the row
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var fill:Int = checked ? UITheme.accentDark : UITheme.panel2;
		if (hovered)
			fill = UIColor.lighten(fill, 0.10);

		if (UITheme.pillSwitches) {
			var trackW:Float = UITheme.px(34);
			var trackH:Float = UITheme.px(18);
			var bx:Float = w - trackW;
			var by:Float = (h - trackH) / 2;
			graphics.beginFill(UIColor.rgb(fill));
			graphics.drawRoundRect(bx, by, trackW, trackH, trackH, trackH);
			graphics.endFill();
			graphics.lineStyle(1, UIColor.rgb(UITheme.border2));
			graphics.drawRoundRect(bx + 0.5, by + 0.5, trackW - 1, trackH - 1, trackH - 1, trackH - 1);
			graphics.lineStyle();
			var kx:Float = checked ? (bx + trackW - trackH * 0.5) : (bx + trackH * 0.5);
			graphics.beginFill(UIColor.rgb(UITheme.text));
			graphics.drawCircle(kx, by + trackH * 0.5, trackH * 0.5 - UITheme.px(2));
			graphics.endFill();
		} else {
			var box:Float = UITheme.px(16);
			var bx:Float = w - box;
			var by:Float = (h - box) / 2;
			graphics.beginFill(UIColor.rgb(fill));
			graphics.drawRoundRect(bx, by, box, box, UITheme.px(6), UITheme.px(6));
			graphics.endFill();
			graphics.lineStyle(1, UIColor.rgb(UITheme.border2));
			graphics.drawRoundRect(bx + 0.5, by + 0.5, box - 1, box - 1, UITheme.px(6), UITheme.px(6));
			graphics.lineStyle();
			if (checked) {
				graphics.lineStyle(2, UIColor.rgb(UITheme.text));
				graphics.moveTo(bx + box * 0.22, by + box * 0.52);
				graphics.lineTo(bx + box * 0.44, by + box * 0.74);
				graphics.lineTo(bx + box * 0.80, by + box * 0.28);
				graphics.lineStyle();
			}
		}

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;
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

	function set_checked(value:Bool):Bool {
		if (checked == value)
			return value;
		checked = value;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
