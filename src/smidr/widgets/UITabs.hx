package smidr.widgets;

import openfl.geom.Point;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.UITween;
import smidr.types.UIEase;

/** One `UITabs` tab definition. **/
typedef UITabDef = {
	var label:String;
	@:optional var key:String;
	@:optional var fallback:String;
}

/**
	A horizontal tab strip (the horizontal counterpart to `UIIconRail`): content-width cells,
	one active at a time with an accent underline that slides between tabs. The owner switches
	panel content from `onSelect(index)`. Taller by default on mobile for touch.
**/
final class UITabs extends UIComponent {
	public var selectedIndex(default, null):Int = 0;
	public var onSelect:Int->Void = null;
	public var fontSize(default, set):Int = 12;

	var tabs:Array<UITabDef> = [];
	var tabFields:Array<TextField> = [];
	var cellX:Array<Float> = [];
	var cellW:Array<Float> = [];

	var indicatorX:Float = 0;
	var indicatorWidth:Float = 0;
	var indicatorAnimating:Bool = false;
	var indicatorTween:UITween = null;

	/**
		@param width layout width
		@param tabs the initial tab set
		@param onSelect fired with the new index when the active tab changes
	**/
	public function new(width:Float, tabs:Array<UITabDef>, ?onSelect:Int->Void) {
		super(true, true);
		this.onSelect = onSelect;
		resize(width, UITheme.px(#if mobile 38 #else 30 #end));
		setTabs(tabs);
	}

	/**
		Replaces the tab set (the selection clamps to 0 when out of range).
		@param tabs the new tabs
	**/
	public function setTabs(tabs:Array<UITabDef>):Void {
		this.tabs = tabs;
		var i:Int = tabFields.length;
		while (--i >= 0)
			removeChild(tabFields[i]);
		tabFields.resize(0);
		i = 0;
		while (i < tabs.length) {
			var t:TextField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
			addChild(t);
			tabFields.push(t);
			i++;
		}
		if (selectedIndex >= tabs.length)
			selectedIndex = 0;
		killTween();
		indicatorAnimating = false;
		invalidate();
	}

	/**
		Activates a tab and fires `onSelect` when it changed (the underline slides over).
		@param index the tab to activate (ignored when out of range or unchanged)
	**/
	public function select(index:Int):Void {
		if (index < 0 || index >= tabs.length || index == selectedIndex)
			return;
		selectedIndex = index;
		if (index < cellX.length) {
			var fx:Float = indicatorX;
			var fw:Float = indicatorWidth;
			var toX:Float = cellX[index];
			var toW:Float = cellW[index];
			killTween();
			indicatorAnimating = true;
			indicatorTween = UITween.to(function(p:Float):Void {
				indicatorX = fx + (toX - fx) * p;
				indicatorWidth = fw + (toW - fw) * p;
				invalidate();
			}, 0, 1, 170, OUT_QUAD, endInd);
		}
		invalidate();
		if (onSelect != null)
			onSelect(index);
	}

	function endInd():Void {
		indicatorAnimating = false;
		indicatorTween = null;
	}

	function killTween():Void {
		if (indicatorTween != null) {
			indicatorTween.cancel();
			indicatorTween = null;
		}
	}

	override function onPress(localX:Float, localY:Float):Void {
		var i:Int = 0;
		var n:Int = cellX.length;
		while (i < n) {
			if (localX >= cellX[i] && localX < cellX[i] + cellW[i]) {
				select(i);
				return;
			}
			i++;
		}
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.drawRect(0, 0, w, h);
		g.endFill();
		g.beginFill(UIColor.rgb(UITheme.border));
		g.drawRect(0, h - 1, w, 1);
		g.endFill();

		cellX.resize(0);
		cellW.resize(0);
		var pad:Float = UITheme.px(#if mobile 16 #else 12 #end);
		var x:Float = UITheme.px(6);
		var i:Int = 0;
		var n:Int = tabs.length;
		while (i < n) {
			var t:TextField = tabFields[i];
			var d:UITabDef = tabs[i];
			var active:Bool = (i == selectedIndex);
			UIFonts.restyle(t, UITheme.fs(fontSize), active ? UITheme.text : UITheme.text2);
			var resolved:String = (d.key != null) ? UILocale.t(d.key, d.fallback != null ? d.fallback : d.label) : d.label;
			if (t.text != resolved)
				t.text = resolved;
			var cw:Float = t.width + pad * 2;
			cellX.push(x);
			cellW.push(cw);
			if (active) {
				g.beginFill(UIColor.rgb(UITheme.panel3));
				g.drawRoundRect(x, UITheme.px(4), cw, h - UITheme.px(8), UITheme.px(6), UITheme.px(6));
				g.endFill();
			}
			t.x = x + pad;
			t.y = (h - t.height) / 2 - 1;
			x += cw + UITheme.px(2);
			i++;
		}

		if (n > 0) {
			if (!indicatorAnimating) {
				indicatorX = cellX[selectedIndex];
				indicatorWidth = cellW[selectedIndex];
			}
			g.beginFill(UIColor.rgb(UITheme.accent));
			g.drawRoundRect(indicatorX + UITheme.px(4), h - UITheme.px(3), indicatorWidth - UITheme.px(8), UITheme.px(2.5), 3, 3);
			g.endFill();
		}
	}

	override public function dispose():Void {
		killTween();
		super.dispose();
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
