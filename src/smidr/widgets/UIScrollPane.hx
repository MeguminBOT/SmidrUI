package smidr.widgets;

import openfl.Lib;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.input.UIPointer;

/**
	A fixed-size, vertically scrollable container. Add children to `content`; call
	`refreshContent()` after (re)filling it. Scrolls by mouse wheel and by dragging the slim
	scrollbar thumb; on mobile (`touchScroll`) dragging anywhere scrolls with fling momentum —
	a drag past the threshold steals the press so no child widget clicks. Clipping uses
	`scrollRect` (GPU clip — scrolling never repaints children).
**/
final class UIScrollPane extends UIComponent {
	/** Put pane content here (coordinates relative to the pane's top-left). **/
	public final content:Sprite;

	/** Current scroll offset in pixels (0..maxScroll). **/
	public var scrollY(default, null):Float = 0;

	/** Pixels per wheel notch. **/
	public var wheelStep:Float = 40;

	/** Drag-anywhere scrolling with fling momentum (default on for mobile). **/
	public var touchScroll:Bool = #if mobile true #else false #end;

	static inline var MODE_NONE:Int = 0;
	static inline var MODE_THUMB:Int = 1;
	static inline var MODE_TOUCH:Int = 2;

	var contentHeight:Float = 0;
	var thumb:Shape;

	var mode:Int = MODE_NONE;
	var dragPending:Bool = false;
	var dragGrabY:Float = 0;
	var dragStartScroll:Float = 0;
	var lastPointerY:Float = 0;
	var lastPointerTime:Int = 0;
	var velocity:Float = 0;
	var flinging:Bool = false;

	/**
		@param width layout width (the scrollbar lives inside it)
		@param height the visible viewport height
	**/
	public function new(width:Float, height:Float) {
		super(false, true);
		content = new Sprite();
		addChild(content);
		thumb = new Shape();
		addChild(thumb);
		addEventListener(MouseEvent.MOUSE_WHEEL, __onWheel);
		addEventListener(MouseEvent.MOUSE_DOWN, __onDown);
		addEventListener(MouseEvent.MOUSE_MOVE, __onMove);
		resize(width, height);
		render();
	}

	/**
		Re-measures the content height and clamps the scroll position. Call after (re)filling
		`content`.
		@param explicitHeight overrides the measured `content.height` when provided
	**/
	public function refreshContent(?explicitHeight:Float):Void {
		contentHeight = (explicitHeight != null) ? explicitHeight : content.height;
		setScroll(scrollY);
		invalidate();
	}

	/** The furthest `scrollY` can go. **/
	public var maxScroll(get, never):Float;

	inline function get_maxScroll():Float {
		var max:Float = contentHeight - h;
		return (max > 0) ? max : 0;
	}

	/**
		Scrolls to an absolute offset.
		@param value the target offset in pixels (clamped to 0..`maxScroll`)
	**/
	public function setScroll(value:Float):Void {
		var max:Float = maxScroll;
		if (value < 0)
			value = 0;
		if (value > max)
			value = max;
		scrollY = value;
		content.scrollRect = new Rectangle(0, scrollY, w, h);
		positionThumb();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(UIColor.rgb(UITheme.panel));
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		content.scrollRect = new Rectangle(0, scrollY, w, h);
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
		var thumbH:Float = trackH * (h / contentHeight);
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
		var thumbH:Float = trackH * (h / contentHeight);
		if (thumbH < 24)
			thumbH = 24;
		thumb.x = w - UITheme.px(4) - 2;
		thumb.y = 2 + (trackH - thumbH) * (scrollY / max);
	}

	function __onWheel(event:MouseEvent):Void {
		if (maxScroll <= 0)
			return;
		stopFling();
		setScroll(scrollY - event.delta * wheelStep);
		event.stopPropagation();
	}

	function __onDown(event:MouseEvent):Void {
		stopFling();
		if (maxScroll <= 0)
			return;
		if (mouseX >= w - UITheme.px(4) - 4) {
			mode = MODE_THUMB;
			dragGrabY = event.stageY;
			dragStartScroll = scrollY;
			beginCapture();
			event.stopPropagation();
			return;
		}
		if (touchScroll) {
			dragPending = true;
			dragGrabY = event.stageY;
			dragStartScroll = scrollY;
			lastPointerY = event.stageY;
			lastPointerTime = Lib.getTimer();
			velocity = 0;
		}
	}

	function __onMove(event:MouseEvent):Void {
		if (!dragPending || mode != MODE_NONE)
			return;
		if (!event.buttonDown) {
			dragPending = false;
			return;
		}
		if (Math.abs(event.stageY - dragGrabY) < UITheme.px(8) * scaleFactorY())
			return;
		// a deeper widget (e.g. a UIList inside the pane) may already own the drag
		if (UIPointer.captureTarget != null) {
			dragPending = false;
			return;
		}
		// steal the press: the child widget must neither stay pressed nor click on release
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
			setScroll(dragStartScroll + ((stageY - dragGrabY) / sf) * (maxScroll / usable));
		} else if (mode == MODE_TOUCH) {
			var now:Int = Lib.getTimer();
			var dt:Float = now - lastPointerTime;
			if (dt > 0) {
				velocity = ((stageY - lastPointerY) / sf) / dt;
				lastPointerY = stageY;
				lastPointerTime = now;
			}
			setScroll(dragStartScroll - (stageY - dragGrabY) / sf);
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
		var i:Int = content.numChildren;
		while (--i >= 0) {
			var child = content.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		content.removeChildren();
		super.dispose();
	}
}
