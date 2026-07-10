package smidr.widgets;

import openfl.events.MouseEvent;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIGlyphs;
import smidr.UITheme;
import smidr.types.UIGlyph;

/**
	A star rating: a row of `max` stars, filled up to `rating`. Clicking or dragging sets the
	rating (with a live hover preview), unless `readOnly`. `onChange` fires with the new 1-based
	rating (0 when cleared by clicking the current single star). Uses the built-in `STAR` glyph.
**/
final class UIRating extends UIComponent {
	/** Number of stars. **/
	public var max(default, set):Int;

	/** Current rating (0..max). **/
	public var rating(default, set):Int;

	/** Fired when the rating changes. **/
	public var onChange:Int->Void = null;

	/** Base (unscaled) star size. **/
	public var starSize:Float = 20;

	/** Base (unscaled) gap between stars. **/
	public var gap:Float = 4;

	/** Filled-star colour, or -1 for the theme warning colour. **/
	public var color:Int = -1;

	/** Display only (no pointer interaction). **/
	public var readOnly:Bool = false;

	var hoverRating:Int = -1;

	/**
		@param max number of stars
		@param rating the initial rating
		@param onChange fired when the rating changes
	**/
	public function new(max:Int = 5, rating:Int = 0, ?onChange:Int->Void) {
		super(true, true);
		this.max = max;
		this.rating = rating;
		this.onChange = onChange;
		hoverCursor = openfl.ui.MouseCursor.BUTTON;
		addEventListener(MouseEvent.MOUSE_MOVE, __onMove);
		resizeToContent();
		render();
	}

	function set_max(value:Int):Int {
		max = value;
		if (rating > max)
			rating = max;
		resizeToContent();
		return value;
	}

	function set_rating(value:Int):Int {
		if (value < 0)
			value = 0;
		if (value > max)
			value = max;
		rating = value;
		invalidate();
		return value;
	}

	inline function pitch():Float {
		return UITheme.px(starSize) + UITheme.px(gap);
	}

	function resizeToContent():Void {
		resize(max * pitch() - UITheme.px(gap), UITheme.px(starSize));
	}

	function starAt(localX:Float):Int {
		var index:Int = Std.int(localX / pitch()) + 1;
		if (index < 1)
			index = 1;
		if (index > max)
			index = max;
		return index;
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (readOnly)
			return;
		var next:Int = starAt(localX);
		// clicking the sole filled star clears the rating
		if (next == rating && next == 1)
			next = 0;
		if (next != rating) {
			rating = next;
			if (onChange != null)
				onChange(rating);
		}
	}

	function __onMove(e:MouseEvent):Void {
		if (readOnly)
			return;
		var preview:Int = starAt(e.localX);
		if (preview != hoverRating) {
			hoverRating = preview;
			invalidate();
		}
	}

	override function onStateChanged():Void {
		if (!hovered)
			hoverRating = -1;
		invalidate();
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var size:Float = UITheme.px(starSize);
		var step:Float = pitch();
		var shown:Int = (hoverRating >= 0) ? hoverRating : rating;
		var fill:Int = (color == -1) ? UITheme.warning : color;
		for (i in 0...max) {
			var filled:Bool = (i < shown);
			UIGlyphs.draw(g, UIGlyph.STAR, i * step, 0, size, UIColor.rgb(filled ? fill : UITheme.text3), filled ? 1 : 0.6);
		}
	}

	override public function dispose():Void {
		removeEventListener(MouseEvent.MOUSE_MOVE, __onMove);
		super.dispose();
	}
}
