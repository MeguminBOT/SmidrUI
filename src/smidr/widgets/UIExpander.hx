package smidr.widgets;

import openfl.display.Sprite;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;

/**
	A single collapsible section: a clickable header with a rotating chevron over a body you fill
	via `content`. Unlike `UIAccordion` (which only toggles an external body's visibility), the
	expander owns its body and its own height grows/shrinks with the state, so `h` reflects
	`headerHeight` plus `contentHeight` while open. `onToggle(open)` lets a host relayout.
**/
final class UIExpander extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var title(default, set):String;

	/** The body container; add your widgets here. **/
	public var content(default, null):Sprite;

	/** Fired when the section opens (`true`) or closes (`false`). **/
	public var onToggle:Bool->Void = null;

	/** Whether the section is open. **/
	public var expanded(default, set):Bool = true;

	/** Base (unscaled) header height. **/
	public var headerHeightBase:Float = 30;

	/** Body height when open (set to your content's height). **/
	public var contentHeight(default, set):Float = 0;

	final header:UIExpanderHeader;

	/**
		@param title the header text
		@param width layout width
		@param expanded start open (default open)
		@param onToggle fired on open/close
	**/
	public function new(title:String, width:Float, expanded:Bool = true, ?onToggle:Bool->Void) {
		super(false, false);
		this.title = title;
		this.onToggle = onToggle;
		content = new Sprite();
		addChild(content);
		header = new UIExpanderHeader(this);
		addChild(header);
		this.expanded = expanded;
		resize(width, headerHeightBase);
		relayout();
		render();
	}

	/**
		Switches the header to a localized string.
		@param key the translation key
		@param fallback the source-language text
	**/
	public function localize(key:String, fallback:String):Void {
		this.fallback = fallback;
		this.key = key;
	}

	function set_expanded(value:Bool):Bool {
		if (expanded == value)
			return value;
		expanded = value;
		relayout();
		if (onToggle != null)
			onToggle(value);
		return value;
	}

	function set_contentHeight(value:Float):Float {
		contentHeight = value;
		relayout();
		return value;
	}

	@:allow(smidr.widgets.UIExpanderHeader)
	function toggle():Void {
		expanded = !expanded;
	}

	function relayout():Void {
		var headerH:Float = UITheme.px(headerHeightBase);
		content.y = headerH;
		content.visible = expanded;
		var total:Float = headerH + (expanded ? contentHeight : 0);
		resize(w, total);
		if (header != null)
			header.resize(w, headerH);
	}

	override public function render():Void {
		if (header != null)
			header.resize(w, UITheme.px(headerHeightBase));
	}

	function set_key(value:String):String {
		key = value;
		if (header != null)
			header.invalidate();
		return value;
	}

	function set_title(value:String):String {
		title = value;
		if (header != null)
			header.invalidate();
		return value;
	}
}

/** The expander's clickable header: chevron + title, toggles on click. **/
private final class UIExpanderHeader extends UIComponent {
	final owner:UIExpander;
	final titleField:TextField;

	public function new(owner:UIExpander) {
		super(true, true);
		this.owner = owner;
		titleField = UIFonts.make(UITheme.fs(13), UITheme.text);
		addChild(titleField);
	}

	override function click():Void {
		owner.toggle();
		super.click();
	}

	override public function render():Void {
		graphics.clear();
		var radius:Float = UITheme.px(6);
		graphics.beginFill(UIColor.rgb(hovered ? UITheme.panel3 : UITheme.panel2));
		graphics.drawRoundRect(0, 0, w, h, radius, radius);
		graphics.endFill();

		// chevron: right when collapsed, down when expanded
		var cx:Float = UITheme.px(14);
		var cy:Float = h / 2;
		var reach:Float = UITheme.px(4);
		graphics.beginFill(UIColor.rgb(UITheme.text2));
		if (owner.expanded) {
			graphics.moveTo(cx - reach, cy - reach * 0.5);
			graphics.lineTo(cx + reach, cy - reach * 0.5);
			graphics.lineTo(cx, cy + reach * 0.7);
		} else {
			graphics.moveTo(cx - reach * 0.5, cy - reach);
			graphics.lineTo(cx + reach * 0.7, cy);
			graphics.lineTo(cx - reach * 0.5, cy + reach);
		}
		graphics.endFill();

		UIFonts.restyle(titleField, UITheme.fs(13), UITheme.text);
		var resolved:String = (owner.key != null) ? UILocale.t(owner.key, owner.fallback) : owner.title;
		if (titleField.text != resolved)
			titleField.text = resolved;
		titleField.x = UITheme.px(26);
		titleField.y = (h - titleField.height) / 2;
	}
}
