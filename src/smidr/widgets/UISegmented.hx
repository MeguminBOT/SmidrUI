package smidr.widgets;

import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.UITween;

/**
	An exclusive-choice segmented control (radio group): label left, equal-width segments in a
	box on the right. Exactly one segment is selected; picking another slides the accent pill
	over and fires `onChange(index)`. Taller by default on mobile for touch.
**/
final class UISegmented extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var selectedIndex(default, null):Int = 0;
	public var onChange:Int->Void = null;
	public var fontSize(default, set):Int = 11;

	/** Width of the segment box on the right. **/
	public var boxWidth:Float;

	var items:Array<String> = [];
	var itemKeys:Array<String> = null;
	var tfs:Array<TextField> = [];

	final tf:TextField;
	var pillX:Float = -1;
	var pillAnim:Bool = false;
	var pillTween:UITween = null;

	/**
		@param label the row text on the left (empty = the box spans the whole row)
		@param width layout width (the segment box sits at the right edge)
		@param items the segment labels
		@param onChange fired with the new index when the user picks a segment
	**/
	public function new(label:String, width:Float, items:Array<String>, ?onChange:Int->Void) {
		super(true, true);
		this.label = label;
		this.onChange = onChange;
		boxWidth = UITheme.px(160);
		tf = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(tf);
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
		var i:Int = tfs.length;
		while (--i >= 0)
			removeChild(tfs[i]);
		tfs.resize(0);
		i = 0;
		while (i < items.length) {
			var t:TextField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2, TextFormatAlign.CENTER);
			t.autoSize = openfl.text.TextFieldAutoSize.NONE;
			addChild(t);
			tfs.push(t);
			i++;
		}
		if (selectedIndex >= items.length)
			selectedIndex = 0;
		pillX = -1;
		invalidate();
	}

	/**
		Programmatically selects a segment without firing `onChange` (the pill snaps).
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
		var n:Int = items.length;
		var bx:Float = boxX();
		if (n == 0 || localX < bx)
			return;
		var pad:Float = UITheme.px(2);
		var idx:Int = Std.int((localX - bx - pad) / ((boxWidth - pad * 2) / n));
		if (idx < 0)
			idx = 0;
		if (idx >= n)
			idx = n - 1;
		pick(idx);
	}

	function pick(idx:Int):Void {
		if (idx == selectedIndex)
			return;
		var pad:Float = UITheme.px(2);
		var segW:Float = (boxWidth - pad * 2) / items.length;
		var from:Float = (pillX < 0) ? boxX() + pad + selectedIndex * segW : pillX;
		selectedIndex = idx;
		killTween();
		pillAnim = true;
		pillTween = UITween.to(applyPill, from, boxX() + pad + idx * segW, 150, UITween.OUT_QUAD, endPill);
		invalidate();
		if (onChange != null)
			onChange(idx);
	}

	function applyPill(v:Float):Void {
		pillX = v;
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
		return (label != "" || key != null) ? w - boxWidth : 0;
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var n:Int = items.length;
		var bx:Float = boxX();
		var bw:Float = (label != "" || key != null) ? boxWidth : w;
		var r:Float = UITheme.px(6);
		var pad:Float = UITheme.px(2);

		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.drawRoundRect(bx, 1, bw, h - 2, r, r);
		g.endFill();
		g.lineStyle(1, UIColor.rgb(UITheme.border));
		g.drawRoundRect(bx + 0.5, 1.5, bw - 1, h - 3, r, r);
		g.lineStyle();

		if (n > 0) {
			var segW:Float = (bw - pad * 2) / n;
			if (!pillAnim)
				pillX = bx + pad + selectedIndex * segW;
			g.beginFill(UIColor.rgb(UITheme.accentDark));
			g.drawRoundRect(pillX, 1 + pad, segW, h - 2 - pad * 2, r, r);
			g.endFill();

			var i:Int = 0;
			while (i < n) {
				var t:TextField = tfs[i];
				var active:Bool = (i == selectedIndex);
				UIFonts.restyle(t, UITheme.fs(fontSize), active ? UITheme.text : UITheme.text2, TextFormatAlign.CENTER);
				var resolved:String = (itemKeys != null && itemKeys[i] != null) ? UILocale.t(itemKeys[i], items[i]) : items[i];
				if (t.text != resolved)
					t.text = resolved;
				t.width = segW;
				t.height = t.textHeight + 4;
				t.x = bx + pad + i * segW;
				t.y = (h - t.height) / 2;
				i++;
			}
		}

		UIFonts.restyle(tf, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (tf.text != resolved)
			tf.text = resolved;
		tf.visible = resolved != "";
		tf.x = 0;
		tf.y = (h - tf.height) / 2;
	}

	override public function dispose():Void {
		killTween();
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
