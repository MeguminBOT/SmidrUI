package smidr.widgets;

import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UITheme;
import smidr.types.UICursor;

/**
	Two resizable panes with a draggable divider: side by side (`vertical = false`) or stacked
	(`vertical = true`). Add each pane's content to `first` / `second` (origin at the pane's
	top-left); the panes are clipped to their region, so overflow is hidden and only in-region
	content takes the pointer. Dragging the divider moves the split, honouring `minFirst` /
	`minSecond`.

	`position` is the first pane's size along the split axis, in UI pixels; `onResized` reports
	the two pane sizes after a drag. Non-interactive except for the divider — pane content keeps
	its own interactivity.
**/
final class UISplitter extends UIComponent {
	/** Add the first (left/top) pane's content here. **/
	public final first:Sprite;

	/** Add the second (right/bottom) pane's content here. **/
	public final second:Sprite;

	/** `true` stacks the panes (top/bottom, horizontal divider); `false` places them side by side. **/
	public var vertical(default, set):Bool;

	/** The first pane's size along the split axis, in UI pixels (clamped to the min sizes). **/
	public var position(default, set):Float = 0;

	/** Smallest the first pane may become. **/
	public var minFirst:Float = 48;

	/** Smallest the second pane may become. **/
	public var minSecond:Float = 48;

	/** Base (unscaled) divider thickness. **/
	public var dividerThickness:Float = 6;

	/** Fired after a divider drag, with the first and second pane sizes. **/
	public var onResized:(first:Float, second:Float) -> Void = null;

	final divider:UISplitterHandle;

	/**
		@param vertical `true` for stacked panes, `false` for side-by-side
		@param width layout width
		@param height layout height
		@param position optional initial first-pane size (defaults to half)
	**/
	public function new(vertical:Bool, width:Float, height:Float, ?position:Float) {
		super(false, false);
		@:bypassAccessor this.vertical = vertical;
		first = new Sprite();
		second = new Sprite();
		divider = new UISplitterHandle(this);
		addChild(first);
		addChild(second);
		addChild(divider);
		resize(width, height);
		@:bypassAccessor this.position = (position != null) ? position : mainExtent() / 2;
		render();
	}

	inline function mainExtent():Float
		return vertical ? h : w;

	function clampPosition(p:Float):Float {
		var t:Float = UITheme.px(dividerThickness);
		var max:Float = mainExtent() - t - minSecond;
		if (p > max)
			p = max;
		if (p < minFirst)
			p = minFirst;
		if (p < 0)
			p = 0;
		return p;
	}

	@:allow(smidr.widgets.UISplitterHandle)
	function dragTo(mainPos:Float):Void {
		var p:Float = clampPosition(mainPos);
		if (p == position)
			return;
		@:bypassAccessor position = p;
		layoutPanes();
		if (onResized != null) {
			var t:Float = UITheme.px(dividerThickness);
			onResized(position, mainExtent() - position - t);
		}
	}

	function layoutPanes():Void {
		var t:Float = UITheme.px(dividerThickness);
		if (vertical) {
			first.x = 0;
			first.y = 0;
			first.scrollRect = new Rectangle(0, 0, w, position);
			divider.x = 0;
			divider.y = position;
			divider.resize(w, t);
			second.x = 0;
			second.y = position + t;
			second.scrollRect = new Rectangle(0, 0, w, h - position - t);
		} else {
			first.x = 0;
			first.y = 0;
			first.scrollRect = new Rectangle(0, 0, position, h);
			divider.x = position;
			divider.y = 0;
			divider.resize(t, h);
			second.x = position + t;
			second.y = 0;
			second.scrollRect = new Rectangle(0, 0, w - position - t, h);
		}
	}

	override public function render():Void {
		@:bypassAccessor position = clampPosition(position);
		layoutPanes();
	}

	function set_vertical(v:Bool):Bool {
		vertical = v;
		if (divider != null)
			divider.syncCursor();
		invalidate();
		return v;
	}

	function set_position(v:Float):Float {
		position = clampPosition(v);
		invalidate();
		return position;
	}
}

/** The draggable divider between a `UISplitter`'s two panes. **/
private final class UISplitterHandle extends UIComponent {
	final owner:UISplitter;

	public function new(owner:UISplitter) {
		super(true, true);
		this.owner = owner;
		syncCursor();
	}

	public function syncCursor():Void {
		hoverCursor = owner.vertical ? UICursor.RESIZE_V : UICursor.RESIZE_H;
	}

	override function onPress(localX:Float, localY:Float):Void {
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (owner.parent == null)
			return;
		var p:Point = owner.globalToLocal(new Point(stageX, stageY));
		var t:Float = UITheme.px(owner.dividerThickness);
		owner.dragTo((owner.vertical ? p.y : p.x) - t / 2);
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();
		g.beginFill(UIColor.rgb(hovered ? UITheme.border2 : UITheme.border));
		if (owner.vertical)
			g.drawRect(0, h / 2 - 0.5, w, 1);
		else
			g.drawRect(w / 2 - 0.5, 0, 1, h);
		g.endFill();
		// three grip dots along the divider centre
		g.beginFill(UIColor.rgb(UITheme.border2));
		var dot:Float = UITheme.px(1.5);
		var spacing:Float = UITheme.px(5);
		var k:Int = -1;
		while (k <= 1) {
			if (owner.vertical)
				g.drawCircle(w / 2 + k * spacing, h / 2, dot);
			else
				g.drawCircle(w / 2, h / 2 + k * spacing, dot);
			k++;
		}
		g.endFill();
	}
}
