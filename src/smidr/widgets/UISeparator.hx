package smidr.widgets;

import smidr.UIColor;
import smidr.UIComponent;
import smidr.UITheme;

/** A 1px themed divider line (horizontal by default). **/
final class UISeparator extends UIComponent {
	/**
		@param length the line length
		@param vertical `true` for a vertical divider
	**/
	public function new(length:Float, vertical:Bool = false) {
		super(false, false);
		resize(vertical ? 1 : length, vertical ? length : 1);
		render();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(UIColor.rgb(UITheme.border));
		graphics.drawRect(0, 0, (w > 1) ? w : 1, (h > 1) ? h : 1);
		graphics.endFill();
	}
}
