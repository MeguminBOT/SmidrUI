package notepad;

/**
	One note: a title plus rich body content (the plain `text` and its parallel `styles` words from
	`smidr.widgets.UITextArea`), timestamps, and the pin / important / folder flags. `important`
	notes are guarded against deletion. Serializes to/from a plain structure for JSON persistence.
**/
class Note {
	public var id:Int;
	public var title:String;
	public var text:String;
	public var styles:Array<Int>;
	public var created:Float;
	public var modified:Float;
	public var pinned:Bool;

	/** The "important" tag: `true` blocks deletion until it is cleared. **/
	public var important:Bool;

	/** Owning folder id, or -1 for the root. **/
	public var folderId:Int;

	public function new(id:Int, title:String = "Untitled", folderId:Int = -1) {
		this.id = id;
		this.title = title;
		this.folderId = folderId;
		text = "";
		styles = [];
		created = Date.now().getTime();
		modified = created;
		pinned = false;
		important = false;
	}

	/** Stamps `modified` with the current time (call after an edit). **/
	public function touch():Void {
		modified = Date.now().getTime();
	}

	public function toStruct():Dynamic {
		return {
			id: id,
			title: title,
			text: text,
			styles: styles,
			created: created,
			modified: modified,
			pinned: pinned,
			important: important,
			folderId: folderId
		};
	}

	public static function fromStruct(o:Dynamic):Note {
		var note = new Note(Std.int(o.id), o.title != null ? o.title : "Untitled", o.folderId != null ? Std.int(o.folderId) : -1);
		note.text = (o.text != null) ? o.text : "";
		note.styles = (o.styles != null) ? [for (v in (o.styles : Array<Dynamic>)) Std.int(v)] : [for (i in 0...note.text.length) 0];
		if (o.created != null)
			note.created = o.created;
		if (o.modified != null)
			note.modified = o.modified;
		note.pinned = o.pinned == true;
		note.important = o.important == true;
		return note;
	}
}
