package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.net.SharedObject;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.types.UIGlyph;
import smidr.widgets.UIButton;
import smidr.widgets.UIIcon;
import smidr.widgets.UILabel;
import smidr.widgets.UIList;
import smidr.widgets.UIPanel;
import smidr.widgets.UITextArea;
import smidr.widgets.UITextInput;
import smidr.widgets.UIDrawer;

/**
	A touch-first notepad for phones (built and shipped for Android, but it runs on any target). It
	is the single-column counterpart to the multi-pane desktop `Notepad`: an app bar with a menu
	button that slides open a `UIDrawer` list of notes, a title field, and the multi-line
	`UITextArea` filling the screen. Tapping the editor raises the soft keyboard through the
	`UIFocus` IME bridge; notes persist in a `SharedObject`. `UITheme.applyMobilePreset()` enlarges
	every control for fingers.

	Build it from the repo root:
	```bash
	lime test examples/notepad-mobile/project.xml android
	lime test examples/notepad-mobile/project.xml windows   # desktop preview (phone-sized window)
	```
**/
class NotepadMobile extends Sprite {
	static inline var APPBAR_H:Float = 64;
	static inline var TITLE_H:Float = 46;
	static inline var PAD:Float = 12;

	var ui:UIRoot;
	var backdrop:UIPanel;
	var appbar:UIPanel;
	var menuButton:UIButton;
	var newButton:UIButton;
	var brand:UILabel;
	var wordLabel:UILabel;
	var titleInput:UITextInput;
	var editor:UITextArea;

	var drawer:UIDrawer;
	var drawerTitle:UILabel;
	var drawerNew:UIButton;
	var list:UIList;

	var notes:Array<{title:String, body:String}> = [];
	var current:Int = 0;
	var store:SharedObject;

	public function new() {
		super();

		UITheme.apply(UITheme.PRESETS[0].palette); // Dark
		UITheme.applyMobilePreset(); // finger-sized controls

		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);

		loadNotes();

		backdrop = new UIPanel(100, 100, BG, false);
		ui.content.addChild(backdrop);

		editor = new UITextArea(100, 100, "");
		editor.fontSize = 15;
		editor.placeholder = "Tap here and start writing...";
		editor.onChange = onBodyChange;
		ui.content.addChild(editor);

		titleInput = new UITextInput("", 100, "", onTitleChange);
		titleInput.fontSize = 16;
		ui.content.addChild(titleInput);

		appbar = new UIPanel(100, APPBAR_H, PANEL2);
		appbar.borderBottom = true;
		ui.content.addChild(appbar);

		menuButton = UIButton.icon(UIIcon.fromGlyph(UIGlyph.MENU, 20), APPBAR_H - 22, openDrawer);
		ui.content.addChild(menuButton);

		brand = new UILabel("Notepad", 17, PRIMARY);
		ui.content.addChild(brand);

		wordLabel = new UILabel("", 12, TERTIARY);
		ui.content.addChild(wordLabel);

		newButton = UIButton.icon(UIIcon.fromGlyph(UIGlyph.PLUS, 20), APPBAR_H - 22, newNote);
		newButton.accent = true;
		ui.content.addChild(newButton);

		buildDrawer();

		refreshList();
		selectNote(current);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			layout();
	}

	function buildDrawer():Void {
		drawer = new UIDrawer(LEFT, 300);
		drawerTitle = new UILabel("Notes", 18, PRIMARY);
		drawerTitle.x = PAD;
		drawerTitle.y = PAD + 6;
		drawer.content.addChild(drawerTitle);

		drawerNew = new UIButton("New note", 130, 40, newNote, true);
		drawerNew.x = PAD;
		drawer.content.addChild(drawerNew);

		list = new UIList(300 - PAD * 2, 100, 40);
		list.x = PAD;
		list.onSelect = onDrawerSelect;
		drawer.content.addChild(list);
	}

	function loadNotes():Void {
		store = SharedObject.getLocal("smidrNotepadMobile");
		var saved:Array<Dynamic> = store.data.notes;
		if (saved != null && saved.length > 0) {
			for (entry in saved)
				notes.push({title: entry.title, body: entry.body});
		} else {
			notes.push({
				title: "Welcome",
				body: "This is the SmiðrUI notepad for phones.\n\n"
					+ "Tap the menu button to switch notes, or the + to add one.\n\n"
					+ "Tap here to raise the keyboard and start typing. Everything is saved as you go."
			});
		}
		current = 0;
	}

	function saveNotes():Void {
		var flat:Array<Dynamic> = [];
		for (note in notes)
			flat.push({title: note.title, body: note.body});
		store.data.notes = flat;
		store.flush();
	}

	function refreshList():Void {
		list.setProvider(notes.length, i -> {
			var title:String = notes[i].title;
			return (title != null && title != "") ? title : "Untitled";
		});
		if (current >= 0 && current < notes.length)
			list.select(current);
	}

	function selectNote(index:Int):Void {
		if (index < 0 || index >= notes.length)
			return;
		current = index;
		titleInput.text = notes[index].title;
		editor.text = notes[index].body;
		brand.text = (notes[index].title != "") ? notes[index].title : "Untitled";
		list.select(index);
		updateWordCount();
		relayoutBrand();
	}

	function onDrawerSelect(index:Int):Void {
		selectNote(index);
		drawer.close();
	}

	function openDrawer():Void {
		drawer.attachEdge();
		drawer.open();
	}

	function newNote():Void {
		notes.push({title: "Untitled", body: ""});
		current = notes.length - 1;
		refreshList();
		selectNote(current);
		saveNotes();
		if (drawer.isOpen)
			drawer.close();
	}

	function onTitleChange(value:String):Void {
		if (current < 0 || current >= notes.length)
			return;
		notes[current].title = value;
		brand.text = (value != "") ? value : "Untitled";
		relayoutBrand();
		refreshList();
		saveNotes();
	}

	function onBodyChange(value:String):Void {
		if (current < 0 || current >= notes.length)
			return;
		notes[current].body = value;
		updateWordCount();
		saveNotes();
	}

	function updateWordCount():Void {
		wordLabel.text = wordCount(editor.text) + " words";
		relayoutBrand();
	}

	function wordCount(text:String):Int {
		var count:Int = 0;
		var inWord:Bool = false;
		for (i in 0...text.length) {
			var code:Int = text.charCodeAt(i);
			var space:Bool = code == 32 || code == 9 || code == 10 || code == 13;
			if (!space && !inWord) {
				count++;
				inWord = true;
			} else if (space) {
				inWord = false;
			}
		}
		return count;
	}

	function onAddedToStage(_:Event):Void {
		stage.addEventListener(Event.RESIZE, onResize);
		layout();
	}

	function onResize(_:Event):Void {
		layout();
	}

	function layout():Void {
		var sw:Float = (stage != null) ? stage.stageWidth : 400;
		var sh:Float = (stage != null) ? stage.stageHeight : 740;

		backdrop.resize(sw, sh);

		appbar.resize(sw, APPBAR_H);
		var btn:Float = APPBAR_H - 22;
		var cy:Float = (APPBAR_H - btn) / 2;
		menuButton.x = PAD;
		menuButton.y = cy;
		newButton.x = sw - PAD - btn;
		newButton.y = cy;

		titleInput.x = PAD;
		titleInput.y = APPBAR_H + PAD;
		titleInput.resize(sw - PAD * 2, TITLE_H);

		editor.x = PAD;
		editor.y = APPBAR_H + PAD + TITLE_H + PAD / 2;
		editor.resize(sw - PAD * 2, sh - editor.y - PAD);

		var headerBottom:Float = PAD + 6 + 30;
		drawerNew.y = headerBottom;
		list.y = headerBottom + 48;
		list.resize(300 - PAD * 2, Math.max(80, sh - list.y - PAD));

		relayoutBrand();
	}

	function relayoutBrand():Void {
		var sw:Float = (stage != null) ? stage.stageWidth : 400;
		brand.measure();
		brand.x = (sw - brand.w) / 2;
		brand.y = (APPBAR_H - brand.h) / 2 - 8;
		wordLabel.measure();
		wordLabel.x = (sw - wordLabel.w) / 2;
		wordLabel.y = brand.y + brand.h + 1;
	}

	/** Call when the screen is torn down. **/
	public function destroy():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			stage.removeEventListener(Event.RESIZE, onResize);
		UITheme.clearMobilePreset();
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
