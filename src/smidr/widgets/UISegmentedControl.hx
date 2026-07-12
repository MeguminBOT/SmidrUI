package smidr.widgets;

import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.UITween;
import smidr.types.UIEase;

/**
	An exclusive-choice segmented control (radio group): label left, equal-width segments in a
	box on the right. Exactly one segment is selected; picking another slides the accent pill
	over and fires `onSelect(index)`. Taller by default on mobile for touch.
**/
final class UISegmentedControl extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var selectedIndex(default, null):Int = 0;
	public var onSelect:Int->Void = null;
	public var fontSize(default, set):Int = 11;

	/** Width of the segment box on the right. **/
	public var controlWidth:Float;

	var items:Array<String> = [];
	var itemKeys:Array<String> = null;
	var segmentFields:Array<TextField> = [];

	final labelField:TextField;
	var pillX:Float = -1;
	var pillAnim:Bool = false;
	var pillTween:UITween = null;

	/**
		@param label the row text on the left (empty = the box spans the whole row)
		@param width layout width (the segment box sits at the right edge)
		@param items the segment labels
		@param onSelect fired with the new index when the user picks a segment
	**/
	public function new(label:String, width:Float, items:Array<String>, ?onSelect:Int->Void) {
		super(true, true);
		this.label = label;
		this.onSelect = onSelect;
		controlWidth = UITheme.px(160);
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
		setItems(items);
		resize(width, UITheme.px(#if mobile 30 #else 24 #end));
		render();
	}

	/**
		Switches the row label to a localized string.
		@param key the translation key
		@param fallback the source-language text
	**/
	public function localize(key:String, fallback:String):Void {
		this.fallback = fallback;
		this.key = key;
	}

	/**
		Replaces the segments (the selection clamps to 0 when out of range).
		@param items the segment labels (also the localization fallbacks when `keys` is set)
		@param keys optional per-segment translation keys resolved through `UILocale`
	**/
	public function setItems(items:Array<String>, ?keys:Array<String>):Void {
		this.items = items;
		this.itemKeys = keys;
		var i:Int = segmentFields.length;
		while (--i >= 0)
			removeChild(segmentFields[i]);
		segmentFields.resize(0);
		i = 0;
		while (i < items.length) {
			var field:TextField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2, TextFormatAlign.CENTER);
			field.autoSize = openfl.text.TextFieldAutoSize.NONE;
			addChild(field);
			segmentFields.push(field);
			i++;
		}
		if (selectedIndex >= items.length)
			selectedIndex = 0;
		pillX = -1;
		invalidate();
	}

	/**
		Programmatically selects a segment without firing `onSelect` (the pill snaps).
		@param index the segment to select (ignored when out of range)
	**/
	public function select(index:Int):Void {
		if (index < 0 || index >= items.length || index == selectedIndex)
			return;
		selectedIndex = index;
		killTween();
		pillAnim = false;
		pillX = -1;
		invalidate();
	}

	override function onPress(localX:Float, localY:Float):Void {
		var count:Int = items.length;
		var bx:Float = boxX();
		if (count == 0 || localX < bx)
			return;
		var pad:Float = UITheme.px(2);
		var idx:Int = Std.int((localX - bx - pad) / ((controlWidth - pad * 2) / count));
		if (idx < 0)
			idx = 0;
		if (idx >= count)
			idx = count - 1;
		pick(idx);
	}

	function pick(idx:Int):Void {
		if (idx == selectedIndex)
			return;
		var pad:Float = UITheme.px(2);
		var segW:Float = (controlWidth - pad * 2) / items.length;
		var from:Float = (pillX < 0) ? boxX() + pad + selectedIndex * segW : pillX;
		selectedIndex = idx;
		killTween();
		pillAnim = true;
		pillTween = UITween.to(applyPill, from, boxX() + pad + idx * segW, 150, OUT_QUAD, endPill);
		invalidate();
		if (onSelect != null)
			onSelect(idx);
	}

	function applyPill(value:Float):Void {
		pillX = value;
		invalidate();
	}

	function endPill():Void {
		pillAnim = false;
		pillTween = null;
	}

	function killTween():Void {
		if (pillTween != null) {
			pillTween.cancel();
			pillTween = null;
		}
	}

	inline function boxX():Float {
		return (label != "" || key != null) ? w - controlWidth : 0;
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var count:Int = items.length;
		var bx:Float = boxX();
		var bw:Float = (label != "" || key != null) ? controlWidth : w;
		var radius:Float = UITheme.px(6);
		var pad:Float = UITheme.px(2);

		graphics.beginFill(UIColor.rgb(UITheme.panel2));
		graphics.drawRoundRect(bx, 1, bw, h - 2, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(UITheme.border));
		graphics.drawRoundRect(bx + 0.5, 1.5, bw - 1, h - 3, radius, radius);
		graphics.lineStyle();

		if (count > 0) {
			var segW:Float = (bw - pad * 2) / count;
			if (!pillAnim)
				pillX = bx + pad + selectedIndex * segW;
			graphics.beginFill(UIColor.rgb(UITheme.accentDark));
			graphics.drawRoundRect(pillX, 1 + pad, segW, h - 2 - pad * 2, radius, radius);
			graphics.endFill();

			var i:Int = 0;
			while (i < count) {
				var field:TextField = segmentFields[i];
				var active:Bool = (i == selectedIndex);
				UIFonts.restyle(field, UITheme.fs(fontSize), active ? UITheme.text : UITheme.text2, TextFormatAlign.CENTER);
				var resolved:String = (itemKeys != null && itemKeys[i] != null) ? UILocale.t(itemKeys[i], items[i]) : items[i];
				if (field.text != resolved)
					field.text = resolved;
				field.width = segW;
				field.height = field.textHeight + 4;
				field.x = bx + pad + i * segW;
				field.y = (h - field.height) / 2;
				i++;
			}
		}

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.visible = resolved != "";
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;
	}

	override public function dispose():Void {
		killTween();
		super.dispose();
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
