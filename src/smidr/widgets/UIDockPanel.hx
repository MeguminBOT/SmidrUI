package smidr.widgets;

import openfl.display.Sprite;
import smidr.UIComponent;

/**
	One dockable panel: a titled content surface shown in a `UIDockGroup` tab. Add the panel's
	widgets to `content` (origin at the panel's top-left); the hosting group sizes and positions
	it. The `title` labels its tab.

	Panels are moved between groups (and split into new ones) by dragging their tab in a
	`UIDockHost`; a `closable` panel shows an X on its tab and fires `onClosed` when removed.
**/
final class UIDockPanel extends UIComponent {
	/** The tab label. **/
	public var title(default, set):String;

	/** Put the panel's widgets here (coordinates relative to the panel's top-left). **/
	public final content:Sprite;

	/** Shows a close affordance on the tab; the panel fires `onClosed` when removed that way. **/
	public var closable:Bool = true;

	/** Fired after the panel is closed (tab close button). **/
	public var onClosed:Void->Void = null;

	/**
		@param title the tab label
	**/
	public function new(title:String) {
		super(false, true);
		@:bypassAccessor this.title = title;
		content = new Sprite();
		addChild(content);
		render();
	}

	override public function render():Void {
		// a transparent hit surface so the blocking panel body never leaks pointer hits through
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		content.x = 0;
		content.y = 0;
	}

	override public function dispose():Void {
		var i:Int = content.numChildren;
		while (--i >= 0) {
			var child = content.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		content.removeChildren();
		super.dispose();
	}

	function set_title(value:String):String {
		title = value;
		invalidate();
		return value;
	}
}
