package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import smidr.flixel.FlxSmidr;
import smidr.types.UICursorMode;
import smidr.widgets.UIButton;
import smidr.widgets.UILabel;
import smidr.widgets.UIPanel;
import smidr.widgets.UISlider;
import smidr.widgets.UITooltip;

/**
	SmiðrUI on a HaxeFlixel state. The `smidr.flixel.FlxSmidr` bridge is compiled only
	when the `flixel` haxelib is present, and it solves the three friction points with a
	Flixel host: viewport matching, custom-cursor handling, and input arbitration.

	Add to your project.xml so the bridge compiles:
	```xml
	<haxelib name="smidr" />
	<haxelib name="flixel" />
	```
**/
class FlixelExample extends FlxState {
	// A HUD element pinned to a moving world object.
	var marker:UILabel;
	var enemy:FlxSprite;

	override public function create():Void {
		super.create();

		// A little world content to anchor UI against.
		enemy = new FlxSprite(400, 300).makeGraphic(48, 48, 0xFFF05C7C);
		add(enemy);

		// ── Bridge init ──────────────────────────────────────────────────────
		// aboveGame = true (default) parents the UIRoot inside FlxG.game below the
		// cursor container: UI coordinates == game coordinates under every scale mode,
		// with zero per-frame viewport syncing, and Flixel's custom cursor draws on top.
		FlxSmidr.init(true);

		// With a custom FlxG.mouse cursor the system cursor is hidden, so widget
		// hover cursors wouldn't show. Restore the system cursor while over the UI:
		FlxSmidr.cursorMode = CURSOR_SYSTEM_OVER_UI;

		// Let the bridge disable FlxG.mouse while the pointer is over the UI, so a
		// click on a button never also fires a click in the game world.
		FlxSmidr.autoBlockMouse = true;

		// Tooltips need installing once, after a root exists (FlxSmidr.init made one).
		UITooltip.install();

		buildHud();

		// A world-space label that follows the enemy every frame (accounts for camera
		// scroll + zoom). offsetX/Y are applied in UI space after projection.
		marker = new UILabel("Enemy", 12, 0);
		FlxSmidr.root.content.addChild(marker);
		FlxSmidr.anchor(marker, enemy.x + enemy.width / 2, enemy.y, null, -marker.measure() / 2, -18);
	}

	function buildHud():Void {
		var root = FlxSmidr.root;

		var panel = new UIPanel(220, 96, 0xE61E1E21);
		panel.x = 12;
		panel.y = 12;
		panel.corner = 8;
		panel.outline = true;
		root.content.addChild(panel);

		var title = new UILabel("HUD", 14, 0);
		title.x = 28;
		title.y = 24;
		root.content.addChild(title);

		var zoom = new UISlider("Camera zoom", 180, 0.5, 2, FlxG.camera.zoom, (v) -> FlxG.camera.zoom = v);
		zoom.decimals = 2;
		zoom.x = 28;
		zoom.y = 48;
		root.content.addChild(zoom);

		var shake = new UIButton("Shake", 84, 26, () -> FlxG.camera.shake(0.01, 0.3), true);
		shake.x = 28;
		shake.y = 76;
		root.content.addChild(shake);
	}

	override public function update(elapsed:Float):Void {
		// Move the world object so the anchored marker visibly tracks it.
		enemy.x = 400 + Math.cos(FlxG.game.ticks / 600) * 120;

		// If your state reads FlxG.mouse directly for gameplay, gate it on the bridge
		// so UI clicks/typing don't leak into the game. (autoBlockMouse already covers
		// FlxG.mouse.enabled; these flags are for hand-rolled input.)
		if (!FlxSmidr.mouseBlocked && FlxG.mouse.justPressed) {
			// world click handling here…
		}
		if (!FlxSmidr.keysBlocked && FlxG.keys.justPressed.SPACE) {
			// gameplay keybind here…
		}

		super.update(elapsed);
	}

	override public function destroy():Void {
		// Full teardown: unhooks Flixel signals, restores the mouse and disposes the root.
		FlxSmidr.dispose();
		super.destroy();
	}
}
