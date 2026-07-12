package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;

/**
	An exclusive-choice list of radio options (the vertical counterpart to `UISegmentedControl`):
	a stacked column of rows, each a dot on the left and a label on the right, with exactly one
	selected. Clicking a row selects it and fires `onSelect(index)`; picking another clears the
	previous one.

	The group is a passive container — the interactive rows are its children — so it lays out and
	re-themes like the rest of the library. Rows are fixed-height (`rowHeightBase`, taller on
	mobile for touch); the group's height follows the option count.
**/
final class UIRadioGroup extends UIComponent {
	/** The selected option index, or -1 when empty. **/
	public var selectedIndex(default, null):Int = 0;

	/** Fired when the selection changes (click or `select(i, true)`). **/
	public var onSelect:Int->Void = null;

	public var fontSize(default, set):Int = 12;

	/** Base (unscaled) per-row height. **/
	public var rowHeightBase(default, set):Float = #if mobile 32 #else 24 #end;

	var items:Array<String> = [];
	var itemKeys:Array<String> = null;
	var rows:Array<UIRadioRow> = [];

	/**
		@param items the option labels
		@param width layout width
		@param selected the initially selected index
		@param onSelect fired with the new index when the user picks an option
	**/
	public function new(items:Array<String>, width:Float, selected:Int = 0, ?onSelect:Int->Void) {
		super(false, false);
		this.onSelect = onSelect;
		@:bypassAccessor this.selectedIndex = selected;
		w = width;
		setItems(items);
	}

	/**
		Replaces the options (the selection clamps into range).
		@param items the option labels (also the localization fallbacks when `keys` is set)
		@param keys optional per-option translation keys resolved through `UILocale`
	**/
	public function setItems(items:Array<String>, ?keys:Array<String>):Void {
		this.items = items;
		this.itemKeys = keys;
		var i:Int = rows.length;
		while (--i >= 0)
			rows[i].dispose();
		rows.resize(0);
		i = 0;
		while (i < items.length) {
			var row:UIRadioRow = new UIRadioRow(this, i);
			addChild(row);
			rows.push(row);
			i++;
		}
		if (selectedIndex >= items.length)
			selectedIndex = items.length - 1;
		render();
	}

	/**
		Programmatically selects an option.
		@param index the option to select (ignored when out of range or unchanged)
		@param fire `true` also fires `onSelect`
	**/
	public function select(index:Int, fire:Bool = false):Void {
		if (index < 0 || index >= items.length || index == selectedIndex)
			return;
		var old:Int = selectedIndex;
		selectedIndex = index;
		invalidateRow(old);
		invalidateRow(index);
		if (fire && onSelect != null)
			onSelect(index);
	}

	/** The label text an option resolves to (through `UILocale` when a key is set). **/
	@:allow(smidr.widgets.UIRadioRow)
	function labelOf(index:Int):String {
		if (index < 0 || index >= items.length)
			return "";
		return (itemKeys != null && itemKeys[index] != null) ? UILocale.t(itemKeys[index], items[index]) : items[index];
	}

	@:allow(smidr.widgets.UIRadioRow)
	function pick(index:Int):Void {
		if (index == selectedIndex)
			return;
		var old:Int = selectedIndex;
		selectedIndex = index;
		invalidateRow(old);
		invalidateRow(index);
		if (onSelect != null)
			onSelect(index);
	}

	inline function invalidateRow(index:Int):Void {
		if (index >= 0 && index < rows.length)
			rows[index].invalidate();
	}

	override public function render():Void {
		var rowH:Float = UITheme.px(rowHeightBase);
		var i:Int = 0;
		var count:Int = rows.length;
		while (i < count) {
			var row:UIRadioRow = rows[i];
			row.y = i * rowH;
			row.resize(w, rowH);
			i++;
		}
		h = count * rowH;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		for (row in rows)
			row.invalidate();
		return value;
	}

	function set_rowHeightBase(value:Float):Float {
		rowHeightBase = value;
		invalidate();
		return value;
	}
}

/** One radio option row: a dot on the left, a label on the right, hover feedback. **/
private final class UIRadioRow extends UIComponent {
	final owner:UIRadioGroup;
	final index:Int;
	var labelField:TextField = null;

	public function new(owner:UIRadioGroup, index:Int) {
		super(true, true);
		this.owner = owner;
		this.index = index;
	}

	override function click():Void {
		owner.pick(index);
		super.click();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var selected:Bool = (index == owner.selectedIndex);
		var cx:Float = UITheme.px(9);
		var cy:Float = h / 2;
		var radius:Float = UITheme.px(7);
		if (hovered && !selected) {
			graphics.beginFill(UIColor.rgb(UITheme.panel3), 0.5);
			graphics.drawCircle(cx, cy, radius);
			graphics.endFill();
		}
		graphics.lineStyle(1.5, UIColor.rgb(selected ? UITheme.accent : UITheme.border2));
		graphics.drawCircle(cx, cy, radius);
		graphics.lineStyle();
		if (selected) {
			graphics.beginFill(UIColor.rgb(UITheme.accent));
			graphics.drawCircle(cx, cy, UITheme.px(3.5));
			graphics.endFill();
		}

		if (labelField == null) {
			labelField = UIFonts.make(UITheme.fs(owner.fontSize), UITheme.text2);
			addChild(labelField);
		}
		UIFonts.restyle(labelField, UITheme.fs(owner.fontSize), selected ? UITheme.text : UITheme.text2);
		var resolved:String = owner.labelOf(index);
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = UITheme.px(22);
		labelField.y = (h - labelField.height) / 2;
	}
}
