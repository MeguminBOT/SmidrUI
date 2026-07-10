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
import smidr.UIGlyphs;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;
import smidr.input.UIPointer;
import smidr.types.UIGlyph;

/**
	A virtualized icon/tile grid: fixed-size tiles that reflow into as many columns as the width
	allows, scrolled vertically. Like `UIList` only the on-screen tiles (+ two rows) exist as
	display objects and are recycled by slot mapping, so a grid of any size is cheap.

	Data is provider-driven (`setProvider` / `setItems`); the default tile draws an optional glyph
	over a centered label. Custom tiles subclass `UITile` and override `bind()`, supplied through
	`tileFactory`. Input mirrors `UIList`: wheel + thumb drag everywhere, touch drag with fling on
	mobile, arrow-key navigation, Enter/double-click to activate.
**/
class UITileGrid extends UIComponent implements IUIFocusable {
	/** The selected tile index, or -1. **/
	public var selectedIndex(default, null):Int = -1;

	/** Fired when the selection changes. **/
	public var onSelect:Int->Void = null;

	/** Fired on double click / Enter. **/
	public var onActivate:Int->Void = null;

	/** Total data entries. **/
	public var itemCount(default, null):Int = 0;

	/** Current scroll offset in pixels. **/
	public var scrollY(default, null):Float = 0;

	/** Pixels per wheel notch. **/
	public var wheelStep:Float = 48;

	/** Drag-anywhere scrolling with fling momentum (default on for mobile). **/
	public var touchScroll:Bool = #if mobile true #else false #end;

	/** Base (unscaled) tile width. **/
	public var tileWidthBase:Float = 92;

	/** Base (unscaled) tile height. **/
	public var tileHeightBase:Float = 84;

	/** Base (unscaled) gap between tiles. **/
	public var gapBase:Float = 10;

	/** Base (unscaled) padding around the grid. **/
	public var padBase:Float = 12;

	/** Creates one pooled tile; `null` uses the default glyph+label `UITile`. **/
	public var tileFactory:UITileGrid->UITile = null;

	static inline var MODE_NONE:Int = 0;
	static inline var MODE_THUMB:Int = 1;
	static inline var MODE_TOUCH:Int = 2;

	var labelProvider:Int->String = null;
	var glyphProvider:Int->UIGlyph = null;
	var tintProvider:Int->Int = null;

	var viewport:Sprite;
	var tiles:Array<UITile> = [];
	var thumb:Shape;
	var clipRect:Rectangle;

	var columns:Int = 1;
	var poolRows:Int = 0;
	var tileW:Float = 1;
	var tileH:Float = 1;
	var gap:Float = 0;
	var pad:Float = 0;
	var rowPitch:Float = 1;
	var contentHeight:Float = 0;

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
		@param width layout width
		@param height visible viewport height
	**/
	public function new(width:Float, height:Float) {
		super(false, true);
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
		Sets the data source (tiles resolved lazily).
		@param count the total number of entries
		@param label resolves a tile's label for an index
		@param glyph optional glyph id for an index (`null` for none)
		@param tint optional glyph colour for an index (`null` uses the theme accent)
	**/
	public function setProvider(count:Int, label:Int->String, ?glyph:Int->UIGlyph, ?tint:Int->Int):Void {
		itemCount = (count > 0) ? count : 0;
		labelProvider = label;
		glyphProvider = glyph;
		tintProvider = tint;
		if (selectedIndex >= itemCount)
			selectedIndex = -1;
		var i:Int = tiles.length;
		while (--i >= 0)
			tiles[i].__index = -1;
		invalidate();
	}

	/**
		Convenience data source from an array of labels (see `setProvider`).
		@param items the tile labels
	**/
	public inline function setItems(items:Array<String>):Void {
		setProvider(items.length, function(i:Int):String return items[i]);
	}

	/** The label for an index (used by the default tile). **/
	public inline function labelOf(index:Int):String {
		return (labelProvider != null) ? labelProvider(index) : "";
	}

	/** The glyph for an index, or `-1` for none (used by the default tile). **/
	public inline function glyphOf(index:Int):UIGlyph {
		return (glyphProvider != null) ? glyphProvider(index) : (-1 : UIGlyph);
	}

	/** The glyph tint for an index, or the theme accent (used by the default tile). **/
	public inline function tintOf(index:Int):Int {
		return (tintProvider != null) ? tintProvider(index) : UITheme.accent;
	}

	/** Rebinds every visible tile in place (after mutating data without changing the count). **/
	public function refresh():Void {
		var i:Int = tiles.length;
		while (--i >= 0) {
			var tile:UITile = tiles[i];
			if (tile.__index >= 0) {
				tile.bind(tile.__index);
				tile.invalidate();
			}
		}
	}

	/**
		Selects an index without firing `onSelect`.
		@param index the entry to select, or -1 to clear
		@param reveal `true` also scrolls the tile into view
	**/
	public function select(index:Int, reveal:Bool = false):Void {
		if (index < -1 || index >= itemCount || index == selectedIndex)
			return;
		var old:Int = selectedIndex;
		selectedIndex = index;
		invalidateTileAt(old);
		invalidateTileAt(index);
		if (reveal && index >= 0)
			scrollTo(index);
	}

	/**
		Scrolls the minimum distance to bring an index's row into view.
		@param index the entry to reveal
	**/
	public function scrollTo(index:Int):Void {
		if (index < 0 || index >= itemCount)
			return;
		var row:Int = Std.int(index / columns);
		var top:Float = pad + row * rowPitch;
		if (top < scrollY)
			setScroll(top - pad);
		else if (top + tileH > scrollY + h)
			setScroll(top + tileH - h + pad);
	}

	/** The furthest `scrollY` can go. **/
	public var maxScroll(get, never):Float;

	inline function get_maxScroll():Float {
		var m:Float = contentHeight - h;
		return (m > 0) ? m : 0;
	}

	/**
		Scrolls to an absolute offset (clamped) and rebinds the visible window.
		@param value the target offset in pixels
	**/
	public function setScroll(value:Float):Void {
		var m:Float = maxScroll;
		if (value < 0)
			value = 0;
		if (value > m)
			value = m;
		scrollY = value;
		clipRect.setTo(0, scrollY, w, h);
		viewport.scrollRect = clipRect;
		updateTiles();
		positionThumb();
	}

	function computeGeometry():Void {
		tileW = UITheme.px(tileWidthBase);
		tileH = UITheme.px(tileHeightBase);
		gap = UITheme.px(gapBase);
		pad = UITheme.px(padBase);
		rowPitch = tileH + gap;
		var usable:Float = w - pad * 2 + gap;
		columns = Std.int(usable / (tileW + gap));
		if (columns < 1)
			columns = 1;
		var rowCount:Int = (itemCount > 0) ? Math.ceil(itemCount / columns) : 0;
		contentHeight = (rowCount > 0) ? pad * 2 + rowCount * tileH + (rowCount - 1) * gap : 0;
	}

	function updateTiles():Void {
		var n:Int = tiles.length;
		if (n == 0)
			return;
		var firstRow:Int = Std.int((scrollY - pad) / rowPitch);
		if (firstRow < 0)
			firstRow = 0;
		var first:Int = firstRow * columns;
		var i:Int = first;
		var end:Int = first + n;
		while (i < end) {
			var tile:UITile = tiles[i % n];
			if (i < itemCount) {
				if (tile.__index != i) {
					tile.__index = i;
					var row:Int = Std.int(i / columns);
					var col:Int = i - row * columns;
					tile.x = pad + col * (tileW + gap);
					tile.y = pad + row * rowPitch;
					tile.resize(tileW, tileH);
					tile.bind(i);
					tile.invalidate();
				}
				tile.visible = true;
			} else {
				tile.__index = -1;
				tile.visible = false;
			}
			i++;
		}
	}

	function invalidateTileAt(index:Int):Void {
		if (index < 0 || tiles.length == 0)
			return;
		var tile:UITile = tiles[index % tiles.length];
		if (tile.__index == index)
			tile.invalidate();
	}

	function buildPool(need:Int):Void {
		var i:Int = tiles.length;
		while (--i >= 0)
			tiles[i].dispose();
		tiles.resize(0);
		i = 0;
		while (i < need) {
			var tile:UITile = (tileFactory != null) ? tileFactory(this) : new UITile(this);
			tile.visible = false;
			viewport.addChild(tile);
			tiles.push(tile);
			i++;
		}
	}

	override public function render():Void {
		computeGeometry();
		poolRows = Math.ceil(h / rowPitch) + 2;
		var need:Int = poolRows * columns;
		if (need != tiles.length)
			buildPool(need);
		else {
			var i:Int = tiles.length;
			while (--i >= 0)
				tiles[i].__index = -1;
		}
		setScroll(scrollY);

		var g = graphics;
		g.clear();
		g.beginFill(UIColor.rgb(UITheme.panel));
		g.drawRect(0, 0, w, h);
		g.endFill();
		drawThumb();
	}

	function drawThumb():Void {
		var g = thumb.graphics;
		g.clear();
		var m:Float = maxScroll;
		thumb.visible = (m > 0);
		if (m <= 0)
			return;
		var barW:Float = UITheme.px(4);
		var trackH:Float = h - 4;
		var thumbH:Float = trackH * (h / contentHeight);
		if (thumbH < 24)
			thumbH = 24;
		g.beginFill(UIColor.rgb(UITheme.border2));
		g.drawRoundRect(0, 0, barW, thumbH, barW, barW);
		g.endFill();
		positionThumb();
	}

	function positionThumb():Void {
		var m:Float = maxScroll;
		if (m <= 0)
			return;
		var trackH:Float = h - 4;
		var thumbH:Float = trackH * (h / contentHeight);
		if (thumbH < 24)
			thumbH = 24;
		thumb.x = w - UITheme.px(4) - 2;
		thumb.y = 2 + (trackH - thumbH) * (scrollY / m);
	}

	@:allow(smidr.widgets.UITile)
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
			invalidateTileAt(old);
			invalidateTileAt(index);
			if (onSelect != null)
				onSelect(index);
		}
	}

	function moveSelection(delta:Int):Void {
		var next:Int = (selectedIndex < 0) ? (delta > 0 ? 0 : itemCount - 1) : selectedIndex + delta;
		if (next < 0 || next >= itemCount)
			return;
		var old:Int = selectedIndex;
		selectedIndex = next;
		invalidateTileAt(old);
		invalidateTileAt(next);
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
			case 37:
				moveSelection(-1);
				return true;
			case 39:
				moveSelection(1);
				return true;
			case 38:
				moveSelection(-columns);
				return true;
			case 40:
				moveSelection(columns);
				return true;
			case 13:
				if (selectedIndex >= 0 && onActivate != null) {
					onActivate(selectedIndex);
					return true;
				}
		}
		return false;
	}

	function __onWheel(e:MouseEvent):Void {
		if (maxScroll <= 0)
			return;
		setScroll(scrollY - e.delta * wheelStep);
		e.stopPropagation();
	}

	function __onDown(e:MouseEvent):Void {
		UIFocus.set(this);
		stopFling();
		if (maxScroll <= 0)
			return;
		if (mouseX >= w - UITheme.px(4) - 4) {
			mode = MODE_THUMB;
			dragStartStageY = e.stageY;
			dragStartScroll = scrollY;
			beginCapture();
			e.stopPropagation();
			return;
		}
		if (touchScroll) {
			dragPending = true;
			dragStartStageY = e.stageY;
			dragStartScroll = scrollY;
			lastPointerY = e.stageY;
			lastPointerTime = Lib.getTimer();
			velocity = 0;
		}
	}

	function __onMove(e:MouseEvent):Void {
		if (!dragPending || mode != MODE_NONE)
			return;
		if (Math.abs(e.stageY - dragStartStageY) < UITheme.px(8) * scaleFactorY())
			return;
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
			var thumbH:Float = trackH * (h / contentHeight);
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
		var i:Int = tiles.length;
		while (--i >= 0)
			tiles[i].dispose();
		tiles.resize(0);
		super.dispose();
	}
}

/**
	One recyclable tile. The default draws an optional glyph over a centered label; subclass and
	override `bind()`/`render()` for custom content, supplying instances through
	`UITileGrid.tileFactory`. Never construct tiles yourself outside a factory.
**/
class UITile extends UIComponent {
	/** The bound data index (-1 while pooled/hidden). **/
	public var index(get, never):Int;

	@:allow(smidr.widgets.UITileGrid)
	var __index:Int = -1;

	final owner:UITileGrid;
	var labelField:TextField = null;

	inline function get_index():Int {
		return __index;
	}

	/**
		@param owner the grid this tile belongs to
	**/
	public function new(owner:UITileGrid) {
		super(true, true);
		this.owner = owner;
	}

	/**
		Fills the tile's content for a data index (called on recycle; keep it allocation-light).
		@param index the data index to display
	**/
	public function bind(index:Int):Void {
		if (labelField == null) {
			labelField = UIFonts.make(UITheme.fs(11), UITheme.text2);
			addChild(labelField);
		}
		var s:String = owner.labelOf(index);
		if (labelField.text != s)
			labelField.text = s;
	}

	override function click():Void {
		if (__index >= 0)
			owner.pick(__index);
		super.click();
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var selected:Bool = (__index >= 0 && __index == owner.selectedIndex);
		var radius:Float = UITheme.px(8);
		g.beginFill(UIColor.rgb(selected ? UITheme.panel3 : UITheme.panel2));
		g.drawRoundRect(0, 0, w, h, radius, radius);
		g.endFill();
		if (selected) {
			g.lineStyle(UITheme.px(1.5), UIColor.rgb(UITheme.accent));
			g.drawRoundRect(0.75, 0.75, w - 1.5, h - 1.5, radius, radius);
			g.lineStyle();
		} else if (hovered) {
			g.beginFill(UIColor.rgb(UITheme.panel3), 0.4);
			g.drawRoundRect(0, 0, w, h, radius, radius);
			g.endFill();
		}

		var glyph:UIGlyph = owner.glyphOf(__index);
		var labelTop:Float = h - UITheme.px(22);
		if ((glyph : Int) != -1) {
			var glyphSize:Float = UITheme.px(30);
			UIGlyphs.draw(g, glyph, (w - glyphSize) / 2, (labelTop - glyphSize) / 2, glyphSize, UIColor.rgb(owner.tintOf(__index)));
		}

		if (labelField != null) {
			UIFonts.restyle(labelField, UITheme.fs(11), selected ? UITheme.text : UITheme.text2);
			labelField.x = (w - labelField.width) / 2;
			labelField.y = labelTop + (UITheme.px(22) - labelField.height) / 2;
		}
	}
}
