package smidr;

/**
	Named ids for the built-in vector glyph set drawn by `UIGlyphs.draw`.

	An `enum abstract` over `Int`, so at runtime it is just an `Int` (no allocation, no boxing —
	the HXCPP output is identical to using raw ints) while giving type-safe, named values. Where
	a `UIGlyph` is expected the name can be written unqualified, e.g. `UIGlyphs.draw(g,
	CHEVRON_LEFT, ...)`; elsewhere use `UIGlyph.CHEVRON_LEFT`. `from`/`to Int` keep it
	interchangeable with plain ints, so passing a raw id still compiles.

	Ids are grouped: media (0..9), actions (10..23), navigation (24..33), files (34..39),
	system/status (40..58). `COUNT` bounds iteration for pickers/demos.
**/
enum abstract UIGlyph(Int) from Int to Int {
	var PLAY = 0;
	var PAUSE = 1;
	var STOP = 2;
	var PREV = 3;
	var NEXT = 4;
	var RECORD = 5;
	var LOOP = 6;
	var SHUFFLE = 7;
	var VOLUME = 8;
	var MUTE = 9;
	var PLUS = 10;
	var MINUS = 11;
	var CLOSE = 12;
	var CHECK = 13;
	var SEARCH = 14;
	var GEAR = 15;
	var REFRESH = 16;
	var TRASH = 17;
	var EDIT = 18;
	var COPY = 19;
	var DOWNLOAD = 20;
	var UPLOAD = 21;
	var EXTERNAL = 22;
	var FILTER = 23;
	var CHEVRON_LEFT = 24;
	var CHEVRON_RIGHT = 25;
	var CHEVRON_UP = 26;
	var CHEVRON_DOWN = 27;
	var ARROW_LEFT = 28;
	var ARROW_RIGHT = 29;
	var ARROW_UP = 30;
	var ARROW_DOWN = 31;
	var MENU = 32;
	var MORE = 33;
	var FILE = 34;
	var FOLDER = 35;
	var FOLDER_OPEN = 36;
	var IMAGE = 37;
	var SAVE = 38;
	var CLIPBOARD = 39;
	var INFO = 40;
	var WARNING = 41;
	var ERROR = 42;
	var HOME = 43;
	var LOCK = 44;
	var UNLOCK = 45;
	var EYE = 46;
	var STAR = 47;
	var HEART = 48;
	var BELL = 49;
	var CLOCK = 50;
	var POWER = 51;
	var USER = 52;
	var GRID = 53;
	var LIST = 54;
	var DRAG = 55;
	var FULLSCREEN = 56;
	var PIN = 57;
	var DOT = 58;

	/** Number of glyphs (ids are 0..COUNT-1). **/
	public static inline var COUNT:Int = 59;
}
