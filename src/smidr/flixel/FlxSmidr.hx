package smidr.flixel;

#if flixel
import flixel.FlxCamera;
import flixel.FlxG;
import openfl.display.DisplayObject;
import smidr.UIRoot;
import smidr.input.UIFocus;
import smidr.input.UIPointer;
import smidr.types.UICursorMode;

/**
	Optional Flixel bridge (compiled only when the `flixel` haxelib is present).

	Solves the three points of friction between SmiðrUI and a Flixel host:

	- **Viewport** — `init()` parents the `UIRoot` inside `FlxG.game` below the cursor
	  container (Flixel's custom cursor renders above the UI for free): the scale mode's offset
	  comes from the parent and `syncViewport` applies its scale on resize, so UI coordinates
	  equal Flixel game coordinates under every scale mode. `init(false)` stage-attaches
	  instead and syncs both offset and scale on resize.
	- **Cursor** — with a custom `FlxG.mouse` cursor the system cursor is hidden, so widget
	  `hoverCursor`s never show; `cursorMode = CURSOR_SYSTEM_OVER_UI` restores the system
	  cursor while the pointer is over UI, or assign `onOverUIChanged` to swap your own
	  cursor art.
	- **Input arbitration** — `mouseBlocked` / `keysBlocked` are the two flags the game
	  checks before processing its own input; `autoBlockMouse = true` toggles
	  `FlxG.mouse.enabled` automatically instead.

	World-space UI (nameplates, markers) goes through `worldToUIX/Y` or the `anchor()`
	list, which repins display objects to world points each `postUpdate`.
**/
final class FlxSmidr {
	/** The bridged root, or `null` before `init`. **/
	public static var root(default, null):UIRoot = null;

	/** One of `CURSOR_NONE` / `CURSOR_SYSTEM_OVER_UI`. **/
	public static var cursorMode:UICursorMode = CURSOR_NONE;

	/** Fired when the pointer enters/leaves the UI (custom cursor-art swaps). **/
	public static var onOverUIChanged:Bool->Void = null;

	/** When `true`, `FlxG.mouse.enabled` is toggled off while the UI owns the pointer. **/
	public static var autoBlockMouse:Bool = false;

	static var attachedAboveGame:Bool = true;
	static var anchors:Array<FlxSmidrAnchor> = [];
	static var wasOverUI:Bool = false;
	static var savedSystemCursor:Bool = false;
	static var hooked:Bool = false;

	/**
		Creates and attaches the `UIRoot`, hooking the Flixel signals the bridge needs.
		@param aboveGame `true` (recommended) parents the root inside `FlxG.game` below the
		cursor container — UI coordinates equal game coordinates automatically; `false`
		attaches to the stage and syncs `setViewport` from the active scale mode on resize
		(use when `FlxG.game` carries filters/shaders that must not affect the UI)
		@return the created root
	**/
	public static function init(aboveGame:Bool = true):UIRoot {
		if (root != null)
			dispose();
		attachedAboveGame = aboveGame;
		root = new UIRoot();
		if (aboveGame)
			FlxG.addChildBelowMouse(root);
		else
			FlxG.stage.addChild(root);
		syncViewport();
		if (!hooked) {
			hooked = true;
			FlxG.signals.postUpdate.add(onPostUpdate);
			FlxG.signals.gameResized.add(onResized);
			FlxG.cameras.cameraAdded.add(onCameraAdded);
		}
		return root;
	}

	/**
		Keeps an above-game root above the camera layers: Flixel inserts every new camera's
		flash sprite at the input container's index, which lands ON TOP of a root added
		earlier (state camera resets do this too, hiding the whole UI).
	**/
	static function onCameraAdded(_:flixel.FlxCamera):Void {
		if (root == null || !attachedAboveGame || root.parent != FlxG.game)
			return;
		@:privateAccess var inputIdx:Int = FlxG.game.getChildIndex(FlxG.game._inputContainer);
		if (FlxG.game.getChildIndex(root) < inputIdx - 1)
			FlxG.game.setChildIndex(root, inputIdx - 1);
	}

	/** `true` while the game should ignore its own mouse input (pointer owned by the UI). **/
	public static var mouseBlocked(get, never):Bool;

	static inline function get_mouseBlocked():Bool {
		return UIPointer.overUI || UIPointer.downOnUI;
	}

	/** `true` while the game should suppress its keybinds (a widget captures typing). **/
	public static var keysBlocked(get, never):Bool;

	static inline function get_keysBlocked():Bool {
		return UIFocus.typing;
	}

	/**
		Re-syncs the root over the Flixel game viewport from the active scale mode. Called
		automatically on `gameResized` (window resize / fullscreen toggle).

		Both attach modes need this: Flixel's scale modes only OFFSET `FlxG.game` (`game.x/y`)
		and scale each camera's flash sprite internally — the game container itself is never
		scaled, so an above-game root inherits the offset from its parent but must still apply
		the scale itself; a stage-attached root applies both.
	**/
	public static function syncViewport():Void {
		if (root == null)
			return;
		var scale = FlxG.scaleMode.scale;
		if (attachedAboveGame) {
			root.setViewport(0, 0, scale.x, scale.y);
		} else {
			var offset = FlxG.scaleMode.offset;
			root.setViewport(offset.x, offset.y, scale.x, scale.y);
		}
	}

	/**
		Converts a world x coordinate to UI/game space through a camera (assumes the default
		`FlxG.initialZoom == 1` setup; zoom scales around the viewport centre).
		@param worldX the world-space x
		@param camera the camera to project through (`null` = `FlxG.camera`)
		@return the x in UI coordinates
	**/
	public static inline function worldToUIX(worldX:Float, ?camera:FlxCamera):Float {
		var cam:FlxCamera = (camera != null) ? camera : FlxG.camera;
		return cam.x + cam.width * 0.5 + (worldX - cam.scroll.x - cam.width * 0.5) * cam.zoom;
	}

	/**
		Converts a world y coordinate to UI/game space through a camera.
		@param worldY the world-space y
		@param camera the camera to project through (`null` = `FlxG.camera`)
		@return the y in UI coordinates
	**/
	public static inline function worldToUIY(worldY:Float, ?camera:FlxCamera):Float {
		var cam:FlxCamera = (camera != null) ? camera : FlxG.camera;
		return cam.y + cam.height * 0.5 + (worldY - cam.scroll.y - cam.height * 0.5) * cam.zoom;
	}

	/**
		Converts a UI/game x coordinate to world space through a camera (inverse of
		`worldToUIX`; e.g. spawning at a clicked UI position).
		@param uiX the UI-space x
		@param camera the camera to unproject through (`null` = `FlxG.camera`)
		@return the world-space x
	**/
	public static inline function uiToWorldX(uiX:Float, ?camera:FlxCamera):Float {
		var cam:FlxCamera = (camera != null) ? camera : FlxG.camera;
		return cam.scroll.x + cam.width * 0.5 + (uiX - cam.x - cam.width * 0.5) / cam.zoom;
	}

	/**
		Converts a UI/game y coordinate to world space through a camera.
		@param uiY the UI-space y
		@param camera the camera to unproject through (`null` = `FlxG.camera`)
		@return the world-space y
	**/
	public static inline function uiToWorldY(uiY:Float, ?camera:FlxCamera):Float {
		var cam:FlxCamera = (camera != null) ? camera : FlxG.camera;
		return cam.scroll.y + cam.height * 0.5 + (uiY - cam.y - cam.height * 0.5) / cam.zoom;
	}

	/**
		Pins a display object (widget or plain sprite already in the UI tree) to a world
		point; it follows camera scroll/zoom every frame until `unanchor`ed. Re-anchoring
		the same target updates its record in place.
		@param target the display object to reposition
		@param worldX the world-space anchor x
		@param worldY the world-space anchor y
		@param camera the camera to track (`null` = `FlxG.camera`)
		@param offsetX UI-space x offset applied after projection (e.g. `-target.width / 2`)
		@param offsetY UI-space y offset applied after projection
	**/
	public static function anchor(target:DisplayObject, worldX:Float, worldY:Float, ?camera:FlxCamera, offsetX:Float = 0, offsetY:Float = 0):Void {
		var i:Int = anchors.length;
		while (--i >= 0) {
			if (anchors[i].target == target) {
				anchors[i].reuse(worldX, worldY, camera, offsetX, offsetY);
				return;
			}
		}
		anchors.push(new FlxSmidrAnchor(target, worldX, worldY, camera, offsetX, offsetY));
	}

	/**
		Stops tracking an anchored display object (does not remove or dispose it).
		@param target the same object passed to `anchor`
	**/
	public static function unanchor(target:DisplayObject):Void {
		var i:Int = anchors.length;
		while (--i >= 0)
			if (anchors[i].target == target)
				anchors.splice(i, 1);
	}

	static function onPostUpdate():Void {
		var over:Bool = UIPointer.overUI;
		if (over != wasOverUI) {
			wasOverUI = over;
			if (cursorMode == CURSOR_SYSTEM_OVER_UI) {
				if (over) {
					savedSystemCursor = FlxG.mouse.useSystemCursor;
					FlxG.mouse.useSystemCursor = true;
				} else
					FlxG.mouse.useSystemCursor = savedSystemCursor;
			}
			if (onOverUIChanged != null)
				onOverUIChanged(over);
		}
		if (autoBlockMouse)
			FlxG.mouse.enabled = !(over || UIPointer.downOnUI);

		var i:Int = anchors.length;
		while (--i >= 0) {
			var anchor:FlxSmidrAnchor = anchors[i];
			var cam:FlxCamera = (anchor.camera != null) ? anchor.camera : FlxG.camera;
			anchor.target.x = cam.x + cam.width * 0.5 + (anchor.worldX - cam.scroll.x - cam.width * 0.5) * cam.zoom + anchor.offsetX;
			anchor.target.y = cam.y + cam.height * 0.5 + (anchor.worldY - cam.scroll.y - cam.height * 0.5) * cam.zoom + anchor.offsetY;
		}
	}

	static function onResized(_:Int, _:Int):Void {
		syncViewport();
	}

	/**
		Full teardown: unhooks signals, restores mouse state and disposes the root. Call
		from the state's `destroy` (or before re-`init`).
	**/
	public static function dispose():Void {
		if (hooked) {
			hooked = false;
			FlxG.signals.postUpdate.remove(onPostUpdate);
			FlxG.signals.gameResized.remove(onResized);
			FlxG.cameras.cameraAdded.remove(onCameraAdded);
		}
		if (wasOverUI && cursorMode == CURSOR_SYSTEM_OVER_UI)
			FlxG.mouse.useSystemCursor = savedSystemCursor;
		if (autoBlockMouse)
			FlxG.mouse.enabled = true;
		wasOverUI = false;
		anchors.resize(0);
		if (root != null) {
			root.dispose();
			root = null;
		}
	}
}

/** One world-point anchor record (mutable so re-anchoring never reallocates). **/
private final class FlxSmidrAnchor {
	public var target:DisplayObject;
	public var worldX:Float;
	public var worldY:Float;
	public var camera:FlxCamera;
	public var offsetX:Float;
	public var offsetY:Float;

	public function new(target:DisplayObject, worldX:Float, worldY:Float, camera:FlxCamera, offsetX:Float, offsetY:Float) {
		this.target = target;
		reuse(worldX, worldY, camera, offsetX, offsetY);
	}

	/**
		Updates the record in place.
		@param worldX the world-space anchor x
		@param worldY the world-space anchor y
		@param camera the camera to track (`null` = `FlxG.camera`)
		@param offsetX UI-space x offset applied after projection
		@param offsetY UI-space y offset applied after projection
	**/
	public function reuse(worldX:Float, worldY:Float, camera:FlxCamera, offsetX:Float, offsetY:Float):Void {
		this.worldX = worldX;
		this.worldY = worldY;
		this.camera = camera;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}
}
#end
