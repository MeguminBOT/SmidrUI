package smidr.widgets;

import openfl.Lib;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;
import smidr.input.UIPointer;

/**
	A virtualized, selectable list. Only the visible rows (+2) exist as display objects; they
	are recycled by modulo slot mapping, so scrolling by one row rebinds exactly one row and a
	100k-entry list costs the same as a 20-entry one. Rows are fixed-height (the constraint
	that keeps the window math O(1)).

	Data is provider-driven: `setProvider(count, label)` for huge/lazy datasets or
	`setItems(array)` for convenience. Custom row content subclasses `UIListRow` and overrides
	`bind()`, supplied through `rowFactory`.

	Input: mouse wheel + scrollbar thumb drag everywhere; on mobile (`touchScroll`) dragging
	anywhere scrolls with fling momentum — a drag past the threshold steals the press so no
	row click fires. Clicking focuses the list; Up/Down move the selection, Enter fires
	`onActivate` (as does a double click).
**/
class UIList extends UIComponent implements IUIFocusable {
	/** The selected row index, or -1. **/
	public var selectedIndex(default, null):Int = -1;

	/** Fired when the selection changes (click or arrow keys). **/
	public var onSelect:Int->Void = null;

	/** Fired on double click / Enter on the selected row. **/
	public var onActivate:Int->Void = null;

	/** Total data entries. **/
	public var itemCount(default, null):Int = 0;

	/** Current scroll offset in pixels (0..maxScroll). **/
	public var scrollY(default, null):Float = 0;

	/** Pixels per wheel notch. **/
	public var wheelStep:Float = 40;

	/** Drag-anywhere scrolling with fling momentum (default on for mobile). **/
	public var touchScroll:Bool = #if mobile true #else false #end;

	/** Creates one pooled row; `null` uses the default single-label `UIListRow`. **/
	public var rowFactory:UIList->UIListRow = null;

	/** Base (unscaled) row height. **/
	public var rowHeightBase(default, null):Float;

	static inline var MODE_NONE:Int = 0;
	static inline var MODE_THUMB:Int = 1;
	static inline var MODE_TOUCH:Int = 2;

	var labelProvider:Int->String = null;
	var viewport:Sprite;
	var rows:Array<UIListRow> = [];
	var thumb:Shape;
	var rowHeight:Float = 1;
	var clipRect:Rectangle;

	var mode:Int = MODE_NONE;
	var dragPending:Bool = false;
	var dragStartStageY:Float = 0;
	var dragStartScroll:Float = 0;
	var lastPointerY:Float = 0;
	var lastPointerTime:Int = 0;
	var velocity:Float = 0;
	var flinging:Bool = false;

	var lastPickIndex:Int = -1;
	var lastPickTime:Int = 0;

	/**
		@param width layout width (the scrollbar lives inside it)
		@param height the visible viewport height
		@param rowHeight base (unscaled) row height; 0 picks the platform default
	**/
	public function new(width:Float, height:Float, rowHeight:Float = 0) {
		super(false, true);
		rowHeightBase = (rowHeight > 0) ? rowHeight : #if mobile 34 #else 24 #end;
		viewport = new Sprite();
		addChild(viewport);
		thumb = new Shape();
		addChild(thumb);
		clipRect = new Rectangle();
		addEventListener(MouseEvent.MOUSE_WHEEL, __onWheel);
		addEventListener(MouseEvent.MOUSE_DOWN, __onDown);
		addEventListener(MouseEvent.MOUSE_MOVE, __onMove);
		resize(width, height);
		render();
	}

	/**
		Sets the data source (row labels resolved lazily; nothing is built up front).
		Clamps the selection and scroll, then rebinds the visible window.
		@param count the total number of entries
		@param label resolves the display label for an index
	**/
	public function setProvider(count:Int, label:Int->String):Void {
		itemCount = (count > 0) ? count : 0;
		labelProvider = label;
		if (selectedIndex >= itemCount)
			selectedIndex = -1;
		var i:Int = rows.length;
		while (--i >= 0)
			rows[i].__index = -1;
		setScroll(scrollY);
		invalidate();
	}

	/**
		Convenience data source from an array (see `setProvider`).
		@param items the row labels
	**/
	public inline function setItems(items:Array<String>):Void {
		setProvider(items.length, function(i:Int):String return items[i]);
	}

	/**
		The display label for an index (used by the default row's `bind`).
		@param index the entry index
		@return the label ("" without a provider)
	**/
	public inline function labelOf(index:Int):String {
		return (labelProvider != null) ? labelProvider(index) : "";
	}

	/**
		Rebinds every visible row in place (call after mutating the underlying data
		without changing the count).
	**/
	public function refresh():Void {
		var i:Int = rows.length;
		while (--i >= 0) {
			var row:UIListRow = rows[i];
			if (row.__index >= 0) {
				row.bind(row.__index);
				row.invalidate();
			}
		}
	}

	/**
		Programmatically selects an index without firing `onSelect`.
		@param index the entry to select, or -1 to clear
		@param reveal `true` also scrolls the row into view
	**/
	public function select(index:Int, reveal:Bool = false):Void {
		if (index < -1 || index >= itemCount || index == selectedIndex)
			return;
		var old:Int = selectedIndex;
		selectedIndex = index;
		invalidateRowAt(old);
		invalidateRowAt(index);
		if (reveal && index >= 0)
			scrollTo(index);
	}

	/**
		Scrolls the minimum distance to bring an index fully into view.
		@param index the entry to reveal
	**/
	public function scrollTo(index:Int):Void {
		if (index < 0 || index >= itemCount)
			return;
		var top:Float = index * rowHeight;
		if (top < scrollY)
			setScroll(top);
		else if (top + rowHeight > scrollY + h)
			setScroll(top + rowHeight - h);
	}

	/** The furthest `scrollY` can go. **/
	public var maxScroll(get, never):Float;

	inline function get_maxScroll():Float {
		var max:Float = itemCount * rowHeight - h;
		return (max > 0) ? max : 0;
	}

	/**
		Scrolls to an absolute offset (clamped) and rebinds the visible window.
		@param value the target offset in pixels
	**/
	public function setScroll(value:Float):Void {
		var max:Float = maxScroll;
		if (value < 0)
			value = 0;
		if (value > max)
			value = max;
		scrollY = value;
		clipRect.setTo(0, scrollY, w, h);
		viewport.scrollRect = clipRect;
		updateRows();
		positionThumb();
	}

	function updateRows():Void {
		var count:Int = rows.length;
		if (count == 0)
			return;
		var first:Int = Std.int(scrollY / rowHeight);
		if (first < 0)
			first = 0;
		var i:Int = first;
		var end:Int = first + count;
		while (i < end) {
			var row:UIListRow = rows[i % count];
			if (i < itemCount) {
				if (row.__index != i) {
					row.__index = i;
					row.y = i * rowHeight;
					row.resize(w, rowHeight);
					row.bind(i);
					row.invalidate();
				}
				row.visible = true;
			} else {
				row.__index = -1;
				row.visible = false;
			}
			i++;
		}
	}

	function invalidateRowAt(index:Int):Void {
		if (index < 0 || rows.length == 0)
			return;
		var row:UIListRow = rows[index % rows.length];
		if (row.__index == index)
			row.invalidate();
	}

	function buildPool(need:Int):Void {
		var i:Int = rows.length;
		while (--i >= 0)
			rows[i].dispose();
		rows.resize(0);
		i = 0;
		while (i < need) {
			var row:UIListRow = (rowFactory != null) ? rowFactory(this) : new UIListRow(this);
			row.visible = false;
			viewport.addChild(row);
			rows.push(row);
			i++;
		}
	}

	override public function render():Void {
		rowHeight = UITheme.px(rowHeightBase);
		var need:Int = Math.ceil(h / rowHeight) + 2;
		if (need != rows.length)
			buildPool(need);
		else {
			var i:Int = rows.length;
			while (--i >= 0) {
				var row:UIListRow = rows[i];
				if (row.__index >= 0) {
					row.y = row.__index * rowHeight;
					row.resize(w, rowHeight);
				}
			}
		}
		setScroll(scrollY);

		graphics.clear();
		graphics.beginFill(UIColor.rgb(UITheme.panel));
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		drawThumb();
	}

	function drawThumb():Void {
		var thumbGraphics = thumb.graphics;
		thumbGraphics.clear();
		var max:Float = maxScroll;
		thumb.visible = (max > 0);
		if (max <= 0)
			return;
		var barW:Float = UITheme.px(4);
		var trackH:Float = h - 4;
		var thumbH:Float = trackH * (h / (itemCount * rowHeight));
		if (thumbH < 24)
			thumbH = 24;
		thumbGraphics.beginFill(UIColor.rgb(UITheme.border2));
		thumbGraphics.drawRoundRect(0, 0, barW, thumbH, barW, barW);
		thumbGraphics.endFill();
		positionThumb();
	}

	function positionThumb():Void {
		var max:Float = maxScroll;
		if (max <= 0)
			return;
		var trackH:Float = h - 4;
		var thumbH:Float = trackH * (h / (itemCount * rowHeight));
		if (thumbH < 24)
			thumbH = 24;
		thumb.x = w - UITheme.px(4) - 2;
		thumb.y = 2 + (trackH - thumbH) * (scrollY / max);
	}

	@:allow(smidr.widgets.UIListRow)
	function pick(index:Int):Void {
		var now:Int = Lib.getTimer();
		if (index == lastPickIndex && now - lastPickTime < 350) {
			lastPickTime = 0;
			if (onActivate != null)
				onActivate(index);
			return;
		}
		lastPickIndex = index;
		lastPickTime = now;
		if (index != selectedIndex) {
			var old:Int = selectedIndex;
			selectedIndex = index;
			invalidateRowAt(old);
			invalidateRowAt(index);
			if (onSelect != null)
				onSelect(index);
		}
	}

	function moveSelection(dir:Int):Void {
		var next:Int = (selectedIndex < 0) ? (dir > 0 ? 0 : itemCount - 1) : selectedIndex + dir;
		if (next < 0 || next >= itemCount)
			return;
		var old:Int = selectedIndex;
		selectedIndex = next;
		invalidateRowAt(old);
		invalidateRowAt(next);
		scrollTo(next);
		if (onSelect != null)
			onSelect(next);
	}

	public function capturesKeyboard():Bool {
		return false;
	}

	public function onFocusGained():Void {}

	public function onFocusLost():Void {}

	public function onKeyDown(keyCode:Int, charCode:Int, ctrl:Bool, shift:Bool, alt:Bool):Bool {
		switch (keyCode) {
			case 38:
				moveSelection(-1);
				return true;
			case 40:
				moveSelection(1);
				return true;
			case 13:
				if (selectedIndex >= 0 && onActivate != null) {
					onActivate(selectedIndex);
					return true;
				}
		}
		return false;
	}

	function __onWheel(event:MouseEvent):Void {
		if (maxScroll <= 0)
			return;
		setScroll(scrollY - event.delta * wheelStep);
		event.stopPropagation();
	}

	function __onDown(event:MouseEvent):Void {
		UIFocus.set(this);
		stopFling();
		if (maxScroll <= 0)
			return;
		if (mouseX >= w - UITheme.px(4) - 4) {
			mode = MODE_THUMB;
			dragStartStageY = event.stageY;
			dragStartScroll = scrollY;
			beginCapture();
			event.stopPropagation();
			return;
		}
		if (touchScroll) {
			dragPending = true;
			dragStartStageY = event.stageY;
			dragStartScroll = scrollY;
			lastPointerY = event.stageY;
			lastPointerTime = Lib.getTimer();
			velocity = 0;
		}
	}

	function __onMove(event:MouseEvent):Void {
		if (!dragPending || mode != MODE_NONE)
			return;
		if (Math.abs(event.stageY - dragStartStageY) < UITheme.px(8) * scaleFactorY())
			return;
		// steal the press: the row must neither stay pressed nor click on release
		var pt:UIComponent = UIPointer.pressTarget;
		if (pt != null)
			@:privateAccess pt.releasePress(false);
		@:privateAccess UIPointer.clearPress();
		mode = MODE_TOUCH;
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		var sf:Float = scaleFactorY();
		if (mode == MODE_THUMB) {
			var trackH:Float = h - 4;
			var thumbH:Float = trackH * (h / (itemCount * rowHeight));
			if (thumbH < 24)
				thumbH = 24;
			var usable:Float = trackH - thumbH;
			if (usable <= 0)
				return;
			setScroll(dragStartScroll + ((stageY - dragStartStageY) / sf) * (maxScroll / usable));
		} else if (mode == MODE_TOUCH) {
			var now:Int = Lib.getTimer();
			var dt:Float = now - lastPointerTime;
			if (dt > 0) {
				velocity = ((stageY - lastPointerY) / sf) / dt;
				lastPointerY = stageY;
				lastPointerTime = now;
			}
			setScroll(dragStartScroll - (stageY - dragStartStageY) / sf);
		}
	}

	override function onDragEnd():Void {
		var wasTouch:Bool = (mode == MODE_TOUCH);
		mode = MODE_NONE;
		dragPending = false;
		if (wasTouch && Math.abs(velocity) > 0.1 && maxScroll > 0) {
			flinging = true;
			UIRoot.addTicker(flingTick);
		}
	}

	function flingTick(dtMs:Float):Void {
		var next:Float = scrollY - velocity * dtMs;
		setScroll(next);
		velocity *= Math.exp(-dtMs * 0.004);
		if (Math.abs(velocity) < 0.02 || scrollY != next)
			stopFling();
	}

	function stopFling():Void {
		if (!flinging)
			return;
		flinging = false;
		velocity = 0;
		UIRoot.removeTicker(flingTick);
	}

	inline function scaleFactorY():Float {
		var root = UIRoot.current;
		return (root != null && root.scaleY > 0) ? root.scaleY : 1.0;
	}

	override public function dispose():Void {
		removeEventListener(MouseEvent.MOUSE_WHEEL, __onWheel);
		removeEventListener(MouseEvent.MOUSE_DOWN, __onDown);
		removeEventListener(MouseEvent.MOUSE_MOVE, __onMove);
		stopFling();
		UIFocus.clear(this);
		var i:Int = rows.length;
		while (--i >= 0)
			rows[i].dispose();
		rows.resize(0);
		super.dispose();
	}
}

/**
	One recyclable list row. The default implementation renders a single label via
	`UIList.labelOf`; subclass and override `bind()`/`render()` for custom content, supplying
	instances through `UIList.rowFactory`. Never construct rows yourself outside a factory —
	the list owns the pool.
**/
class UIListRow extends UIComponent {
	/** The bound data index (-1 while pooled/hidden). **/
	public var index(get, never):Int;

	@:allow(smidr.widgets.UIList)
	var __index:Int = -1;

	final owner:UIList;
	var labelField:TextField = null;

	inline function get_index():Int {
		return __index;
	}

	/**
		@param owner the list this row belongs to
	**/
	public function new(owner:UIList) {
		super(true, true);
		this.owner = owner;
	}

	/**
		Fills the row's content for a data index (called on recycle; keep it allocation-light).
		The default sets a single label from the list's provider.
		@param index the data index to display
	**/
	public function bind(index:Int):Void {
		if (labelField == null) {
			labelField = UIFonts.make(UITheme.fs(12), UITheme.text);
			addChild(labelField);
		}
		var text:String = owner.labelOf(index);
		if (labelField.text != text)
			labelField.text = text;
	}

	override function click():Void {
		if (__index >= 0)
			owner.pick(__index);
		super.click();
	}

	override public function render():Void {
		graphics.clear();
		var selected:Bool = (__index >= 0 && __index == owner.selectedIndex);
		if (selected) {
			graphics.beginFill(UIColor.rgb(UITheme.panel3));
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
			graphics.beginFill(UIColor.rgb(UITheme.accent));
			graphics.drawRect(0, UITheme.px(3), UITheme.px(2.5), h - UITheme.px(6));
			graphics.endFill();
		} else if (hovered) {
			graphics.beginFill(UIColor.rgb(UITheme.panel3), 0.5);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		} else {
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}
		if (labelField != null) {
			UIFonts.restyle(labelField, UITheme.fs(12), selected ? UITheme.text : UITheme.text2);
			labelField.x = UITheme.px(10);
			labelField.y = (h - labelField.height) / 2;
		}
	}
}
