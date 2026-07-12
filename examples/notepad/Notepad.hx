package;

import openfl.display.Sprite;
import openfl.events.Event;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.UITween;
import smidr.input.UIFocus;
import smidr.overlays.UIContextMenu;
import smidr.overlays.UIToast;
import smidr.text.UIMarkdown;
import smidr.text.UIRichStyler;
import smidr.text.UITextStyle;
import smidr.types.UIGlyph;
import smidr.types.UIMenuItem;
import smidr.widgets.UIButton;
import smidr.widgets.UIColorPicker;
import smidr.widgets.UIDropdown;
import smidr.widgets.UILabel;
import smidr.widgets.UIModal;
import smidr.widgets.UIPanel;
import smidr.widgets.UIStatusBar;
import smidr.widgets.UIStepper;
import smidr.widgets.UITextArea;
import smidr.widgets.UITextInput;
import smidr.widgets.UIToolbar;
import smidr.widgets.UITreeView;
import smidr.widgets.UITreeView.UITreeNode;
import notepad.Folder;
import notepad.Note;
import notepad.NoteStore;
#if sys
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import sys.io.File;
#end

/**
	A desktop notepad built with SmiðrUI: a WYSIWYG rich-text editor (the `UITextArea` widget with a
	`UIRichStyler` installed), a folder tree with search, per-note pin / important flags, right-click
	context menus, an options screen, created/modified timestamps, and native file open/save. Notes
	persist to `<documents>/SmidrNotes/notes.json`. It shows how the generic editor widget stays
	free of note-app logic: all rich-text policy lives in the `smidr.text` modules, all note/folder
	logic in the `notepad` package.

	Build it from the repo root:
	```bash
	lime test examples/notepad/project.xml windows
	```
**/
class Notepad extends Sprite {
	static inline var ACTION_H:Float = 40;
	static inline var FORMAT_H:Float = 38;
	static inline var STATUS_H:Float = 26;
	static inline var SIDEBAR_W:Float = 252;
	static inline var SEARCH_H:Float = 30;
	static inline var TITLE_H:Float = 30;
	static inline var PAD:Float = 10;

	var ui:UIRoot;
	var backdrop:UIPanel;
	var sidebar:UIPanel;
	var actionBar:UIToolbar;
	var formatBar:UIToolbar;
	var searchInput:UITextInput;
	var tree:UITreeView;
	var titleInput:UITextInput;
	var editor:UITextArea;
	var status:UIStatusBar;

	var styler:UIRichStyler;
	var store:NoteStore;
	var current:Note;
	var selectedFolder:Int = -1;
	var searchQuery:String = "";

	// format toolbar controls (their state mirrors the caret's style)
	var paragraphDropdown:UIDropdown;
	var sizeDropdown:UIDropdown;
	var buttonBold:UIButton;
	var buttonItalic:UIButton;
	var buttonUnderline:UIButton;
	var buttonBullet:UIButton;
	var buttonNumber:UIButton;

	static final FONT_SIZES:Array<Int> = [8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24, 28, 32, 40, 48];
	static final PARAGRAPH_BLOCKS:Array<Int> = [
		UITextStyle.BLOCK_NORMAL,
		UITextStyle.BLOCK_H1,
		UITextStyle.BLOCK_H2,
		UITextStyle.BLOCK_H3
	];
	static final COLOUR_NAMES:Array<String> = ["Default text", "Red", "Amber", "Green", "Blue", "Purple", "White", "Grey"];

	var saveDirty:Bool = false;
	var saveAccum:Float = 0;

	public function new() {
		super();

		store = NoteStore.load();
		UITheme.apply(UITheme.PRESETS[clampPreset(store.options.themeIndex)].palette);
		if (store.options.accent != 0)
			UITheme.applyAccent(store.options.accent);

		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);

		styler = new UIRichStyler();

		backdrop = new UIPanel(100, 100, BG, false);
		ui.content.addChild(backdrop);

		sidebar = new UIPanel(SIDEBAR_W, 100, PANEL);
		sidebar.borderRight = true;
		ui.content.addChild(sidebar);

		buildActionBar();
		buildFormatBar();

		searchInput = new UITextInput("", 100, "", onSearch);
		searchInput.fontSize = 13;
		ui.content.addChild(searchInput);

		tree = new UITreeView(100, 100, 26);
		tree.onSelect = onTreeSelect;
		tree.onActivate = onTreeActivate;
		tree.onNodeRightClick = onNodeMenu;
		ui.content.addChild(tree);

		titleInput = new UITextInput("", 100, "", onTitleChange);
		titleInput.fontSize = 15;
		ui.content.addChild(titleInput);

		editor = new UITextArea(100, 100, "");
		editor.styler = styler;
		editor.placeholder = "Start writing. Use the toolbar to format.";
		editor.onChange = onBodyChange;
		editor.onCaretMove = onCaretMove;
		editor.onRightClick = onEditorMenu;
		ui.content.addChild(editor);

		status = new UIStatusBar(100, STATUS_H);
		status.setCells([
			{text: "Ln 1, Col 1"},
			{text: "0 words"},
			{text: "", rightAlign: true, tone: TERTIARY},
			{text: "", rightAlign: true, tone: TERTIARY}
		]);
		ui.content.addChild(status);

		refreshTree();
		openNote(store.notes[0]);

		UIRoot.addTicker(saveTick);
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			layout();
	}

	inline function clampPreset(index:Int):Int {
		return (index >= 0 && index < UITheme.PRESETS.length) ? index : 0;
	}

	function buildActionBar():Void {
		actionBar = new UIToolbar(ACTION_H);
		actionBar.addButton("New note", 92, newNote).accent = true;
		actionBar.addButton("New folder", 96, newFolder);
		actionBar.addSeparator();
		actionBar.addButton("Open", 60, openFile);
		actionBar.addButton("Save As", 74, saveAsFile);
		actionBar.addSpacer();
		actionBar.addButton("Options", 78, openOptions);
		ui.content.addChild(actionBar);
	}

	function buildFormatBar():Void {
		formatBar = new UIToolbar(FORMAT_H);

		// paragraph style (Normal / Heading 1-3), Google-Docs style
		paragraphDropdown = new UIDropdown("", 132, (index, _) -> applyParagraph(index));
		paragraphDropdown.controlWidth = 132;
		paragraphDropdown.setItems(["Normal text", "Heading 1", "Heading 2", "Heading 3"]);
		formatBar.addWidget(paragraphDropdown, 132);
		formatBar.addSeparator();

		// font size: minus / a size picker / plus
		formatBar.addButton("-", 26, () -> stepFontSize(-1));
		sizeDropdown = new UIDropdown("", 52, (_, value) -> {
			var points:Null<Int> = Std.parseInt(value);
			if (points != null)
				applyFontSize(points);
		});
		sizeDropdown.controlWidth = 52;
		sizeDropdown.setItems([for (size in FONT_SIZES) "" + size]);
		formatBar.addWidget(sizeDropdown, 52);
		formatBar.addButton("+", 26, () -> stepFontSize(1));
		formatBar.addSeparator();

		buttonBold = formatBar.addButton("B", 30, () -> toggleInline(UITextStyle.BOLD));
		buttonItalic = formatBar.addButton("I", 30, () -> toggleInline(UITextStyle.ITALIC));
		buttonUnderline = formatBar.addButton("U", 30, () -> toggleInline(UITextStyle.UNDERLINE));
		formatBar.addButton("A", 30, openColourMenu);
		formatBar.addSeparator();

		buttonBullet = formatBar.addButton("• List", 56, () -> toggleBlock(UITextStyle.BLOCK_BULLET));
		buttonNumber = formatBar.addButton("1. List", 60, () -> toggleBlock(UITextStyle.BLOCK_NUMBER));
		formatBar.addSeparator();
		formatBar.addButton("Clear", 54, clearFormatting);
		ui.content.addChild(formatBar);
	}

	// formatting: drive the editor's generic style API through the WYSIWYG module, then refocus

	function applyParagraph(index:Int):Void {
		if (index >= 0 && index < PARAGRAPH_BLOCKS.length)
			UIRichStyler.setBlock(editor, PARAGRAPH_BLOCKS[index]);
		focusEditor();
	}

	function applyFontSize(points:Int):Void {
		if (points > 0)
			UIRichStyler.setFontSize(editor, points);
		focusEditor();
	}

	function stepFontSize(direction:Int):Void {
		var current:Int = currentFontSize();
		var index:Int = nearestSizeIndex(current) + direction;
		if (index < 0)
			index = 0;
		if (index >= FONT_SIZES.length)
			index = FONT_SIZES.length - 1;
		UIRichStyler.setFontSize(editor, FONT_SIZES[index]);
		focusEditor();
	}

	function toggleInline(flag:Int):Void {
		UIRichStyler.toggleInline(editor, flag);
		focusEditor();
	}

	function toggleBlock(blockType:Int):Void {
		var currentBlock:Int = UIRichStyler.blockAt(editor);
		UIRichStyler.setBlock(editor, currentBlock == blockType ? UITextStyle.BLOCK_NORMAL : blockType);
		focusEditor();
	}

	function openColourMenu():Void {
		if (stage == null)
			return;
		var items:Array<UIMenuItem> = [];
		for (index in 0...COLOUR_NAMES.length) {
			var colourIndex:Int = index;
			items.push({label: COLOUR_NAMES[index], onSelect: () -> {
				UIRichStyler.setColor(editor, colourIndex);
				focusEditor();
			}});
		}
		UIContextMenu.open(stage.mouseX, stage.mouseY, items);
	}

	function clearFormatting():Void {
		UIRichStyler.clearFormatting(editor);
		focusEditor();
	}

	inline function currentFontSize():Int {
		var explicit:Int = UIRichStyler.fontSizeAt(editor);
		return (explicit > 0) ? explicit : editor.fontSize;
	}

	function nearestSizeIndex(points:Int):Int {
		var best:Int = 0;
		var bestDelta:Int = 1 << 30;
		for (i in 0...FONT_SIZES.length) {
			var delta:Int = Std.int(Math.abs(FONT_SIZES[i] - points));
			if (delta < bestDelta) {
				bestDelta = delta;
				best = i;
			}
		}
		return best;
	}

	inline function focusEditor():Void {
		UIFocus.set(editor);
		updateFormatButtons();
	}

	function updateFormatButtons():Void {
		var inlineFlags:Int = UIRichStyler.inlineAt(editor);
		buttonBold.accent = UITextStyle.has(inlineFlags, UITextStyle.BOLD);
		buttonItalic.accent = UITextStyle.has(inlineFlags, UITextStyle.ITALIC);
		buttonUnderline.accent = UITextStyle.has(inlineFlags, UITextStyle.UNDERLINE);
		var block:Int = UIRichStyler.blockAt(editor);
		buttonBullet.accent = block == UITextStyle.BLOCK_BULLET;
		buttonNumber.accent = block == UITextStyle.BLOCK_NUMBER;
		paragraphDropdown.select(paragraphIndexOf(block));
		sizeDropdown.select(nearestSizeIndex(currentFontSize()));
	}

	inline function paragraphIndexOf(block:Int):Int {
		var index:Int = PARAGRAPH_BLOCKS.indexOf(block);
		return (index >= 0) ? index : 0;
	}

	// note lifecycle

	function openNote(note:Note):Void {
		if (note == null)
			return;
		current = note;
		selectedFolder = note.folderId;
		titleInput.text = note.title;
		editor.setRich(note.text, note.styles);
		updateStatus();
		updateFormatButtons();
		selectCurrentInTree();
		// fade the new note in on alpha only; layout owns the editor's position
		editor.alpha = 0;
		UITween.to((value) -> editor.alpha = value, 0, 1, 140, OUT_QUAD);
	}

	function newNote():Void {
		if (!store.canAddNote()) {
			UIToast.show("Note limit reached (see Options)");
			return;
		}
		var note:Note = store.newNote(selectedFolder);
		refreshTree();
		openNote(note);
		requestSave();
		UIFocus.set(titleInput);
	}

	function newFolder():Void {
		prompt("New folder", "Folder", (name) -> {
			store.newFolder(name, selectedFolder);
			refreshTree();
			requestSave();
		});
	}

	function onTitleChange(value:String):Void {
		if (current == null)
			return;
		current.title = value;
		current.touch();
		refreshTree();
		requestSave();
	}

	function onBodyChange(value:String):Void {
		if (current == null)
			return;
		current.text = value;
		current.styles = editor.getStyleData();
		current.touch();
		updateStatus();
		requestSave();
	}

	function onCaretMove():Void {
		updateStatus();
		updateFormatButtons();
	}

	// tree

	function refreshTree():Void {
		if (searchQuery != "") {
			buildSearchResults();
			return;
		}
		var roots:Array<UITreeNode> = [];
		for (folder in foldersIn(-1))
			roots.push(folderNode(folder));
		for (note in notesIn(-1))
			roots.push(noteNode(note));
		tree.setRoots(roots);
		selectCurrentInTree();
	}

	function buildSearchResults():Void {
		var roots:Array<UITreeNode> = [];
		for (note in store.notes)
			if (matches(note, searchQuery))
				roots.push(noteNode(note));
		tree.setRoots(roots);
	}

	function matches(note:Note, query:String):Bool {
		if (note.title.toLowerCase().indexOf(query) >= 0)
			return true;
		if (note.text.toLowerCase().indexOf(query) >= 0)
			return true;
		return formatDate(note.modified).indexOf(query) >= 0 || formatDate(note.created).indexOf(query) >= 0;
	}

	function foldersIn(parentId:Int):Array<Folder> {
		var list:Array<Folder> = [];
		for (folder in store.folders)
			if (folder.parentId == parentId)
				list.push(folder);
		list.sort((a, b) -> compareText(a.name, b.name));
		return list;
	}

	function notesIn(folderId:Int):Array<Note> {
		var list:Array<Note> = [];
		for (note in store.notes)
			if (note.folderId == folderId)
				list.push(note);
		list.sort(function(a:Note, b:Note):Int {
			if (a.pinned != b.pinned)
				return a.pinned ? -1 : 1;
			return (b.modified > a.modified) ? 1 : (b.modified < a.modified ? -1 : 0);
		});
		return list;
	}

	inline function compareText(a:String, b:String):Int {
		var la:String = a.toLowerCase();
		var lb:String = b.toLowerCase();
		return (la < lb) ? -1 : (la > lb ? 1 : 0);
	}

	function folderNode(folder:Folder):UITreeNode {
		var node:UITreeNode = new UITreeNode(folder.name, null, true);
		node.data = folder;
		for (sub in foldersIn(folder.id))
			node.add(folderNode(sub));
		for (note in notesIn(folder.id))
			node.add(noteNode(note));
		return node;
	}

	function noteNode(note:Note):UITreeNode {
		var node:UITreeNode = new UITreeNode(note.title != "" ? note.title : "Untitled");
		node.data = note;
		var icons:Array<UIGlyph> = [];
		if (note.pinned)
			icons.push(UIGlyph.PIN);
		if (note.important)
			icons.push(UIGlyph.LOCK);
		if (icons.length > 0)
			node.icons = icons;
		return node;
	}

	function selectCurrentInTree():Void {
		// leave selection to the user; the tree rebinds labels on refresh
	}

	function onTreeSelect(node:UITreeNode):Void {
		if (node == null)
			return;
		if (Std.isOfType(node.data, Note)) {
			var note:Note = cast node.data;
			selectedFolder = note.folderId;
			if (note != current)
				openNote(note);
		} else if (Std.isOfType(node.data, Folder)) {
			selectedFolder = (cast node.data : Folder).id;
		}
	}

	function onTreeActivate(node:UITreeNode):Void {
		if (node != null && Std.isOfType(node.data, Note))
			openNote(cast node.data);
	}

	// context menus

	function onNodeMenu(node:UITreeNode, x:Float, y:Float):Void {
		if (Std.isOfType(node.data, Note))
			noteMenu(cast node.data, x, y);
		else if (Std.isOfType(node.data, Folder))
			folderMenu(cast node.data, x, y);
	}

	function noteMenu(note:Note, x:Float, y:Float):Void {
		var items:Array<UIMenuItem> = [
			{label: "Open", onSelect: () -> openNote(note)},
			{label: "Rename", onSelect: () -> renameNote(note)},
			{
				label: note.pinned ? "Unpin" : "Pin to top",
				onSelect: () -> {
					note.pinned = !note.pinned;
					refreshTree();
					requestSave();
				}
			},
			{
				label: note.important ? "Clear important" : "Mark important",
				onSelect: () -> {
					note.important = !note.important;
					refreshTree();
					requestSave();
				}
			},
			{label: "Move to folder...", onSelect: () -> moveMenu(note, x, y)},
			{label: "Export as Markdown...", onSelect: () -> exportNote(note)},
			{separator: true},
			{label: "Delete", disabled: note.important, onSelect: () -> deleteNote(note)}
		];
		UIContextMenu.open(x, y, items);
	}

	function folderMenu(folder:Folder, x:Float, y:Float):Void {
		var items:Array<UIMenuItem> = [
			{
				label: "New note here",
				onSelect: () -> {
					selectedFolder = folder.id;
					newNote();
				}
			},
			{
				label: "New subfolder",
				onSelect: () -> prompt("New subfolder", "Folder", (name) -> {
					store.newFolder(name, folder.id);
					refreshTree();
					requestSave();
				})
			},
			{label: "Rename", onSelect: () -> renameFolder(folder)},
			{separator: true},
			{
				label: "Delete folder",
				onSelect: () -> {
					store.deleteFolder(folder);
					refreshTree();
					requestSave();
					UIToast.show("Folder deleted (notes kept)");
				}
			}
		];
		UIContextMenu.open(x, y, items);
	}

	function moveMenu(note:Note, x:Float, y:Float):Void {
		var items:Array<UIMenuItem> = [
			{
				label: "(Root)",
				onSelect: () -> {
					note.folderId = -1;
					refreshTree();
					requestSave();
				}
			}
		];
		for (folder in store.folders) {
			var target:Folder = folder;
			items.push({
				label: folder.name,
				onSelect: () -> {
					note.folderId = target.id;
					refreshTree();
					requestSave();
				}
			});
		}
		UIContextMenu.open(x, y, items);
	}

	function deleteNote(note:Note):Void {
		if (note.important) {
			UIToast.show("Protected: clear 'important' first");
			return;
		}
		store.deleteNote(note);
		if (current == note)
			openNote(store.notes.length > 0 ? store.notes[0] : store.newNote(-1));
		refreshTree();
		requestSave();
		UIToast.show("Note deleted");
	}

	function renameNote(note:Note):Void {
		prompt("Rename note", note.title, (name) -> {
			note.title = name;
			note.touch();
			if (current == note)
				titleInput.text = name;
			refreshTree();
			requestSave();
		});
	}

	function renameFolder(folder:Folder):Void {
		prompt("Rename folder", folder.name, (name) -> {
			folder.name = name;
			refreshTree();
			requestSave();
		});
	}

	function onEditorMenu():Void {
		if (stage == null)
			return;
		var x:Float = stage.mouseX;
		var y:Float = stage.mouseY;
		var items:Array<UIMenuItem> = [
			{label: "Cut", shortcut: "Ctrl+X", onSelect: () -> sendKey(88)},
			{label: "Copy", shortcut: "Ctrl+C", onSelect: () -> sendKey(67)},
			{label: "Paste", shortcut: "Ctrl+V", onSelect: () -> sendKey(86)},
			{separator: true},
			{label: "Select all", shortcut: "Ctrl+A", onSelect: () -> sendKey(65)},
			{separator: true},
			{label: "Bold", onSelect: () -> toggleInline(UITextStyle.BOLD)},
			{label: "Italic", onSelect: () -> toggleInline(UITextStyle.ITALIC)}
		];
		UIContextMenu.open(x, y, items);
	}

	function sendKey(keyCode:Int):Void {
		UIFocus.set(editor);
		editor.onKeyDown(keyCode, 0, true, false, false);
	}

	// files

	function openFile():Void {
		#if sys
		var dialog:FileDialog = new FileDialog();
		dialog.onSelect.add((path:String) -> {
			if (path == null)
				return;
			try {
				var md:String = File.getContent(path);
				var note:Note = store.newNote(selectedFolder);
				note.title = fileTitle(path);
				var doc = UIMarkdown.parse(md);
				note.text = doc.text;
				note.styles = doc.styles;
				refreshTree();
				openNote(note);
				requestSave();
			} catch (e:Dynamic) {
				UIToast.show("Could not open file");
			}
		});
		dialog.browse(FileDialogType.OPEN, "md,txt", null, "Open a note");
		#else
		UIToast.show("File dialogs need a desktop build");
		#end
	}

	function saveAsFile():Void {
		exportNote(current);
	}

	function exportNote(note:Note):Void {
		if (note == null)
			return;
		#if sys
		var markdown:String = (note == current) ? UIMarkdown.toMarkdown(editor.text, editor.getStyleData()) : UIMarkdown.toMarkdown(note.text, note.styles);
		var dialog:FileDialog = new FileDialog();
		dialog.onSelect.add((path:String) -> {
			if (path == null)
				return;
			try {
				File.saveContent(path, markdown);
				UIToast.show("Saved to " + fileTitle(path));
			} catch (e:Dynamic) {
				UIToast.show("Could not save file");
			}
		});
		dialog.browse(FileDialogType.SAVE, "md", (note.title != "" ? note.title : "note") + ".md", "Export as Markdown");
		#else
		UIToast.show("File dialogs need a desktop build");
		#end
	}

	inline function fileTitle(path:String):String {
		return haxe.io.Path.withoutDirectory(path);
	}

	// options

	function openOptions():Void {
		var modal:UIModal = new UIModal("Options", 380, 372);
		var y:Float = 8;

		addBodyLabel(modal, "Accent colour", y);
		y += 22;
		var picker:UIColorPicker = new UIColorPicker(336, UITheme.accent, (color) -> {
			store.options.accent = color;
			UITheme.applyAccent(color);
		});
		picker.x = 20;
		picker.y = y;
		modal.body.addChild(picker);
		y += 150;

		var maxNotes:UIStepper = new UIStepper("Max notes (0 = unlimited)", 336, store.options.maxNotes, 10, (value) -> store.options.maxNotes = Std.int(value));
		maxNotes.min = 0;
		maxNotes.max = 100000;
		maxNotes.x = 20;
		maxNotes.y = y;
		modal.body.addChild(maxNotes);
		y += 40;

		addBodyLabel(modal, "Theme", y);
		y += 22;
		var themeX:Float = 20;
		for (index in 0...UITheme.PRESETS.length) {
			var presetIndex:Int = index;
			var themeButton:UIButton = new UIButton(UITheme.PRESETS[index].name, 78, 30, () -> {
				store.options.themeIndex = presetIndex;
				UITheme.apply(UITheme.PRESETS[presetIndex].palette);
				if (store.options.accent != 0)
					UITheme.applyAccent(store.options.accent);
			});
			themeButton.x = themeX;
			themeButton.y = y;
			modal.body.addChild(themeButton);
			themeX += 84;
		}
		y += 40;

		var folderButton:UIButton = new UIButton("Change save folder...", 200, 30, chooseSaveFolder);
		folderButton.x = 20;
		folderButton.y = y;
		modal.body.addChild(folderButton);

		modal.onClosed = () -> requestSave();
		modal.open();
	}

	function addBodyLabel(modal:UIModal, text:String, y:Float):Void {
		var label:UILabel = new UILabel(text, 13, SECONDARY);
		label.x = 20;
		label.y = y;
		modal.body.addChild(label);
	}

	function chooseSaveFolder():Void {
		#if sys
		var dialog:FileDialog = new FileDialog();
		dialog.onSelect.add((path:String) -> {
			if (path == null)
				return;
			store.options.saveDir = path;
			store.save();
			UIToast.show("Saving notes to " + path);
		});
		dialog.browse(FileDialogType.OPEN_DIRECTORY, null, null, "Choose a notes folder");
		#else
		UIToast.show("Folder picker needs a desktop build");
		#end
	}

	// a small text-prompt modal (rename / new folder)

	function prompt(title:String, initial:String, onOk:String->Void):Void {
		var modal:UIModal = new UIModal(title, 320, 132);
		var input:UITextInput = new UITextInput("", 280, initial);
		input.x = 20;
		input.y = 10;
		modal.body.addChild(input);
		var ok:UIButton = new UIButton("OK", 90, 32, () -> {
			var value:String = StringTools.trim(input.text);
			if (value != "")
				onOk(value);
			modal.close();
		}, true);
		ok.x = 190;
		ok.y = 54;
		modal.body.addChild(ok);
		var cancel:UIButton = new UIButton("Cancel", 80, 32, () -> modal.close());
		cancel.x = 100;
		cancel.y = 54;
		modal.body.addChild(cancel);
		modal.open();
		UIFocus.set(input);
	}

	// status + persistence

	function updateStatus():Void {
		var body:String = editor.text;
		var caret:Int = editor.caretIndex;
		var line:Int = 1;
		var lineStart:Int = 0;
		var i:Int = 0;
		while (i < caret && i < body.length) {
			if (body.charCodeAt(i) == 10) {
				line++;
				lineStart = i + 1;
			}
			i++;
		}
		status.setText(0, "Ln " + line + ", Col " + (caret - lineStart + 1));
		status.setText(1, wordCount(body) + " words");
		if (current != null) {
			status.setText(2, "Edited " + formatDate(current.modified));
			status.setText(3, "Created " + formatDate(current.created));
		}
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

	function formatDate(ms:Float):String {
		var date:Date = Date.fromTime(ms);
		return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) + " " + pad2(date.getHours()) + ":" + pad2(date.getMinutes());
	}

	inline function pad2(value:Int):String {
		return (value < 10) ? "0" + value : "" + value;
	}

	function onSearch(query:String):Void {
		searchQuery = StringTools.trim(query).toLowerCase();
		refreshTree();
	}

	inline function requestSave():Void {
		saveDirty = true;
	}

	function saveTick(dt:Float):Void {
		if (!saveDirty)
			return;
		saveAccum += dt;
		if (saveAccum >= 700) {
			saveAccum = 0;
			saveDirty = false;
			store.save();
		}
	}

	// responsive layout

	function onAddedToStage(_:Event):Void {
		stage.addEventListener(Event.RESIZE, onResize);
		layout();
	}

	function onResize(_:Event):Void {
		layout();
	}

	function layout():Void {
		var sw:Float = (stage != null) ? stage.stageWidth : 1000;
		var sh:Float = (stage != null) ? stage.stageHeight : 640;
		var top:Float = ACTION_H + FORMAT_H;
		var bodyH:Float = sh - top - STATUS_H;

		backdrop.resize(sw, sh);
		actionBar.resize(sw, ACTION_H);
		formatBar.y = ACTION_H;
		formatBar.resize(sw, FORMAT_H);

		sidebar.y = top;
		sidebar.resize(SIDEBAR_W, bodyH);

		searchInput.x = PAD / 2 + 4;
		searchInput.y = top + PAD / 2;
		searchInput.resize(SIDEBAR_W - PAD - 8, SEARCH_H);

		tree.x = 4;
		tree.y = top + PAD / 2 + SEARCH_H + 6;
		tree.resize(SIDEBAR_W - 8, Math.max(80, sh - tree.y - STATUS_H - PAD / 2));

		var editorX:Float = SIDEBAR_W + PAD;
		var editorW:Float = sw - editorX - PAD;
		titleInput.x = editorX;
		titleInput.y = top + PAD;
		titleInput.resize(editorW, TITLE_H);

		editor.x = editorX;
		editor.y = top + PAD + TITLE_H + PAD / 2;
		editor.resize(editorW, sh - editor.y - STATUS_H - PAD);

		status.y = sh - STATUS_H;
		status.resize(sw, STATUS_H);
	}

	/** Call when the screen is torn down. **/
	public function destroy():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			stage.removeEventListener(Event.RESIZE, onResize);
		UIRoot.removeTicker(saveTick);
		store.save();
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
