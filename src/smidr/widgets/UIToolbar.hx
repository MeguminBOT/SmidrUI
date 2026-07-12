package smidr.widgets;

import smidr.UIColor;
import smidr.UIComponent;
import smidr.UITheme;

/**
	A horizontal button strip: add text or icon buttons, separators, and flexible spacers. The
	toolbar draws a themed bar (background + bottom border + separator ticks) and lays its items
	out left to right; spacers absorb the leftover width, so items after a spacer are pushed to
	the right edge. Buttons are ordinary `UIButton`s returned for further tweaking (accent, etc.).
**/
final class UIToolbar extends UIComponent {
	/** Base (unscaled) inset at each end. **/
	public var padding:Float = 6;

	/** Base (unscaled) gap between items. **/
	public var gap:Float = 4;

	static inline var KIND_BUTTON:Int = 0;
	static inline var KIND_SEP:Int = 1;
	static inline var KIND_SPACER:Int = 2;
	static inline var KIND_WIDGET:Int = 3;

	var kinds:Array<Int> = [];
	var buttons:Array<UIButton> = [];
	var extras:Array<UIComponent> = [];
	var heightBase:Float;
	var sepPositions:Array<Float> = [];

	/**
		@param height base (unscaled) bar height
	**/
	public function new(height:Float = 36) {
		super(false, true);
		heightBase = height;
		resize(UITheme.px(200), UITheme.px(height));
		render();
	}

	inline function buttonHeight():Float {
		return UITheme.px(heightBase) - UITheme.px(padding) * 2;
	}

	/**
		Adds a text button.
		@param label the button label
		@param width the button width
		@param onClick the click handler
		@return the button (for further configuration)
	**/
	public function addButton(label:String, width:Float, ?onClick:Void->Void):UIButton {
		var button:UIButton = new UIButton(label, width, buttonHeight(), onClick);
		addEntry(KIND_BUTTON, button);
		return button;
	}

	/**
		Adds an icon-only button.
		@param icon the icon
		@param onClick the click handler
		@return the button (for further configuration)
	**/
	public function addIconButton(icon:UIIcon, ?onClick:Void->Void):UIButton {
		var button:UIButton = UIButton.icon(icon, buttonHeight(), onClick);
		addEntry(KIND_BUTTON, button);
		return button;
	}

	/** Adds a vertical separator tick. **/
	public function addSeparator():Void {
		addEntry(KIND_SEP, null);
	}

	/** Adds a flexible spacer that absorbs leftover width (right-aligns following items). **/
	public function addSpacer():Void {
		addEntry(KIND_SPACER, null);
	}

	/**
		Adds an arbitrary widget to the bar (e.g. a `UIDropdown`), sized and vertically centered
		like a button. Returns the widget for further configuration.
		@param widget the component to host
		@param width the widget's width on the bar
	**/
	public function addWidget(widget:UIComponent, width:Float):UIComponent {
		widget.resize(width, buttonHeight());
		kinds.push(KIND_WIDGET);
		buttons.push(null);
		extras[kinds.length - 1] = widget;
		addChild(widget);
		invalidate();
		return widget;
	}

	function addEntry(kind:Int, button:UIButton):Void {
		kinds.push(kind);
		buttons.push(button);
		if (button != null)
			addChild(button);
		invalidate();
	}

	function layout():Void {
		var pad:Float = UITheme.px(padding);
		var gapPx:Float = UITheme.px(gap);
		var sepW:Float = UITheme.px(9);
		var fixed:Float = 0;
		var spacers:Int = 0;
		var items:Int = 0;
		for (i in 0...kinds.length) {
			switch (kinds[i]) {
				case KIND_BUTTON:
					fixed += buttons[i].w;
					items++;
				case KIND_SEP:
					fixed += sepW;
					items++;
				case KIND_SPACER:
					spacers++;
				case KIND_WIDGET:
					fixed += extras[i].w;
					items++;
			}
		}
		var gaps:Float = (items > 1) ? (items - 1) * gapPx : 0;
		var spacerW:Float = 0;
		if (spacers > 0) {
			var leftover:Float = w - pad * 2 - fixed - gaps;
			spacerW = (leftover > 0) ? leftover / spacers : 0;
		}

		sepPositions.resize(0);
		var x:Float = pad;
		var barH:Float = UITheme.px(heightBase);
		var btnY:Float = (barH - buttonHeight()) / 2;
		var first:Bool = true;
		for (i in 0...kinds.length) {
			switch (kinds[i]) {
				case KIND_BUTTON:
					if (!first)
						x += gapPx;
					buttons[i].x = x;
					buttons[i].y = btnY;
					x += buttons[i].w;
					first = false;
				case KIND_SEP:
					if (!first)
						x += gapPx;
					sepPositions.push(x + sepW / 2);
					x += sepW;
					first = false;
				case KIND_SPACER:
					x += spacerW;
				case KIND_WIDGET:
					if (!first)
						x += gapPx;
					extras[i].x = x;
					extras[i].y = (barH - extras[i].h) / 2;
					x += extras[i].w;
					first = false;
			}
		}
	}

	override public function render():Void {
		layout();
		graphics.clear();
		var barH:Float = UITheme.px(heightBase);
		graphics.beginFill(UIColor.rgb(UITheme.panel2));
		graphics.drawRect(0, 0, w, barH);
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(UITheme.border));
		graphics.drawRect(0, barH - 1, w, 1);
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(UITheme.border2));
		for (sx in sepPositions)
			graphics.drawRect(sx, UITheme.px(padding) + UITheme.px(2), 1, barH - UITheme.px(padding) * 2 - UITheme.px(4));
		graphics.endFill();
	}
}
