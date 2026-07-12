package notepad;

/** A note folder in the sidebar tree. `parentId` is -1 for a top-level folder. **/
class Folder {
	public var id:Int;
	public var name:String;
	public var parentId:Int;

	public function new(id:Int, name:String, parentId:Int = -1) {
		this.id = id;
		this.name = name;
		this.parentId = parentId;
	}

	public function toStruct():Dynamic {
		return {id: id, name: name, parentId: parentId};
	}

	public static function fromStruct(o:Dynamic):Folder {
		return new Folder(Std.int(o.id), o.name != null ? o.name : "Folder", o.parentId != null ? Std.int(o.parentId) : -1);
	}
}
