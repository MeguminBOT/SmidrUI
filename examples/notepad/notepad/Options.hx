package notepad;

/** User settings persisted with the workspace (theme, accent, default text colour, save dir, cap). **/
class Options {
	/** Theme preset index into `UITheme.PRESETS`. **/
	public var themeIndex:Int = 0;

	/** Custom accent ARGB, or 0 to keep the preset's accent. **/
	public var accent:Int = 0;

	/** Default text colour ARGB, or 0 to keep the theme text colour. **/
	public var fontColor:Int = 0;

	/** Override notes directory, or null for `<documents>/SmidrNotes`. **/
	public var saveDir:String = null;

	/** Maximum number of notes allowed (0 = unlimited). **/
	public var maxNotes:Int = 200;

	public function new() {}

	public function toStruct():Dynamic {
		return {
			themeIndex: themeIndex,
			accent: accent,
			fontColor: fontColor,
			saveDir: saveDir,
			maxNotes: maxNotes
		};
	}

	public static function fromStruct(o:Dynamic):Options {
		var options = new Options();
		if (o.themeIndex != null)
			options.themeIndex = Std.int(o.themeIndex);
		if (o.accent != null)
			options.accent = Std.int(o.accent);
		if (o.fontColor != null)
			options.fontColor = Std.int(o.fontColor);
		if (o.saveDir != null)
			options.saveDir = o.saveDir;
		if (o.maxNotes != null)
			options.maxNotes = Std.int(o.maxNotes);
		return options;
	}
}
