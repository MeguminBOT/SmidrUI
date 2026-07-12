package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;

/**
	A collapsible section header: chevron, all-caps title, underline and an optional
	right-aligned hint. The owner toggles its section's content visibility from
	`onToggle(expanded)` and re-flows the layout.
**/
final class UIAccordion extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var title(default, set):String;
	public var hint(default, set):String = null;
	public var expanded(default, set):Bool = true;
	public var onToggle:Bool->Void = null;

	final labelField:TextField;
	var hintField:TextField = null;

	/**
		@param title the header text (rendered upper-case)
		@param width layout width
		@param expanded the initial state
		@param onToggle fired after a click flips the state
	**/
	public function new(title:String, width:Float, expanded:Bool = true, ?onToggle:Bool->Void) {
		super(true, true);
		this.title = title;
		@:bypassAccessor this.expanded = expanded;
		this.onToggle = onToggle;
		labelField = UIFonts.make(UITheme.fs(10), UITheme.text3);
		addChild(labelField);
		resize(width, UITheme.px(22));
		render();
	}

	/**
		Switches the title to a localized string.
		@param key the translation key
		@param fallback the source-language text
	**/
	public function localize(key:String, fallback:String):Void {
		this.fallback = fallback;
		this.key = key;
	}

	override function click():Void {
		@:bypassAccessor expanded = !expanded;
		invalidate();
		if (onToggle != null)
			onToggle(expanded);
		super.click();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		// chevron
		var color:Int = UIColor.rgb(UITheme.text3);
		var cy:Float = h / 2;
		graphics.beginFill(color);
		if (expanded) {
			graphics.moveTo(UITheme.px(1), cy - UITheme.px(2.5));
			graphics.lineTo(UITheme.px(9), cy - UITheme.px(2.5));
			graphics.lineTo(UITheme.px(5), cy + UITheme.px(3));
		} else {
			graphics.moveTo(UITheme.px(2), cy - UITheme.px(4));
			graphics.lineTo(UITheme.px(7.5), cy);
			graphics.lineTo(UITheme.px(2), cy + UITheme.px(4));
		}
		graphics.endFill();

		UIFonts.restyle(labelField, UITheme.fs(10), UITheme.text3);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : title;
		resolved = resolved.toUpperCase();
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = UITheme.px(14);
		labelField.y = (h - labelField.height) / 2 - 1;

		if (hint != null && hint != "") {
			if (hintField == null) {
				hintField = UIFonts.make(UITheme.fs(9), UITheme.text3);
				addChild(hintField);
			}
			UIFonts.restyle(hintField, UITheme.fs(9), UITheme.text3);
			if (hintField.text != hint)
				hintField.text = hint;
			hintField.visible = true;
			hintField.x = w - hintField.width;
			hintField.y = (h - hintField.height) / 2;
		} else if (hintField != null)
			hintField.visible = false;

		graphics.beginFill(UIColor.rgb(UITheme.border));
		graphics.drawRect(0, h - 1, w, 1);
		graphics.endFill();
	}

	function set_key(value:String):String {
		key = value;
		invalidate();
		return value;
	}

	function set_title(value:String):String {
		title = value;
		invalidate();
		return value;
	}

	function set_hint(value:String):String {
		hint = value;
		invalidate();
		return value;
	}

	function set_expanded(value:Bool):Bool {
		if (expanded == value)
			return value;
		expanded = value;
		invalidate();
		return value;
	}
}
