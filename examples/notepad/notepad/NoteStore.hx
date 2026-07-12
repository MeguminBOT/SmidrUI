package notepad;

import haxe.Json;
import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if html5
import openfl.net.SharedObject;
#end

/**
	The notepad workspace: all notes, folders and options, with JSON persistence. On native targets
	it reads/writes `<documents>/SmidrNotes/notes.json` (or the user's chosen `saveDir`) via
	`sys.io.File`; on web it falls back to a `SharedObject`. Single-file import/export of the current
	note as Markdown is handled by the app through `lime.ui.FileDialog` and the widget's
	`toMarkdown`/`fromMarkdown`.
**/
class NoteStore {
	public var notes:Array<Note> = [];
	public var folders:Array<Folder> = [];
	public var options:Options = new Options();

	var nextNoteId:Int = 1;
	var nextFolderId:Int = 1;

	public function new() {}

	/** The notes directory (the chosen `saveDir`, else `<documents>/SmidrNotes`). **/
	public function dir():String {
		if (options.saveDir != null && options.saveDir != "")
			return options.saveDir;
		#if sys
		return Path.join([lime.system.System.documentsDirectory, "SmidrNotes"]);
		#else
		return "SmidrNotes";
		#end
	}

	public function filePath():String {
		return Path.join([dir(), "notes.json"]);
	}

	/** Loads the workspace from disk (or the SharedObject on web), seeding a welcome note if empty. **/
	public static function load():NoteStore {
		var store = new NoteStore();
		var json:String = null;
		#if sys
		try {
			if (FileSystem.exists(store.filePath()))
				json = File.getContent(store.filePath());
		} catch (e:Dynamic) {}
		#elseif html5
		var shared = SharedObject.getLocal("smidrNotepadWorkspace");
		json = shared.data.json;
		#end
		if (json != null)
			store.parse(json);
		if (store.notes.length == 0)
			store.seed();
		return store;
	}

	function parse(json:String):Void {
		try {
			var data:Dynamic = Json.parse(json);
			if (data.folders != null)
				for (f in (data.folders : Array<Dynamic>))
					folders.push(Folder.fromStruct(f));
			if (data.notes != null)
				for (n in (data.notes : Array<Dynamic>))
					notes.push(Note.fromStruct(n));
			if (data.options != null)
				options = Options.fromStruct(data.options);
			if (data.nextNoteId != null)
				nextNoteId = Std.int(data.nextNoteId);
			if (data.nextFolderId != null)
				nextFolderId = Std.int(data.nextFolderId);
		} catch (e:Dynamic) {}
	}

	/** Writes the workspace to disk (or the SharedObject on web). **/
	public function save():Void {
		var struct = {
			notes: [for (n in notes) n.toStruct()],
			folders: [for (f in folders) f.toStruct()],
			options: options.toStruct(),
			nextNoteId: nextNoteId,
			nextFolderId: nextFolderId
		};
		var json:String = Json.stringify(struct);
		#if sys
		try {
			if (!FileSystem.exists(dir()))
				FileSystem.createDirectory(dir());
			File.saveContent(filePath(), json);
		} catch (e:Dynamic) {}
		#elseif html5
		var shared = SharedObject.getLocal("smidrNotepadWorkspace");
		shared.data.json = json;
		shared.flush();
		#end
	}

	function seed():Void {
		var welcome = newNote(-1);
		welcome.title = "Welcome";
		welcome.text = "This is the SmidrUI notepad.\n"
			+ "Format with the toolbar: headings, bold, italic, colours and lists.\n"
			+ "Right-click a note for actions. Pin, protect, or file notes into folders.\n"
			+ "Everything is saved automatically to your documents folder.";
		welcome.styles = [for (i in 0...welcome.text.length) 0];
		save();
	}

	/** Whether another note may be created under the `maxNotes` cap. **/
	public function canAddNote():Bool {
		return options.maxNotes <= 0 || notes.length < options.maxNotes;
	}

	public function newNote(folderId:Int):Note {
		var note = new Note(nextNoteId++, "Untitled", folderId);
		notes.push(note);
		return note;
	}

	public function newFolder(name:String, parentId:Int = -1):Folder {
		var folder = new Folder(nextFolderId++, name, parentId);
		folders.push(folder);
		return folder;
	}

	public function deleteNote(note:Note):Void {
		notes.remove(note);
	}

	/** Removes a folder, moving its notes and sub-folders up to its parent. **/
	public function deleteFolder(folder:Folder):Void {
		for (n in notes)
			if (n.folderId == folder.id)
				n.folderId = folder.parentId;
		for (f in folders)
			if (f.parentId == folder.id)
				f.parentId = folder.parentId;
		folders.remove(folder);
	}

	public function folderById(id:Int):Folder {
		for (f in folders)
			if (f.id == id)
				return f;
		return null;
	}
}
