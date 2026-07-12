package smidr.widgets;

import openfl.Lib;
import openfl.events.MouseEvent;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.UITween;
import smidr.input.UIPointer;

/** Which viewport edge a `UIDrawer` docks to. **/
enum abstract UIDrawerSide(Int) to Int {
	var LEFT = 0;
	var RIGHT = 1;
}

/**
	A persistent slide-out panel docked to the left or right viewport edge, for mobile layouts
	where desktop side panels don't fit. Add widgets to `content`; the drawer lives on
	`UIRoot.popupLayer` above a tap-to-close scrim while open.

	Gestures: swiping in from the docked edge (`edgeSwipeEnabled`, an invisible strip) pulls the
	drawer open following the finger; a horizontally-dominant drag on the open drawer slides it
	back out (vertical drags pass through, so scroll panes inside keep working); releasing
	settles open/closed by velocity, then position. The scrim tap, Escape and the host's Back
	handling (via `UIRoot.pushOverlayCloser`) also close it. `open()`/`close()` drive it
	programmatically. Unlike `UIModal`, closing does NOT dispose the drawer — reuse it across
	openings and `dispose()` it with the screen.
**/
final class UIDrawer extends UIComponent {
	/** Put drawer content here (coordinates relative to the drawer's top-left). **/
	public final content:UIComponent;

	/** The docked edge. **/
	public final side:UIDrawerSide;

	/** Openable by swiping from the viewport edge (default on for mobile). **/
	public var edgeSwipeEnabled(default, set):Bool = #if mobile true #else false #end;

	/** Fired after the drawer finishes opening. **/
	public var onOpened:Void->Void = null;

	/** Fired after the drawer finishes closing. **/
	public var onClosed:Void->Void = null;

	/** 0 = fully closed (off-screen), 1 = fully open. **/
	public var progress(default, null):Float = 0;

	/** `true` once the drawer has settled open (not while animating/dragging). **/
	public var isOpen(default, null):Bool = false;

	var scrim:UIComponent;
	var edgeStrip:UIComponent;
	var tween:UITween = null;

	var viewportWidth:Float = 0;
	var viewportHeight:Float = 0;

	var horizontalDragPending:Bool = false;
	var dragging:Bool = false;
	var dragStartX:Float = 0;
	var dragStartY:Float = 0;
	var dragStartProgress:Float = 0;
	var lastPointerX:Float = 0;
	var lastPointerTime:Int = 0;
	var velocity:Float = 0;
	var closerPushed:Bool = false;

	/**
		@param side the viewport edge to dock to
		@param width the open drawer's width in UI units
	**/
	public function new(side:UIDrawerSide, width:Float) {
		super(false, true);
		this.side = side;

		scrim = new UIComponent(true, true);
		scrim.hoverCursor = null;
		scrim.onClick = close;
		scrim.graphics.beginFill(0x000000, 0.55);
		scrim.graphics.drawRect(-16000, -16000, 32000, 32000);
		scrim.graphics.endFill();

		edgeStrip = new UIComponent(true, true);
		edgeStrip.hoverCursor = null;
		edgeStrip.addEventListener(MouseEvent.MOUSE_DOWN, __onEdgePress);

		content = new UIComponent(false, false);
		addChild(content);

		addEventListener(MouseEvent.MOUSE_DOWN, __onPanelDown);
		addEventListener(MouseEvent.MOUSE_MOVE, __onPanelMove);

		resize(width, 1);
	}

	/**
		Installs the edge-swipe strip on the current root. Call once after creating the drawer
		(and again if the viewport size changes). No-op while `edgeSwipeEnabled` is false.
	**/
	public function attachEdge():Void {
		layoutViewport();
		if (!edgeSwipeEnabled)
			return;
		var root:UIRoot = UIRoot.current;
		if (root == null)
			return;
		var stripW:Float = UITheme.px(18);
		edgeStrip.graphics.clear();
		edgeStrip.graphics.beginFill(0, 0);
		edgeStrip.graphics.drawRect(0, 0, stripW, viewportHeight);
		edgeStrip.graphics.endFill();
		edgeStrip.x = (side == LEFT) ? 0 : viewportWidth - stripW;
		edgeStrip.y = 0;
		root.popupLayer.addChild(edgeStrip);
	}

	function layoutViewport():Void {
		var root:UIRoot = UIRoot.current;
		viewportWidth = (root != null && root.stage != null) ? root.stage.stageWidth / (root.scaleX > 0 ? root.scaleX : 1) : 1280;
		viewportHeight = (root != null && root.stage != null) ? root.stage.stageHeight / (root.scaleY > 0 ? root.scaleY : 1) : 720;
		resize(w, viewportHeight);
	}

	/** Slides the drawer open. **/
	public function open():Void {
		animateTo(1);
	}

	/** Slides the drawer closed. **/
	public function close():Void {
		animateTo(0);
	}

	function animateTo(target:Float):Void {
		show();
		if (tween != null)
			tween.cancel();
		var ms:Float = 180 * Math.abs(target - progress);
		if (ms < 1)
			ms = 1;
		tween = UITween.to(applyProgress, progress, target, ms, target > 0 ? OUT_QUAD : IN_QUAD, target > 0 ? finishOpen : finishClose);
	}

	function show():Void {
		var root:UIRoot = UIRoot.current;
		if (root == null)
			return;
		layoutViewport();
		if (scrim.parent == null)
			root.popupLayer.addChild(scrim);
		if (parent == null)
			root.popupLayer.addChild(this);
		else
			root.popupLayer.addChild(this); // re-raise above the scrim
		if (!closerPushed) {
			closerPushed = true;
			UIRoot.pushOverlayCloser(close);
		}
	}

	function applyProgress(value:Float):Void {
		progress = value;
		x = (side == LEFT) ? (value - 1) * w : viewportWidth - value * w;
		y = 0;
		scrim.alpha = value;
	}

	function finishOpen():Void {
		tween = null;
		isOpen = true;
		if (onOpened != null)
			onOpened();
	}

	function finishClose():Void {
		tween = null;
		isOpen = false;
		if (closerPushed) {
			closerPushed = false;
			UIRoot.removeOverlayCloser(close);
		}
		if (scrim.parent != null)
			scrim.parent.removeChild(scrim);
		if (parent != null)
			parent.removeChild(this);
		if (onClosed != null)
			onClosed();
	}

	function __onEdgePress(event:MouseEvent):Void {
		if (!edgeSwipeEnabled)
			return;
		beginDrag(event.stageX);
		event.stopPropagation();
	}

	function __onPanelDown(event:MouseEvent):Void {
		horizontalDragPending = true;
		dragStartX = event.stageX;
		dragStartY = event.stageY;
	}

	function __onPanelMove(event:MouseEvent):Void {
		if (!horizontalDragPending || dragging)
			return;
		if (!event.buttonDown) {
			horizontalDragPending = false;
			return;
		}
		var sf:Float = scaleFactorX();
		var dx:Float = Math.abs(event.stageX - dragStartX);
		var dy:Float = Math.abs(event.stageY - dragStartY);
		var slop:Float = UITheme.px(10) * sf;
		if (dx < slop && dy < slop)
			return;
		horizontalDragPending = false;
		// only horizontally-dominant drags grab the drawer; vertical ones belong to the content
		if (dx <= dy * 1.2 || UIPointer.captureTarget != null)
			return;
		var pt:UIComponent = UIPointer.pressTarget;
		if (pt != null)
			@:privateAccess pt.releasePress(false);
		@:privateAccess UIPointer.clearPress();
		beginDrag(event.stageX);
	}

	function beginDrag(stageX:Float):Void {
		if (tween != null) {
			tween.cancel();
			tween = null;
		}
		show();
		dragging = true;
		dragStartX = stageX;
		dragStartProgress = progress;
		lastPointerX = stageX;
		lastPointerTime = Lib.getTimer();
		velocity = 0;
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (!dragging)
			return;
		var sf:Float = scaleFactorX();
		var now:Int = Lib.getTimer();
		var dt:Float = now - lastPointerTime;
		if (dt > 0) {
			velocity = ((stageX - lastPointerX) / sf) / dt;
			lastPointerX = stageX;
			lastPointerTime = now;
		}
		var delta:Float = (stageX - dragStartX) / sf / w;
		var nextProgress:Float = dragStartProgress + ((side == LEFT) ? delta : -delta);
		if (nextProgress < 0)
			nextProgress = 0;
		if (nextProgress > 1)
			nextProgress = 1;
		applyProgress(nextProgress);
	}

	override function onDragEnd():Void {
		if (!dragging)
			return;
		dragging = false;
		// velocity picks the direction when the finger was still moving; position otherwise
		var toward:Float = (side == LEFT) ? velocity : -velocity;
		if (Math.abs(velocity) > 0.15)
			animateTo(toward > 0 ? 1 : 0);
		else
			animateTo(progress >= 0.5 ? 1 : 0);
	}

	inline function scaleFactorX():Float {
		var root = UIRoot.current;
		return (root != null && root.scaleX > 0) ? root.scaleX : 1.0;
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(UIColor.rgb(UITheme.panel));
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		var edgeX:Float = (side == LEFT) ? w - 0.5 : 0.5;
		graphics.lineStyle(1, UIColor.rgb(UITheme.border2));
		graphics.moveTo(edgeX, 0);
		graphics.lineTo(edgeX, h);
		graphics.lineStyle();
		content.x = 0;
		content.y = 0;
	}

	function set_edgeSwipeEnabled(value:Bool):Bool {
		edgeSwipeEnabled = value;
		if (!value && edgeStrip != null && edgeStrip.parent != null)
			edgeStrip.parent.removeChild(edgeStrip);
		return value;
	}

	override public function dispose():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, __onPanelDown);
		removeEventListener(MouseEvent.MOUSE_MOVE, __onPanelMove);
		edgeStrip.removeEventListener(MouseEvent.MOUSE_DOWN, __onEdgePress);
		if (tween != null) {
			tween.cancel();
			tween = null;
		}
		if (closerPushed) {
			closerPushed = false;
			UIRoot.removeOverlayCloser(close);
		}
		if (scrim.parent != null)
			scrim.parent.removeChild(scrim);
		scrim.dispose();
		if (edgeStrip.parent != null)
			edgeStrip.parent.removeChild(edgeStrip);
		edgeStrip.dispose();
		super.dispose();
	}
}
