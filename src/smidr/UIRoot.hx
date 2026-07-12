package smidr;

import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;
import smidr.input.UIPointer;

/**
	The library's stage-attached root: three layers (`content` < `popupLayer` < `tooltipLayer`),
	the invalidation scheduler, the pointer arbiter and the tween/tooltip driver.

	One `ENTER_FRAME` handler flushes dirty widgets and steps tweens — an idle UI performs no
	work. Global mouse listeners (capture phase) maintain `UIPointer.overUI/downOnUI` so the host
	game layer can ignore pointer input that belongs to the UI, complete press-started clicks,
	and route drag capture. A key listener routes typing to `UIFocus` and consumes handled keys
	before they reach the host.

	The host positions the root over its game viewport with `setViewport` (offset + scale) so UI
	coordinates match game coordinates under any letterboxing.
**/
final class UIRoot extends Sprite {
	/** The active root (one per state/screen). **/
	public static var current(default, null):UIRoot = null;

	/** Regular widget layer. **/
	public final content:Sprite;

	/** Dropdown popups, menus, modals — always above content. **/
	public final popupLayer:Sprite;

	/** The shared tooltip — always on top. **/
	public final tooltipLayer:Sprite;

	static var dirty:Array<UIComponent> = [];
	static var dirtySwap:Array<UIComponent> = [];
	static var tickers:Array<Float->Void> = [];

	static var hoverComp:UIComponent = null;
	static var hoverTime:Float = 0;

	var lastTimer:Int = 0;
	var attachedStage:openfl.display.Stage = null;

	public function new() {
		super();
		current = this;
		mouseEnabled = false;
		content = new Sprite();
		popupLayer = new Sprite();
		tooltipLayer = new Sprite();
		tooltipLayer.mouseEnabled = false;
		tooltipLayer.mouseChildren = false;
		addChild(content);
		addChild(popupLayer);
		addChild(tooltipLayer);
		UITheme.onChanged = invalidateAll;
		UILocale.onChanged = invalidateAll;
		addEventListener(Event.ADDED_TO_STAGE, __onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, __onRemovedFromStage);
	}

	/**
		Adds the root to a display parent.
		@param parent the container to attach to (typically above the game view)
		@param index optional child depth; -1 appends on top
	**/
	public function attach(parent:DisplayObjectContainer, index:Int = -1):Void {
		if (index >= 0)
			parent.addChildAt(this, index);
		else
			parent.addChild(this);
	}

	/**
		Positions/scales the root over the host's content viewport, so UI coordinates match the
		host's coordinate space under any letterboxing.
		@param offsetX viewport left edge in stage pixels
		@param offsetY viewport top edge in stage pixels
		@param scaleX horizontal stage-pixels-per-unit factor
		@param scaleY vertical stage-pixels-per-unit factor
	**/
	public function setViewport(offsetX:Float, offsetY:Float, scaleX:Float, scaleY:Float):Void {
		this.x = offsetX;
		this.y = offsetY;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}

	/**
		Queues a widget repaint for the next frame (deduplicated).
		@param c the widget whose `render()` should run on the next flush
	**/
	public static function schedule(component:UIComponent):Void {
		if (component.__dirty)
			return;
		component.__dirty = true;
		dirty.push(component);
	}

	static var overlayClosers:Array<Void->Void> = [];

	/**
		Pushes a closer for the topmost transient overlay (popup/menu/modal); Escape pops it.
		@param fn closes the overlay when invoked
	**/
	public static function pushOverlayCloser(fn:Void->Void):Void {
		overlayClosers.push(fn);
	}

	/**
		Removes a previously pushed overlay closer (call when the overlay closes itself).
		@param fn the same function passed to `pushOverlayCloser`
	**/
	public static function removeOverlayCloser(fn:Void->Void):Void {
		overlayClosers.remove(fn);
	}

	/** `true` while any transient overlay (popup/menu/modal) is open. **/
	public static var overlayOpen(get, never):Bool;

	static inline function get_overlayOpen():Bool {
		return overlayClosers.length > 0;
	}

	/**
		Registers a per-frame callback (held-repeat, caret blink). Keep these rare — an idle
		UI should have no tickers running.
		@param fn receives the elapsed milliseconds each frame
	**/
	public static function addTicker(fn:Float->Void):Void {
		if (tickers.indexOf(fn) < 0)
			tickers.push(fn);
	}

	/**
		Removes a per-frame callback.
		@param fn the same function passed to `addTicker`
	**/
	public static function removeTicker(fn:Float->Void):Void {
		tickers.remove(fn);
	}

	/** Re-renders every live widget (theme/locale change). **/
	public function invalidateAll():Void {
		invalidateTree(this);
	}

	static function invalidateTree(container:DisplayObjectContainer):Void {
		var i:Int = container.numChildren;
		while (--i >= 0) {
			var child:DisplayObject = container.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).invalidate();
			if (child is DisplayObjectContainer)
				invalidateTree(cast child);
		}
	}

	/**
		Whether a display object sits inside this UI tree (walks the parent chain).
		@param obj the event target to test
		@return `true` when `obj` is this root or one of its descendants
	**/
	public function containsTarget(obj:DisplayObject):Bool {
		while (obj != null) {
			if (obj == this)
				return true;
			obj = obj.parent;
		}
		return false;
	}

	/** The widget currently awaiting/showing a tooltip. **/
	public static var tooltipTarget(get, never):UIComponent;

	static inline function get_tooltipTarget():UIComponent {
		return hoverComp;
	}

	/** Fired when the hover delay elapses; assigned by the tooltip widget. **/
	public static var onTooltipShow:UIComponent->Void = null;

	/** Fired when the hovered widget is left/pressed; assigned by the tooltip widget. **/
	public static var onTooltipHide:Void->Void = null;

	/** Hover-delay before a tooltip appears, in ms. **/
	public static var tooltipDelayMs:Float = 500;

	/**
		Long-press-as-right-click for touch (default on for mobile): a press held `longPressMs`
		without moving past the slop and without any drag capture fires the pressed widget's
		right-click path (`onRightPress`/`onRightClick`), or peeks its tooltip when it has no
		right-click consumer. The press is stolen either way, so releasing never also clicks.
	**/
	public static var longPressEnabled:Bool = #if mobile true #else false #end;

	/** Hold time before a long-press fires, in ms. **/
	public static var longPressMs:Float = 500;

	/** Fired when a long-press triggers; assign for haptic/audio feedback. **/
	public static var onLongPress:UIComponent->Void = null;

	static var pressStageX:Float = 0;
	static var pressStageY:Float = 0;
	static var pressTime:Float = 0;
	static var longPressArmed:Bool = false;

	@:allow(smidr.UIComponent)
	static function tooltipEnter(component:UIComponent):Void {
		hoverComp = component;
		hoverTime = 0;
	}

	@:allow(smidr.UIComponent)
	static function tooltipLeave(component:UIComponent):Void {
		if (hoverComp != component)
			return;
		hoverComp = null;
		hoverTime = 0;
		if (onTooltipHide != null)
			onTooltipHide();
	}

	function __onFrame(_:Event):Void {
		// Only the current (most recently staged) root steps the SHARED systems below (dirty
		// flush, tweens, tickers, tooltip timing): if two roots ever overlap during a state
		// hand-off, or one leaks, each would step them per frame, making caret blinks and
		// hold-to-repeat run at a multiple of real time.
		if (current != this)
			return;
		var now:Int = Lib.getTimer();
		var dt:Float = now - lastTimer;
		lastTimer = now;
		if (dt < 0 || dt > 250)
			dt = 16.6;

		if (dirty.length > 0) {
			var flushing:Array<UIComponent> = dirty;
			dirty = dirtySwap;
			dirtySwap = flushing;
			var i:Int = 0;
			var count:Int = flushing.length;
			while (i < count) {
				var component:UIComponent = flushing[i];
				component.__dirty = false;
				component.render();
				i++;
			}
			flushing.resize(0);
		}

		UITween.step(dt);

		var ti:Int = tickers.length;
		while (--ti >= 0)
			tickers[ti](dt);

		if (hoverComp != null && hoverTime >= 0) {
			hoverTime += dt;
			if (hoverTime >= tooltipDelayMs) {
				hoverTime = -1;
				if (onTooltipShow != null && (hoverComp.tooltip != null || hoverComp.tooltipShortcut != null))
					onTooltipShow(hoverComp);
			}
		}

		if (longPressArmed) {
			if (UIPointer.pressTarget == null || UIPointer.captureTarget != null) {
				longPressArmed = false;
			} else {
				pressTime += dt;
				if (pressTime >= longPressMs) {
					longPressArmed = false;
					fireLongPress(UIPointer.pressTarget);
				}
			}
		}
	}

	function fireLongPress(target:UIComponent):Void {
		// steal the press first: the release after a long-press must never also click
		@:privateAccess target.releasePress(false);
		@:privateAccess UIPointer.clearPress();
		if (onLongPress != null)
			onLongPress(target);
		if (target.onRightClick != null || target.longPressable) {
			var local = target.globalToLocal(new openfl.geom.Point(pressStageX, pressStageY));
			@:privateAccess target.onRightPress(local.x, local.y);
			if (target.onRightClick != null)
				target.onRightClick();
		} else if (onTooltipShow != null && (target.tooltip != null || target.tooltipShortcut != null)) {
			hoverComp = target;
			hoverTime = -1;
			onTooltipShow(target);
		}
	}

	function __onAddedToStage(_:Event):Void {
		// the newest staged root becomes the driver of the shared frame systems
		current = this;
		attachedStage = stage;
		lastTimer = Lib.getTimer();
		attachedStage.addEventListener(Event.ENTER_FRAME, __onFrame);
		attachedStage.addEventListener(MouseEvent.MOUSE_DOWN, __onStageMouseDown, true);
		attachedStage.addEventListener(MouseEvent.MOUSE_UP, __onStageMouseUp, true);
		attachedStage.addEventListener(MouseEvent.MOUSE_MOVE, __onStageMouseMove, true);
		// keyboard events TARGET the stage (no focus object), so a capture-phase listener
		// would never fire — listen in the target phase and consume via stopImmediatePropagation
		attachedStage.addEventListener(KeyboardEvent.KEY_DOWN, __onStageKeyDown, false, 100);
	}

	function __onRemovedFromStage(_:Event):Void {
		if (attachedStage == null)
			return;
		attachedStage.removeEventListener(Event.ENTER_FRAME, __onFrame);
		attachedStage.removeEventListener(MouseEvent.MOUSE_DOWN, __onStageMouseDown, true);
		attachedStage.removeEventListener(MouseEvent.MOUSE_UP, __onStageMouseUp, true);
		attachedStage.removeEventListener(MouseEvent.MOUSE_MOVE, __onStageMouseMove, true);
		attachedStage.removeEventListener(KeyboardEvent.KEY_DOWN, __onStageKeyDown, false);
		attachedStage = null;
	}

	function __onStageMouseDown(event:MouseEvent):Void {
		var target:DisplayObject = cast(event.target, DisplayObject);
		var inside:Bool = containsTarget(target);
		if (!inside)
			@:privateAccess UIPointer.clearPress();
		@:privateAccess UIPointer.downOnUI = inside;

		if (longPressEnabled && inside) {
			longPressArmed = true;
			pressStageX = event.stageX;
			pressStageY = event.stageY;
			pressTime = 0;
		}

		var focused:IUIFocusable = UIFocus.focused;
		if (focused != null && focused is UIComponent && !chainContains(target, cast focused))
			UIFocus.clear();

		if (hoverComp != null && onTooltipHide != null) {
			hoverTime = -1;
			onTooltipHide();
		}
	}

	function __onStageMouseUp(_:MouseEvent):Void {
		longPressArmed = false;
		var capture:UIComponent = UIPointer.captureTarget;
		if (capture != null) {
			UIPointer.releaseCapture(capture);
			capture.onDragEnd();
		}
		var press:UIComponent = UIPointer.pressTarget;
		if (press != null)
			press.releasePress(press.hovered);
		@:privateAccess UIPointer.clearPress();
	}

	function __onStageMouseMove(event:MouseEvent):Void {
		@:privateAccess UIPointer.setOverUI(containsTarget(cast(event.target, DisplayObject)));
		if (longPressArmed) {
			var slop:Float = UITheme.px(10) * ((scaleX > 0) ? scaleX : 1.0);
			if (Math.abs(event.stageX - pressStageX) > slop || Math.abs(event.stageY - pressStageY) > slop)
				longPressArmed = false;
		}
		var capture:UIComponent = UIPointer.captureTarget;
		if (capture != null)
			capture.onDragMove(event.stageX, event.stageY);
	}

	function __onStageKeyDown(event:KeyboardEvent):Void {
		if (UIFocus.keyDown(event.keyCode, event.charCode, event.ctrlKey, event.shiftKey, event.altKey)) {
			event.stopImmediatePropagation();
			return;
		}
		if (event.keyCode == 27 && overlayClosers.length > 0) {
			var closer:Void->Void = overlayClosers[overlayClosers.length - 1];
			closer();
			event.stopImmediatePropagation();
		}
	}

	static function chainContains(obj:DisplayObject, ancestor:UIComponent):Bool {
		while (obj != null) {
			if (obj == ancestor)
				return true;
			obj = obj.parent;
		}
		return false;
	}

	/** Full teardown: listeners, layers, statics. Call from the host state's `destroy`. **/
	public function dispose():Void {
		removeEventListener(Event.ADDED_TO_STAGE, __onAddedToStage);
		removeEventListener(Event.REMOVED_FROM_STAGE, __onRemovedFromStage);
		if (parent != null)
			parent.removeChild(this);
		var i:Int = content.numChildren;
		while (--i >= 0) {
			var child = content.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		content.removeChildren();
		popupLayer.removeChildren();
		tooltipLayer.removeChildren();
		UITween.cancelAll();
		UIFocus.clear();
		@:privateAccess UIPointer.clearPress();
		UIPointer.releaseCapture();
		dirty.resize(0);
		dirtySwap.resize(0);
		tickers.resize(0);
		overlayClosers.resize(0);
		longPressArmed = false;
		hoverComp = null;
		onTooltipShow = null;
		onTooltipHide = null;
		if (UITheme.onChanged == invalidateAll)
			UITheme.onChanged = null;
		if (UILocale.onChanged == invalidateAll)
			UILocale.onChanged = null;
		if (current == this)
			current = null;
	}
}
