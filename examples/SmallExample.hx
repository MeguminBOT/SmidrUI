package;

import openfl.display.Sprite;
import smidr.UIRoot;
import smidr.widgets.UIButton;
import smidr.widgets.UIPanel;
import smidr.widgets.UILabel;

/**
	Minimal SmiðrUI example: attach a root, drop a panel with a label and a button.

	This is the smallest thing that draws and reacts to input. No fonts, no theme setup,
	no localization — the library ships working defaults for all of those.

	Wire it up from your OpenFL entry point:
	```haxe
	addChild(new SmallExample());
	```
**/
class SmallExample extends Sprite {
	var ui:UIRoot;

	public function new() {
		super();

		// 1. Create the root and attach it above your content.
		ui = new UIRoot();
		ui.attach(this);

		// 2. A background panel (rounded corner just to show it off).
		var panel = new UIPanel(260, 120, 0xFF1E1E21);
		panel.x = 40;
		panel.y = 40;
		panel.corner = 10;
		ui.content.addChild(panel);

		// 3. A label — tone 0 = primary text (see UITheme.text / text2 / text3).
		var title = new UILabel("Hello, SmiðrUI", 15, 0);
		title.x = 60;
		title.y = 60;
		ui.content.addChild(title);

		// 4. A primary-action button. The 5th arg (accent) paints it in the accent color.
		var count = 0;
		var btn = new UIButton("Clicked 0 times", 180, 34, null, true);
		btn.x = 60;
		btn.y = 100;
		btn.onClick = () -> {
			count++;
			btn.label = 'Clicked $count times';
		};
		ui.content.addChild(btn);
	}

	/** Call when the screen is torn down — removes listeners and frees the tree. **/
	public function destroy():Void {
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
