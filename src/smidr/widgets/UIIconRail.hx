package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.types.UIEase;
import smidr.types.UIRailTabDef;

/**
	A vertical icon rail (Blender/VSCode-style activity bar): fixed-width column of tabs,
	one active at a time with an accent indicator. `onSelect(index)` fires on change.
**/
final class UIIconRail extends UIComponent {
	public var selectedIndex(default, null):Int = 0;
	public var onSelect:Int->Void = null;

	/** Per-tab cell height. **/
	public var cellH:Float;

	var tabs:Array<UIRailTabDef> = [];
	var labelFields:Array<TextField> = [];

	/**
		@param width the rail width
		@param height the rail height
		@param tabs the initial tab set
		@param onSelect fired with the new index when the active tab changes
	**/
	public function new(width:Float, height:Float, tabs:Array<UIRailTabDef>, ?onSelect:Int->Void) {
		super(true, true);
		this.onSelect = onSelect;
		cellH = UITheme.px(44);
		resize(width, height);
		setTabs(tabs);
	}

	/**
		Replaces the tab set (the selection clamps to 0 when out of range).
		@param tabs the new tabs
	**/
	public function setTabs(tabs:Array<UIRailTabDef>):Void {
		this.tabs = tabs;
		var i:Int = labelFields.length;
		while (--i >= 0)
			removeChild(labelFields[i]);
		labelFields.resize(0);
		i = 0;
		while (i < tabs.length) {
			var tf:TextField = UIFonts.make(UITheme.fs(9), UITheme.text3);
			tf.text = tabs[i].label;
			addChild(tf);
			labelFields.push(tf);
			i++;
		}
		if (selectedIndex >= tabs.length)
			selectedIndex = 0;
		invalidate();
	}

	var indicatorY:Float = -1;

	/**
		Programmatically activates a tab.
		@param index the tab to activate (fires `onSelect` when it changed)
	**/
	public function select(index:Int):Void {
		if (index < 0 || index >= tabs.length || index == selectedIndex)
			return;
		selectedIndex = index;
		var target:Float = UITheme.px(6) + index * (cellH + UITheme.px(2)) + UITheme.px(6);
		if (indicatorY < 0)
			indicatorY = target;
		else
			smidr.UITween.to(function(v:Float):Void {
				indicatorY = v;
				invalidate();
			}, indicatorY, target, 170, OUT_QUAD);
		invalidate();
		if (onSelect != null)
			onSelect(index);
	}

	override function onPress(localX:Float, localY:Float):Void {
		var pad:Float = UITheme.px(6);
		var idx:Int = Std.int((localY - pad) / (cellH + UITheme.px(2)));
		if (idx >= 0 && idx < tabs.length)
			select(idx);
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(UIColor.rgb(UITheme.panel2));
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(UITheme.border));
		graphics.drawRect(w - 1, 0, 1, h);
		graphics.endFill();

		var pad:Float = UITheme.px(6);
		var i:Int = 0;
		var count:Int = tabs.length;
		while (i < count) {
			var cy:Float = pad + i * (cellH + UITheme.px(2));
			var active:Bool = (i == selectedIndex);
			if (active) {
				graphics.beginFill(UIColor.rgb(UITheme.panel3));
				graphics.drawRoundRect(UITheme.px(3), cy, w - UITheme.px(6), cellH, UITheme.px(7), UITheme.px(7));
				graphics.endFill();
				// the accent indicator slides between tabs
				if (indicatorY < 0)
					indicatorY = cy + UITheme.px(6);
				graphics.beginFill(UIColor.rgb(UITheme.accent));
				graphics.drawRoundRect(1, indicatorY, UITheme.px(3), cellH - UITheme.px(12), 3, 3);
				graphics.endFill();
			}
			// glyph placeholder ring (icon assets can replace this later)
			graphics.lineStyle(2, UIColor.rgb(active ? UITheme.text : UITheme.text3));
			graphics.drawCircle(w / 2, cy + cellH * 0.34, UITheme.px(7));
			graphics.lineStyle();

			var tf:TextField = labelFields[i];
			UIFonts.restyle(tf, UITheme.fs(9), active ? UITheme.text : UITheme.text3);
			tf.x = (w - tf.width) / 2;
			tf.y = cy + cellH - tf.height - UITheme.px(3);
			i++;
		}
	}
}
