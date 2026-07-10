package smidr.widgets;

import openfl.display.DisplayObject;
import smidr.UIComponent;
import smidr.UITheme;
import smidr.types.UIAlign;

/**
	A flow-layout container: stacks its children in a row (`vertical = false`) or column
	(`vertical = true`), spaced by `gap` with `padding` around the group. `stretch` sizes each
	`UIComponent` child to fill the cross axis; otherwise `align` places them
	(`START`/`CENTER`/`END`). The main axis auto-grows to fit — a vertical stack keeps its given
	width and computes its height, a horizontal stack keeps its height and computes its width.

	`gap`/`padding` are base (unscaled) pixels, scaled by `UITheme.scale` like the rest of the
	library. Relayout happens on `render()`, so call `invalidate()` (or `relayout()`) after
	changing a child's size; a theme scale change relayouts automatically. Non-interactive and
	pointer-transparent — children keep their own interactivity.
**/
final class UIStack extends UIComponent {
	/** `true` stacks children top-to-bottom; `false` left-to-right. **/
	public var vertical(default, set):Bool;

	/** Base (unscaled) space between children. **/
	public var gap(default, set):Float = 8;

	/** Base (unscaled) inset around the group. **/
	public var padding(default, set):Float = 0;

	/** Size each `UIComponent` child to fill the cross axis. **/
	public var stretch(default, set):Bool = false;

	/** Cross-axis placement when not stretching. **/
	public var align(default, set):UIAlign = START;

	var items:Array<DisplayObject> = [];

	/**
		@param vertical `true` for a column, `false` for a row
		@param extent the cross-axis size (width for a column, height for a row)
		@param gap base spacing between children
		@param padding base inset around the group
	**/
	public function new(vertical:Bool, extent:Float, gap:Float = 8, padding:Float = 0) {
		super(false, false);
		@:bypassAccessor this.vertical = vertical;
		this.gap = gap;
		this.padding = padding;
		if (vertical)
			w = extent;
		else
			h = extent;
		render();
	}

	/**
		Appends a child and relayouts.
		@param child the display object to add
		@return this stack (for chaining)
	**/
	public function add(child:DisplayObject):UIStack {
		items.push(child);
		addChild(child);
		invalidate();
		return this;
	}

	/**
		Appends several children and relayouts.
		@param children the display objects to add
		@return this stack (for chaining)
	**/
	public function addAll(children:Array<DisplayObject>):UIStack {
		for (child in children) {
			items.push(child);
			addChild(child);
		}
		invalidate();
		return this;
	}

	/**
		Removes a child from the layout (does not dispose it).
		@param child the child to remove
	**/
	public function removeItem(child:DisplayObject):Void {
		if (items.remove(child) && child.parent == this)
			removeChild(child);
		invalidate();
	}

	/** Removes every child from the layout (does not dispose them). **/
	public function clear():Void {
		for (child in items)
			if (child.parent == this)
				removeChild(child);
		items.resize(0);
		invalidate();
	}

	/** Forces an immediate relayout (so `w`/`h` are valid now, not on the next frame). **/
	public inline function relayout():Void {
		render();
	}

	inline function widthOf(child:DisplayObject):Float
		return (child is UIComponent) ? (cast child : UIComponent).w : child.width;

	inline function heightOf(child:DisplayObject):Float
		return (child is UIComponent) ? (cast child : UIComponent).h : child.height;

	override public function render():Void {
		var pad:Float = UITheme.px(padding);
		var g:Float = UITheme.px(gap);
		var crossExtent:Float = (vertical ? w : h) - pad * 2;
		var pos:Float = pad;
		var i:Int = 0;
		var n:Int = items.length;
		while (i < n) {
			var child:DisplayObject = items[i];
			if (stretch && (child is UIComponent)) {
				var uc:UIComponent = cast child;
				if (vertical)
					uc.resize(crossExtent, uc.h);
				else
					uc.resize(uc.w, crossExtent);
			}
			var childCross:Float = vertical ? widthOf(child) : heightOf(child);
			var crossPos:Float = pad;
			if (!stretch) {
				crossPos = switch (align) {
					case CENTER: pad + (crossExtent - childCross) / 2;
					case END: pad + crossExtent - childCross;
					default: pad;
				}
			}
			if (vertical) {
				child.x = crossPos;
				child.y = pos;
				pos += heightOf(child) + g;
			} else {
				child.x = pos;
				child.y = crossPos;
				pos += widthOf(child) + g;
			}
			i++;
		}
		if (n > 0)
			pos -= g; // drop the trailing gap
		pos += pad;
		if (vertical)
			h = pos;
		else
			w = pos;
	}

	function set_vertical(v:Bool):Bool {
		vertical = v;
		invalidate();
		return v;
	}

	function set_gap(v:Float):Float {
		gap = v;
		invalidate();
		return v;
	}

	function set_padding(v:Float):Float {
		padding = v;
		invalidate();
		return v;
	}

	function set_stretch(v:Bool):Bool {
		stretch = v;
		invalidate();
		return v;
	}

	function set_align(v:UIAlign):UIAlign {
		align = v;
		invalidate();
		return v;
	}
}
