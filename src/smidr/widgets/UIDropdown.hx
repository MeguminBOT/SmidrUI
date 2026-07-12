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
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;
import smidr.types.UIEase;

/**
	A labelled dropdown row: label left, value box right. Clicking the box opens a scrollable
	popup list on `UIRoot.popupLayer` behind a click-blocking backdrop, so nothing underneath can
	be interacted with while it is open (Escape or an outside click closes it). `display` entries
	override row labels while `items` holds the raw values delivered to `onSelect`.

	Set `searchable` for combo-box type-ahead: while the popup is open, typing filters the list
	(case-insensitive substring on the shown labels), Backspace edits the query, and Enter picks
	the first match. A search header at the top of the popup shows the query.
**/
final class UIDropdown extends UIComponent implements IUIFocusable {
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

	/** Combo-box type-ahead: while open, typing filters the popup and Enter picks the first match. **/
	public var searchable:Bool = false;

	var items:Array<String> = [];
	var display:Array<String> = [];

	final labelField:TextField;
	final valueField:TextField;

	var popup:Sprite = null;
	var popupPane:UIScrollPane = null;
	var searchField:TextField = null;
	var query:String = "";
	var filtered:Array<Int> = [];
	var popupRowH:Float = 0;

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
		var text:String = (index >= 0 && index < display.length) ? display[index] : "";
		return (text == "") ? "-" : text;
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var bx:Float = w - controlWidth;
		var radius:Float = UITheme.px(6);
		var fill:Int = UITheme.panel2;
		if (hovered)
			fill = UIColor.lighten(fill, 0.08);
		graphics.beginFill(UIColor.rgb(fill));
		graphics.drawRoundRect(bx, 1, controlWidth, h - 2, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(popup != null ? UITheme.accent : UITheme.border));
		graphics.drawRoundRect(bx + 0.5, 1.5, controlWidth - 1, h - 3, radius, radius);
		graphics.lineStyle();
		// arrow
		var ax:Float = w - UITheme.px(13);
		var ay:Float = h / 2 - UITheme.px(1.5);
		graphics.beginFill(UIColor.rgb(UITheme.text2));
		graphics.moveTo(ax - UITheme.px(4), ay);
		graphics.lineTo(ax + UITheme.px(4), ay);
		graphics.lineTo(ax, ay + UITheme.px(4.5));
		graphics.endFill();

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), UITheme.text);
		var text:String = displayAt(selectedIndex);
		if (valueField.text != text)
			valueField.text = text;
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
		popupRowH = rowH;
		var rows:Int = (items.length < maxRows) ? items.length : maxRows;
		var listH:Float = rows * rowH + UITheme.px(8);
		var headerH:Float = searchable ? UITheme.px(26) : 0;
		var panelH:Float = headerH + listH;

		var origin:Point = localToGlobal(new Point(w - controlWidth, h));
		var local:Point = root.popupLayer.globalToLocal(origin);

		var panel:Sprite = new Sprite();
		var panelGraphics = panel.graphics;
		var radius:Float = UITheme.px(6);
		panelGraphics.beginFill(UIColor.rgb(UITheme.panel2));
		panelGraphics.drawRoundRect(0, 0, controlWidth, panelH, radius, radius);
		panelGraphics.endFill();
		panelGraphics.lineStyle(1, UIColor.rgb(UITheme.border2));
		panelGraphics.drawRoundRect(0.5, 0.5, controlWidth - 1, panelH - 1, radius, radius);
		panelGraphics.lineStyle();
		if (searchable) {
			panelGraphics.beginFill(UIColor.rgb(UITheme.border), 0.6);
			panelGraphics.drawRect(UITheme.px(8), headerH - 1, controlWidth - UITheme.px(16), 1);
			panelGraphics.endFill();
		}
		panel.x = local.x;
		// open upward when the list would clip past the window bottom
		var vh:Float = (root.stage != null && root.scaleY > 0) ? root.stage.stageHeight / root.scaleY : 720;
		var py:Float = local.y + 2;
		if (py + panelH > vh - 4)
			py = local.y - h - panelH - 2;
		if (py < 4)
			py = 4;
		panel.y = py;
		popup.addChild(panel);

		panel.alpha = 0;
		smidr.UITween.to(function(p:Float):Void {
			panel.alpha = p;
			panel.scaleY = 0.96 + 0.04 * p;
		}, 0, 1, 145, OUT_QUAD);

		if (searchable) {
			query = "";
			searchField = UIFonts.make(UITheme.fs(11), UITheme.text3);
			searchField.x = UITheme.px(9);
			searchField.y = (headerH - UITheme.px(15)) / 2;
			panel.addChild(searchField);
			updateSearchField();
		}

		popupPane = new UIScrollPane(controlWidth, listH - UITheme.px(8));
		popupPane.y = headerH + UITheme.px(4);
		panel.addChild(popupPane);
		recomputeFilter();
		rebuildRows();
		var pos:Int = filtered.indexOf(selectedIndex);
		if (pos >= 0) {
			if (pos * rowH > popupPane.maxScroll)
				popupPane.setScroll(popupPane.maxScroll);
			else if (pos >= rows)
				popupPane.setScroll(pos * rowH - listH / 2);
		}

		root.popupLayer.addChild(popup);
		UIRoot.pushOverlayCloser(closePopup);
		if (searchable)
			UIFocus.set(this);
		invalidate();
	}

	function recomputeFilter():Void {
		filtered.resize(0);
		if (query == "") {
			for (i in 0...items.length)
				filtered.push(i);
			return;
		}
		var needle:String = query.toLowerCase();
		for (i in 0...items.length) {
			if (displayAt(i).toLowerCase().indexOf(needle) >= 0)
				filtered.push(i);
		}
	}

	function rebuildRows():Void {
		if (popupPane == null)
			return;
		var content = popupPane.content;
		var i:Int = content.numChildren;
		while (--i >= 0) {
			var child = content.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		content.removeChildren();
		var pos:Int = 0;
		for (index in filtered) {
			var row:UIDropdownRow = new UIDropdownRow(this, index, displayAt(index), controlWidth, popupRowH, index == selectedIndex);
			row.y = pos * popupRowH;
			content.addChild(row);
			pos++;
		}
		popupPane.refreshContent(filtered.length * popupRowH);
	}

	function updateSearchField():Void {
		if (searchField == null)
			return;
		var empty:Bool = (query == "");
		UIFonts.restyle(searchField, UITheme.fs(11), empty ? UITheme.text3 : UITheme.text);
		var shown:String = empty ? "Type to filter..." : query;
		if (searchField.text != shown)
			searchField.text = shown;
	}

	function afterQueryChange():Void {
		recomputeFilter();
		rebuildRows();
		updateSearchField();
		if (popupPane != null)
			popupPane.setScroll(0);
	}

	/** Closes the popup list (no selection change). **/
	public function closePopup():Void {
		if (popup == null)
			return;
		UIRoot.removeOverlayCloser(closePopup);
		UIFocus.clear(this);
		searchField = null;
		query = "";
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

	public function capturesKeyboard():Bool {
		return popup != null && searchable;
	}

	public function onFocusGained():Void {}

	public function onFocusLost():Void {}

	public function onKeyDown(keyCode:Int, charCode:Int, ctrl:Bool, shift:Bool, alt:Bool):Bool {
		if (popup == null || !searchable)
			return false;
		switch (keyCode) {
			case 8: // Backspace
				if (query.length > 0) {
					query = query.substr(0, query.length - 1);
					afterQueryChange();
				}
				return true;
			case 13: // Enter picks the first match
				if (filtered.length > 0)
					pick(filtered[0]);
				else
					closePopup();
				return true;
			case 27: // Escape clears the query, then closes
				if (query != "") {
					query = "";
					afterQueryChange();
				} else
					closePopup();
				return true;
		}
		if (charCode >= 32 && charCode != 127) {
			query += String.fromCharCode(charCode);
			afterQueryChange();
			return true;
		}
		return false;
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

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
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
		graphics.clear();
		if (hovered) {
			graphics.beginFill(UIColor.rgb(UITheme.panel3));
			graphics.drawRoundRect(2, 0, w - 4, h, UITheme.px(5), UITheme.px(5));
			graphics.endFill();
		} else {
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}
		labelField.x = UITheme.px(8);
		labelField.y = (h - labelField.height) / 2;
	}
}
