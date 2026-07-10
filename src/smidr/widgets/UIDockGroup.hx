package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;

/**
	A leaf of a `UIDockHost`: a tabbed group of `UIDockPanel`s, one visible at a time. Clicking a
	tab activates its panel; dragging a tab hands off to the host to re-dock (split, tab into
	another group, or move). The host sizes and positions the group; do not use it standalone.
**/
final class UIDockGroup extends UIComponent {
	/** Base (unscaled) tab-strip height. **/
	public var tabBarHeight:Float = 26;

	/** The visible panel index, or -1 when empty. **/
	public var activeIndex(default, null):Int = -1;

	final host:UIDockHost;
	final panels:Array<UIDockPanel> = [];
	final tabFields:Array<TextField> = [];
	final tabX:Array<Float> = [];
	final tabW:Array<Float> = [];

	var dragTabIndex:Int = -1;
	var dragging:Bool = false;
	var dragStartX:Float = 0;
	var dragStartY:Float = 0;

	/**
		@param host the dock host that lays this group out
	**/
	public function new(host:UIDockHost) {
		super(true, true);
		this.host = host;
	}

	/** Number of panels in the group. **/
	public var count(get, never):Int;

	inline function get_count():Int
		return panels.length;

	/** The panel at an index (no bounds check beyond the array). **/
	public inline function panelAt(index:Int):UIDockPanel
		return panels[index];

	inline function tabBarPx():Float
		return UITheme.px(tabBarHeight);

	/**
		Adds a panel to the group.
		@param panel the panel to host
		@param activate `true` makes it the visible tab
	**/
	public function addPanel(panel:UIDockPanel, activate:Bool = true):Void {
		panels.push(panel);
		addChild(panel);
		var field:TextField = UIFonts.make(UITheme.fs(12), UITheme.text2);
		addChild(field);
		tabFields.push(field);
		if (activate || activeIndex < 0)
			activeIndex = panels.length - 1;
		invalidate();
	}

	/**
		Removes a panel (does not dispose it — the host may re-dock it).
		@param panel the panel to remove
	**/
	public function removePanel(panel:UIDockPanel):Void {
		var index:Int = panels.indexOf(panel);
		if (index < 0)
			return;
		panels.splice(index, 1);
		if (panel.parent == this)
			removeChild(panel);
		var field:TextField = tabFields.splice(index, 1)[0];
		if (field.parent == this)
			removeChild(field);
		if (activeIndex >= panels.length)
			activeIndex = panels.length - 1;
		invalidate();
	}

	/**
		Makes a tab the visible panel.
		@param index the panel index
	**/
	public function setActive(index:Int):Void {
		if (index < 0 || index >= panels.length)
			return;
		activeIndex = index;
		invalidate();
	}

	/** Positions and sizes the group (called by the host during layout). **/
	@:allow(smidr.widgets.UIDockHost)
	function setBounds(nx:Float, ny:Float, nw:Float, nh:Float):Void {
		x = nx;
		y = ny;
		resize(nw, nh);
	}

	function tabAt(localX:Float):Int {
		var i:Int = 0;
		var n:Int = tabX.length;
		while (i < n) {
			if (localX >= tabX[i] && localX < tabX[i] + tabW[i])
				return i;
			i++;
		}
		return -1;
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (localY >= tabBarPx())
			return;
		var index:Int = tabAt(localX);
		if (index < 0)
			return;
		setActive(index);
		dragTabIndex = index;
		dragging = false;
		if (stage != null) {
			dragStartX = stage.mouseX;
			dragStartY = stage.mouseY;
		}
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (dragTabIndex < 0)
			return;
		if (!dragging) {
			var slop:Float = UITheme.px(8);
			if (Math.abs(stageX - dragStartX) > slop || Math.abs(stageY - dragStartY) > slop) {
				dragging = true;
				host.startPanelDrag(this, panels[dragTabIndex]);
			}
		}
		if (dragging)
			host.updatePanelDrag(stageX, stageY);
	}

	override function onDragEnd():Void {
		if (dragging)
			host.endPanelDrag();
		dragTabIndex = -1;
		dragging = false;
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var tabH:Float = tabBarPx();

		g.beginFill(UIColor.rgb(UITheme.panel));
		g.drawRect(0, tabH, w, h - tabH);
		g.endFill();
		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.drawRect(0, 0, w, tabH);
		g.endFill();

		var x:Float = UITheme.px(2);
		tabX.resize(0);
		tabW.resize(0);
		var i:Int = 0;
		var n:Int = panels.length;
		while (i < n) {
			var field:TextField = tabFields[i];
			var active:Bool = (i == activeIndex);
			UIFonts.restyle(field, UITheme.fs(12), active ? UITheme.text : UITheme.text2);
			var label:String = panels[i].title;
			if (field.text != label)
				field.text = label;
			var tw:Float = field.width + UITheme.px(22);
			if (active) {
				g.beginFill(UIColor.rgb(UITheme.panel3));
				g.drawRoundRect(x + 1, UITheme.px(3), tw - 2, tabH - UITheme.px(4), UITheme.px(5), UITheme.px(5));
				g.endFill();
				g.beginFill(UIColor.rgb(UITheme.accent));
				g.drawRect(x + 1, tabH - UITheme.px(2.5), tw - 2, UITheme.px(2.5));
				g.endFill();
			}
			field.x = x + UITheme.px(11);
			field.y = (tabH - field.height) / 2 - 1;
			tabX.push(x);
			tabW.push(tw);
			x += tw + UITheme.px(2);
			i++;
		}

		g.beginFill(UIColor.rgb(UITheme.border));
		g.drawRect(0, tabH - 1, w, 1);
		g.endFill();
		g.lineStyle(1, UIColor.rgb(UITheme.border));
		g.drawRect(0.5, 0.5, w - 1, h - 1);
		g.lineStyle();

		i = 0;
		while (i < n) {
			var panel:UIDockPanel = panels[i];
			var active:Bool = (i == activeIndex);
			panel.visible = active;
			if (active) {
				panel.x = 0;
				panel.y = tabH;
				panel.resize(w, h - tabH);
			}
			i++;
		}
	}

	override public function dispose():Void {
		var i:Int = panels.length;
		while (--i >= 0)
			panels[i].dispose();
		panels.resize(0);
		super.dispose();
	}
}
