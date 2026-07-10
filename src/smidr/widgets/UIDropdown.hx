package smidr.widgets;

import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.types.UIEase;

/**
	A labelled dropdown row: label left, value box right. Clicking the box opens a scrollable
	popup list on `UIRoot.popupLayer` behind a click-blocking backdrop, so nothing underneath can
	be interacted with while it is open (Escape or an outside click closes it). `display` entries
	override row labels while `items` holds the raw values delivered to `onSelect`.
**/
final class UIDropdown extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var selectedIndex(default, null):Int = 0;
	public var onSelect:(index:Int, value:String) -> Void = null;
	public var fontSize(default, set):Int = 12;

	/** Width of the value box on the right; the label uses the remaining row width. **/
	public var controlWidth:Float;

	/** Max visible rows before the popup scrolls. **/
	public var maxRows:Int = 10;

	var items:Array<String> = [];
	var display:Array<String> = [];

	final labelField:TextField;
	final valueField:TextField;

	var popup:Sprite = null;
	var popupPane:UIScrollPane = null;

	/**
		@param label the row text on the left
		@param width layout width (the value box sits at the right edge)
		@param onSelect fired when the user picks an entry
	**/
	public function new(label:String, width:Float, ?onSelect:(index:Int, value:String) -> Void) {
		super(true, true);
		this.label = label;
		this.onSelect = onSelect;
		controlWidth = UITheme.px(140);
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
		valueField = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		valueField.autoSize = openfl.text.TextFieldAutoSize.NONE;
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

	/**
		Sets the entries, keeping the selection when possible.
		@param items the raw values delivered to `onSelect`
		@param display optional per-entry labels shown instead of the raw values
	**/
	public function setItems(items:Array<String>, ?display:Array<String>):Void {
		this.items = items;
		this.display = (display != null) ? display : items;
		if (selectedIndex >= items.length)
			selectedIndex = 0;
		invalidate();
	}

	/**
		Programmatically selects an index without firing `onSelect`.
		@param index the entry to select (ignored when out of range)
	**/
	public function select(index:Int):Void {
		if (index >= 0 && index < items.length && index != selectedIndex) {
			selectedIndex = index;
			invalidate();
		}
	}

	/** The raw value of the current selection ("" when empty). **/
	public var selectedValue(get, never):String;

	inline function get_selectedValue():String {
		return (selectedIndex >= 0 && selectedIndex < items.length) ? items[selectedIndex] : "";
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (localX < w - controlWidth)
			return;
		if (popup == null)
			openPopup();
		else
			closePopup();
	}

	function displayAt(index:Int):String {
		var s:String = (index >= 0 && index < display.length) ? display[index] : "";
		return (s == "") ? "-" : s;
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var bx:Float = w - controlWidth;
		var r:Float = UITheme.px(6);
		var fill:Int = UITheme.panel2;
		if (hovered)
			fill = UIColor.lighten(fill, 0.08);
		g.beginFill(UIColor.rgb(fill));
		g.drawRoundRect(bx, 1, controlWidth, h - 2, r, r);
		g.endFill();
		g.lineStyle(1, UIColor.rgb(popup != null ? UITheme.accent : UITheme.border));
		g.drawRoundRect(bx + 0.5, 1.5, controlWidth - 1, h - 3, r, r);
		g.lineStyle();
		// arrow
		var ax:Float = w - UITheme.px(13);
		var ay:Float = h / 2 - UITheme.px(1.5);
		g.beginFill(UIColor.rgb(UITheme.text2));
		g.moveTo(ax - UITheme.px(4), ay);
		g.lineTo(ax + UITheme.px(4), ay);
		g.lineTo(ax, ay + UITheme.px(4.5));
		g.endFill();

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), UITheme.text);
		var v:String = displayAt(selectedIndex);
		if (valueField.text != v)
			valueField.text = v;
		valueField.width = controlWidth - UITheme.px(26);
		valueField.height = valueField.textHeight + 4;
		valueField.x = bx + UITheme.px(8);
		valueField.y = (h - valueField.height) / 2;
	}

	function openPopup():Void {
		var root:UIRoot = UIRoot.current;
		if (root == null || items.length == 0)
			return;

		popup = new Sprite();
		var blocker:UIComponent = new UIComponent(true, true);
		blocker.hoverCursor = null;
		blocker.onClick = closePopup;
		blocker.graphics.beginFill(0, 0);
		blocker.graphics.drawRect(-16000, -16000, 32000, 32000);
		blocker.graphics.endFill();
		popup.addChild(blocker);

		var rowH:Float = UITheme.px(22);
		var rows:Int = (items.length < maxRows) ? items.length : maxRows;
		var listH:Float = rows * rowH + UITheme.px(8);

		var origin:Point = localToGlobal(new Point(w - controlWidth, h));
		var local:Point = root.popupLayer.globalToLocal(origin);

		var panel:Sprite = new Sprite();
		var g = panel.graphics;
		var r:Float = UITheme.px(6);
		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.drawRoundRect(0, 0, controlWidth, listH, r, r);
		g.endFill();
		g.lineStyle(1, UIColor.rgb(UITheme.border2));
		g.drawRoundRect(0.5, 0.5, controlWidth - 1, listH - 1, r, r);
		g.lineStyle();
		panel.x = local.x;
		// open upward when the list would clip past the window bottom
		var vh:Float = (root.stage != null && root.scaleY > 0) ? root.stage.stageHeight / root.scaleY : 720;
		var py:Float = local.y + 2;
		if (py + listH > vh - 4)
			py = local.y - h - listH - 2;
		if (py < 4)
			py = 4;
		panel.y = py;
		popup.addChild(panel);

		panel.alpha = 0;
		smidr.UITween.to(function(p:Float):Void {
			panel.alpha = p;
			panel.scaleY = 0.96 + 0.04 * p;
		}, 0, 1, 145, OUT_QUAD);

		popupPane = new UIScrollPane(controlWidth, listH - UITheme.px(8));
		popupPane.y = UITheme.px(4);
		var i:Int = 0;
		var n:Int = items.length;
		while (i < n) {
			var row:UIDropdownRow = new UIDropdownRow(this, i, displayAt(i), controlWidth, rowH, i == selectedIndex);
			row.y = i * rowH;
			popupPane.content.addChild(row);
			i++;
		}
		popupPane.refreshContent(n * rowH);
		if (selectedIndex * rowH > popupPane.maxScroll)
			popupPane.setScroll(popupPane.maxScroll);
		else if (selectedIndex >= rows)
			popupPane.setScroll(selectedIndex * rowH - listH / 2);
		panel.addChild(popupPane);

		root.popupLayer.addChild(popup);
		UIRoot.pushOverlayCloser(closePopup);
		invalidate();
	}

	/** Closes the popup list (no selection change). **/
	public function closePopup():Void {
		if (popup == null)
			return;
		UIRoot.removeOverlayCloser(closePopup);
		if (popupPane != null) {
			popupPane.dispose();
			popupPane = null;
		}
		var i:Int = popup.numChildren;
		while (--i >= 0) {
			var child = popup.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		popup.removeChildren();
		if (popup.parent != null)
			popup.parent.removeChild(popup);
		popup = null;
		invalidate();
	}

	@:allow(smidr.widgets.UIDropdownRow)
	function pick(index:Int):Void {
		selectedIndex = index;
		closePopup();
		invalidate();
		if (onSelect != null)
			onSelect(index, selectedValue);
	}

	override public function dispose():Void {
		closePopup();
		super.dispose();
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

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}

/** One popup row: hover highlight + click-to-pick. **/
private final class UIDropdownRow extends UIComponent {
	final owner:UIDropdown;
	final index:Int;
	final selected:Bool;
	final labelField:TextField;

	public function new(owner:UIDropdown, index:Int, text:String, width:Float, height:Float, selected:Bool) {
		super(true, true);
		this.owner = owner;
		this.index = index;
		this.selected = selected;
		labelField = UIFonts.make(UITheme.fs(11), selected ? UITheme.highlight : UITheme.text);
		labelField.text = text;
		addChild(labelField);
		resize(width, height);
		render();
	}

	override function click():Void {
		owner.pick(index);
		super.click();
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		if (hovered) {
			g.beginFill(UIColor.rgb(UITheme.panel3));
			g.drawRoundRect(2, 0, w - 4, h, UITheme.px(5), UITheme.px(5));
			g.endFill();
		} else {
			g.beginFill(0, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();
		}
		labelField.x = UITheme.px(8);
		labelField.y = (h - labelField.height) / 2;
	}
}
