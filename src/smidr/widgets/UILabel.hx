package smidr.widgets;

import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormatAlign;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.types.UITone;

/**
	A themed, non-interactive text label. `tone` picks the theme text ramp (`PRIMARY`/`SECONDARY`/
	`TERTIARY`) so theme swaps restyle it; `colorOverride` pins an explicit ARGB color instead. Set
	`key` (+ `fallback`) for localized text, or assign `text` directly.
**/
final class UILabel extends UIComponent {
	/** Localization key; when set, `render()` resolves the text via `UILocale`. **/
	public var key(default, set):String = null;

	/** Fallback (and English source) for `key`. **/
	public var fallback:String = "";

	/** Raw text (used when `key` is null). **/
	public var text(default, set):String = "";

	/** `PRIMARY` = theme.text, `SECONDARY` = theme.text2, `TERTIARY` = theme.text3. **/
	public var tone(default, set):UITone = PRIMARY;

	/** Explicit ARGB color; overrides `tone` when != 0. **/
	public var colorOverride(default, set):Int = 0;

	/** Base (unscaled) font size. **/
	public var size(default, set):Int;

	public var align(default, set):TextFormatAlign;

	/** When `> 0`, the label word-wraps to this width (multi-line); `0` keeps the single-line auto-size. **/
	public var wrapWidth(default, set):Float = 0;

	final textField:TextField;

	/**
		@param text the initial raw text
		@param size base font size (scaled by the theme)
		@param tone theme text ramp: 0 = primary, 1 = secondary, 2 = tertiary
		@param align paragraph alignment (default LEFT)
	**/
	public function new(text:String = "", size:Int = 13, tone:UITone = PRIMARY, ?align:TextFormatAlign) {
		super(false, false);
		this.size = size;
		this.tone = tone;
		this.align = (align != null) ? align : TextFormatAlign.LEFT;
		textField = UIFonts.make(UITheme.fs(size), resolveColor());
		addChild(textField);
		this.text = text;
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

	inline function resolveColor():Int {
		return (colorOverride != 0) ? colorOverride : switch (tone) {
			case SECONDARY: UITheme.text2;
			case TERTIARY: UITheme.text3;
			default: UITheme.text;
		};
	}

	override public function render():Void {
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : text;
		UIFonts.restyle(textField, UITheme.fs(size), resolveColor(), align);
		if (wrapWidth > 0) {
			textField.multiline = true;
			textField.wordWrap = true;
			textField.autoSize = TextFieldAutoSize.NONE;
			textField.width = wrapWidth;
			if (textField.text != resolved)
				textField.text = resolved;
			w = wrapWidth;
			h = textField.textHeight + 4;
			textField.height = h;
		} else {
			textField.multiline = false;
			textField.wordWrap = false;
			textField.autoSize = TextFieldAutoSize.LEFT;
			if (textField.text != resolved)
				textField.text = resolved;
			w = textField.width;
			h = textField.height;
		}
	}

	function set_wrapWidth(value:Float):Float {
		if (wrapWidth == value)
			return value;
		wrapWidth = value;
		invalidate();
		return value;
	}

	/**
		Forces an immediate (re)layout so `w`/`h` are valid right now instead of on the next frame.
		Use before positioning sibling widgets below a wrapped label in a flow layout, where the
		deferred render would otherwise report a stale (often zero) height.
		@return the measured height
	**/
	public function measure():Float {
		render();
		return h;
	}

	function set_key(value:String):String {
		key = value;
		invalidate();
		return value;
	}

	function set_text(value:String):String {
		if (text == value)
			return value;
		text = value;
		invalidate();
		return value;
	}

	function set_tone(value:UITone):UITone {
		tone = value;
		invalidate();
		return value;
	}

	function set_colorOverride(value:Int):Int {
		colorOverride = value;
		invalidate();
		return value;
	}

	function set_size(value:Int):Int {
		size = value;
		invalidate();
		return value;
	}

	function set_align(value:TextFormatAlign):TextFormatAlign {
		align = value;
		invalidate();
		return value;
	}
}
