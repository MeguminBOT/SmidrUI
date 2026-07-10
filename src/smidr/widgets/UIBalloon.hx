package smidr.widgets;

import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.geom.Point;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.UITween;
import smidr.types.UIEase;

/**
	A callout / popover: a rounded panel with a directional tail pointing at an anchor point,
	shown on `UIRoot.popupLayer`. Add content to `body` (below the optional title). It prefers to
	sit below the anchor with the tail pointing up, flips above when it would clip the viewport
	bottom, and clamps horizontally while keeping the tail aimed at the anchor.

	A transparent full-screen blocker sits behind it: a click outside closes it (as do Escape and
	the host's Back handling via `UIRoot.pushOverlayCloser`). Unlike `UIModal` it does not dim the
	background. Closing disposes the balloon.
**/
final class UIBalloon extends UIComponent {
	/** Add balloon content here (coordinates relative to the balloon, below the title). **/
	public final body:UIComponent;

	/** Fired after the balloon fully closes. **/
	public var onClosed:Void->Void = null;

	/** Optional header text; `null` for a title-less balloon. **/
	public var titleText(default, set):String = null;

	var blocker:UIComponent;
	var titleLabel:UILabel = null;
	var tailSize:Float;
	var tailCenter:Float = 0;
	var tailOnTop:Bool = true;
	var closing:Bool = false;

	/**
		@param width the balloon width
		@param height the balloon height (tail excluded)
		@param title optional header text
	**/
	public function new(width:Float, height:Float, ?title:String) {
		super(false, true);
		tailSize = UITheme.px(7);

		blocker = new UIComponent(true, true);
		blocker.hoverCursor = null;
		blocker.onClick = close;
		blocker.graphics.beginFill(0, 0);
		blocker.graphics.drawRect(-16000, -16000, 32000, 32000);
		blocker.graphics.endFill();

		if (title != null) {
			titleLabel = new UILabel(title, 13, PRIMARY);
			addChild(titleLabel);
			@:bypassAccessor titleText = title;
		}

		body = new UIComponent(false, false);
		addChild(body);
		resize(width, height);
		render();
	}

	/**
		Opens the balloon pointing at a UI-space anchor point.
		@param anchorX the anchor x in UI (root content) coordinates
		@param anchorY the anchor y in UI coordinates
	**/
	public function open(anchorX:Float, anchorY:Float):Void {
		var root:UIRoot = UIRoot.current;
		if (root == null)
			return;
		root.popupLayer.addChild(blocker);
		root.popupLayer.addChild(this);
		place(root, anchorX, anchorY);
		UIRoot.pushOverlayCloser(close);
		alpha = 0;
		UITween.to(setAlpha, 0, 1, 150, OUT_QUAD);
	}

	/**
		Opens the balloon pointing at the bottom-center of a display object.
		@param target the object to point at (must be on the stage)
	**/
	public function openAt(target:DisplayObject):Void {
		var root:UIRoot = UIRoot.current;
		if (root == null || target.stage == null)
			return;
		var global:Point = target.localToGlobal(new Point(target.width / 2, target.height));
		var local:Point = root.globalToLocal(global);
		open(local.x, local.y);
	}

	function place(root:UIRoot, anchorX:Float, anchorY:Float):Void {
		tailSize = UITheme.px(7);
		var vw:Float = (root.stage != null && root.scaleX > 0) ? root.stage.stageWidth / root.scaleX : 1280;
		var vh:Float = (root.stage != null && root.scaleY > 0) ? root.stage.stageHeight / root.scaleY : 720;
		var margin:Float = UITheme.px(6);

		tailOnTop = true;
		var top:Float = anchorY + tailSize;
		if (top + h > vh - margin && anchorY - tailSize - h > margin) {
			tailOnTop = false;
			top = anchorY - tailSize - h;
		}
		var left:Float = anchorX - w / 2;
		if (left < margin)
			left = margin;
		if (left + w > vw - margin)
			left = vw - margin - w;
		x = left;
		y = top;

		var edge:Float = UITheme.px(8) + tailSize + UITheme.px(2);
		tailCenter = anchorX - left;
		if (tailCenter < edge)
			tailCenter = edge;
		if (tailCenter > w - edge)
			tailCenter = w - edge;
	}

	function setAlpha(value:Float):Void {
		alpha = value;
	}

	/** Closes the balloon (fade out, then dispose). **/
	public function close():Void {
		if (closing)
			return;
		closing = true;
		UIRoot.removeOverlayCloser(close);
		UITween.to(setAlpha, alpha, 0, 110, IN_QUAD, finishClose);
	}

	function finishClose():Void {
		if (blocker.parent != null)
			blocker.parent.removeChild(blocker);
		blocker.dispose();
		var done:Void->Void = onClosed;
		dispose();
		if (done != null)
			done();
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.lineStyle(1, UIColor.rgb(UITheme.border2));
		drawBubble(g);
		g.endFill();
		g.lineStyle();

		var top:Float = UITheme.px(10);
		if (titleLabel != null) {
			titleLabel.x = UITheme.px(12);
			titleLabel.y = UITheme.px(10);
			top = UITheme.px(32);
		}
		body.x = 0;
		body.y = top;
	}

	/** Traces the rounded panel outline with the tail notch integrated into the tailed edge. **/
	function drawBubble(graphics:Graphics):Void {
		var radius:Float = UITheme.px(8);
		var tail:Float = tailSize;
		var tailX:Float = tailCenter;
		if (tailOnTop) {
			graphics.moveTo(radius, 0);
			graphics.lineTo(tailX - tail, 0);
			graphics.lineTo(tailX, -tail);
			graphics.lineTo(tailX + tail, 0);
			graphics.lineTo(w - radius, 0);
			graphics.curveTo(w, 0, w, radius);
			graphics.lineTo(w, h - radius);
			graphics.curveTo(w, h, w - radius, h);
			graphics.lineTo(radius, h);
			graphics.curveTo(0, h, 0, h - radius);
			graphics.lineTo(0, radius);
			graphics.curveTo(0, 0, radius, 0);
		} else {
			graphics.moveTo(radius, 0);
			graphics.lineTo(w - radius, 0);
			graphics.curveTo(w, 0, w, radius);
			graphics.lineTo(w, h - radius);
			graphics.curveTo(w, h, w - radius, h);
			graphics.lineTo(tailX + tail, h);
			graphics.lineTo(tailX, h + tail);
			graphics.lineTo(tailX - tail, h);
			graphics.lineTo(radius, h);
			graphics.curveTo(0, h, 0, h - radius);
			graphics.lineTo(0, radius);
			graphics.curveTo(0, 0, radius, 0);
		}
	}

	override public function dispose():Void {
		if (blocker.parent != null)
			blocker.parent.removeChild(blocker);
		blocker.dispose();
		super.dispose();
	}

	function set_titleText(v:String):String {
		titleText = v;
		if (v != null && titleLabel == null) {
			titleLabel = new UILabel(v, 13, PRIMARY);
			addChild(titleLabel);
		} else if (titleLabel != null)
			titleLabel.text = (v != null) ? v : "";
		invalidate();
		return v;
	}
}
