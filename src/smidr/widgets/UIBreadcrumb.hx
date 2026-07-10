package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;

/**
	A path/navigation trail: clickable segments separated by chevrons, with the last segment shown
	as the current (brighter) location. Clicking a segment fires `onSelect(index)`. Set the trail
	with `setPath`; the row hit-tests segment x-ranges rather than nesting child widgets.
**/
final class UIBreadcrumb extends UIComponent {
	/** Fired when a segment is clicked (its index in the path). **/
	public var onSelect:Int->Void = null;

	public var fontSize(default, set):Int = 12;

	var segments:Array<String> = [];
	var fields:Array<TextField> = [];
	var ranges:Array<Float> = [];

	/**
		@param onSelect fired when a segment is clicked
	**/
	public function new(?onSelect:Int->Void) {
		super(true, true);
		this.onSelect = onSelect;
		resize(UITheme.px(200), UITheme.px(24));
		render();
	}

	/**
		Sets the trail segments (last is the current location).
		@param segments the ordered path parts
	**/
	public function setPath(segments:Array<String>):Void {
		this.segments = (segments != null) ? segments : [];
		invalidate();
	}

	override function onPress(localX:Float, localY:Float):Void {
		for (i in 0...ranges.length) {
			if (localX <= ranges[i]) {
				if (i < segments.length - 1 && onSelect != null)
					onSelect(i);
				return;
			}
		}
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();

		while (fields.length > segments.length) {
			var extra:TextField = fields.pop();
			if (extra.parent != null)
				extra.parent.removeChild(extra);
		}
		while (fields.length < segments.length) {
			var field:TextField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
			addChild(field);
			fields.push(field);
		}

		ranges.resize(0);
		var chevronGap:Float = UITheme.px(6);
		var chevronW:Float = UITheme.px(5);
		var x:Float = 0;
		for (i in 0...segments.length) {
			var last:Bool = (i == segments.length - 1);
			var field:TextField = fields[i];
			UIFonts.restyle(field, UITheme.fs(fontSize), last ? UITheme.text : UITheme.text2);
			if (field.text != segments[i])
				field.text = segments[i];
			field.x = x;
			field.y = (h - field.height) / 2;
			x += field.width;
			// the clickable range for this segment ends halfway into the chevron gap
			ranges.push(x + chevronGap);

			if (!last) {
				var cx:Float = x + chevronGap;
				var cy:Float = h / 2;
				g.beginFill(UIColor.rgb(UITheme.text3));
				g.moveTo(cx, cy - chevronW);
				g.lineTo(cx + chevronW * 0.8, cy);
				g.lineTo(cx, cy + chevronW);
				g.endFill();
				x += chevronGap * 2 + chevronW;
			}
		}
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
