package smidr.widgets;

import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;

/**
	A clickable button. Variants: default (panel surface), `accent` (primary action) and
	`danger` (destructive). Hover lightens, press dips; the click fires on press-started
	release (see `UIComponent`).

	A button may show a label, a `UIIcon`, or both: assign `icon` (or build an icon-only button
	with `UIButton.icon(...)`). The icon may be a built-in glyph (`UIIcon.fromGlyph`) or an asset —
	that is up to the caller. The button colours the icon to match its label (contrast against the
	fill). A toolbar-style toggle is just `accent` flipped at runtime.
**/
final class UIButton extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;
	public var accent(default, set):Bool = false;
	public var danger(default, set):Bool = false;

	/** Base (unscaled) font size. **/
	public var fontSize(default, set):Int = 13;

	/** The hosted icon, or `null`; set through `setIcon` (the static `icon` factory uses it). **/
	var iconObj:UIIcon = null;

	final labelField:TextField;

	/**
		@param label the button text (raw; use `localize` for translated labels)
		@param width layout width
		@param height layout height
		@param onClick fired on a completed click
		@param accent `true` renders the primary-action variant
	**/
	public function new(label:String, width:Float, height:Float, ?onClick:Void->Void, accent:Bool = false) {
		super(true, true);
		this.label = label;
		this.accent = accent;
		this.onClick = onClick;
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text, TextFormatAlign.CENTER);
		labelField.autoSize = openfl.text.TextFieldAutoSize.NONE;
		addChild(labelField);
		resize(width, height);
		render();
	}

	/**
		Builds a square, icon-only button hosting a `UIIcon` (glyph- or asset-backed — the caller
		decides). A toolbar toggle is just `accent` flipped at runtime.
		@param icon the icon to show
		@param size the square edge length
		@param onClick fired on a completed click
		@return the configured button
	**/
	public static function icon(icon:UIIcon, size:Float, ?onClick:Void->Void):UIButton {
		var b:UIButton = new UIButton("", size, size, onClick);
		b.setIcon(icon);
		return b;
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

	override public function render():Void {
		var base:Int = accent ? UITheme.accentDark : (danger ? 0xFF60202E : UITheme.panel2);
		var line:Int = accent ? UITheme.accent : (danger ? UITheme.danger : UITheme.border);
		if (pressed)
			base = UIColor.darken(base, 0.18);
		else if (hovered)
			base = UIColor.lighten(base, 0.10);
		var g = graphics;
		g.clear();
		var r:Float = UITheme.px(UITheme.radius);
		g.beginFill(UIColor.rgb(base));
		g.drawRoundRect(0, 0, w, h, r * 2, r * 2);
		g.endFill();
		g.lineStyle(1, UIColor.rgb(line));
		g.drawRoundRect(0.5, 0.5, w - 1, h - 1, r * 2, r * 2);
		g.lineStyle();

		// accent/danger fills are dark in every theme, so pick contrast from the fill rather than
		// UITheme.text (which flips to dark on light themes and would vanish on the button)
		var textColor:Int = (accent || danger) ? UIColor.contrastText(base) : UITheme.text2;
		UIFonts.restyle(labelField, UITheme.fs(fontSize), textColor, TextFormatAlign.CENTER);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (resolved == null)
			resolved = "";
		var hasLabel:Bool = resolved != "";
		var dip:Float = pressed ? 1 : 0;

		labelField.visible = hasLabel;
		if (hasLabel) {
			if (labelField.text != resolved)
				labelField.text = resolved;
			labelField.width = w;
			labelField.height = labelField.textHeight + 4;
			// with an icon the icon sits in the left inset; the label stays centred
			labelField.x = 0;
			labelField.y = (h - labelField.height) / 2 + dip;
		}

		if (iconObj != null) {
			// icon-only: centre; icon + label: left-inset. The icon keeps its own size.
			var iw:Float = UITheme.px(iconObj.size);
			iconObj.x = hasLabel ? UITheme.px(10) : (w - iw) / 2;
			iconObj.y = (h - iw) / 2 + dip;
			// drive the icon to the button's foreground colour so it matches the label
			if (iconObj.colorOverride != textColor)
				iconObj.colorOverride = textColor;
		}
	}

	/**
		Sets (or clears) the hosted icon. The icon may be glyph- or asset-backed; the button drives
		its colour to match the label (contrast against the button fill).
		@param v the icon to show, or `null` to remove it
		@return this button (for chaining)
	**/
	public function setIcon(v:UIIcon):UIButton {
		if (iconObj == v)
			return this;
		if (iconObj != null && iconObj.parent == this)
			removeChild(iconObj);
		iconObj = v;
		if (iconObj != null)
			addChild(iconObj);
		invalidate();
		return this;
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

	function set_accent(v:Bool):Bool {
		accent = v;
		invalidate();
		return v;
	}

	function set_danger(v:Bool):Bool {
		danger = v;
		invalidate();
		return v;
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
