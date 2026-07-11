package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.widgets.UIButton;
import smidr.widgets.UILabel;
import smidr.widgets.UIPanel;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

private typedef Rect = {x:Int, y:Int, w:Int, h:Int};

/**
	A snipping-tool example. On launch it hides its own window, shells out to the OS screenshot
	facility to grab the primary screen (PowerShell on Windows, `screencapture` on macOS,
	`grim`/`scrot`/`import` on Linux), then shows that frozen image full-screen as a borderless
	overlay. Drag a rectangle to snip a region, or pick full-screen / the active window from the
	toolbar; Save writes a timestamped PNG (Copy also puts it on the clipboard). Esc cancels.

	The screen grab is OS-native — OpenFL cannot capture the desktop itself — so this is a desktop
	build only (no HTML5). Window-mode capture is best-effort (the foreground window rect on
	Windows; it falls back to full-screen elsewhere).

	For a more advanced snipping tool, 
	you'd need to make a more advanced implementation through Lime,
	this is just an example.
**/
class Snip extends Sprite {
	static inline var MODE_REGION:Int = 0;
	static inline var MODE_FULL:Int = 1;
	static inline var MODE_WINDOW:Int = 2;

	static inline var SEP:String = #if windows "\\" #else "/" #end;

	var ui:UIRoot;
	var screen:BitmapData;
	var backdrop:Bitmap;
	var overlay:SnipOverlay;
	var toolbar:UIPanel;
	var hint:UILabel;
	var dimLabel:UILabel;

	var regionBtn:UIButton;
	var fullBtn:UIButton;
	var windowBtn:UIButton;
	var saveBtn:UIButton;
	var copyBtn:UIButton;

	var mode:Int = MODE_REGION;
	var windowRect:Rectangle = null;

	public function new() {
		super();

		// Hide our own window so the capture sees the real desktop, not this overlay.
		var win = openfl.Lib.application.window;
		if (win != null)
			win.visible = false;
		Sys.sleep(0.08);

		var tmp = tempPath("smidr_snip.png");
		if (captureScreen(tmp) && FileSystem.exists(tmp)) {
			try
				screen = BitmapData.fromFile(tmp)
			catch (e:Dynamic)
				screen = null;
		}
		windowRect = foregroundRect();

		if (win != null)
			win.visible = true;

		// Headless check: SMIDR_SNIP_AUTO=full grabs the whole screen and exits.
		if (Sys.getEnv("SMIDR_SNIP_AUTO") != null) {
			if (screen != null)
				Sys.println("Saved: " + saveCrop({x: 0, y: 0, w: screen.width, h: screen.height}));
			else
				Sys.println("Capture failed");
			exit();
			return;
		}

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(_:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;

		if (screen != null) {
			backdrop = new Bitmap(screen);
			backdrop.smoothing = true;
			backdrop.scaleX = sw / screen.width;
			backdrop.scaleY = sh / screen.height;
			addChild(backdrop);
		}

		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);

		overlay = new SnipOverlay();
		overlay.resize(sw, sh);
		overlay.onChange = onSelectionChanged;
		overlay.onCommit = () -> grab(false);
		ui.content.addChild(overlay);

		buildToolbar();

		dimLabel = new UILabel("", 12, PRIMARY);
		dimLabel.visible = false;
		ui.content.addChild(dimLabel);

		hint = new UILabel("Drag to select    ·    Enter to save    ·    Esc to cancel", 14, SECONDARY);
		ui.content.addChild(hint);

		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
		stage.addEventListener(Event.RESIZE, (_) -> layout());
		layout();
		onSelectionChanged();
	}

	function buildToolbar():Void {
		toolbar = new UIPanel(0, 44, PANEL2);
		toolbar.corner = 10;
		toolbar.outline = true;
		ui.content.addChild(toolbar);

		var x:Float = 8;
		inline function tb(label:String, cb:Void->Void, accent:Bool = false):UIButton {
			var b = new UIButton(label, 84, 30, cb, accent);
			b.x = x;
			b.y = 7;
			toolbar.addChild(b);
			x += 88;
			return b;
		}
		regionBtn = tb("Region", () -> setMode(MODE_REGION));
		fullBtn = tb("Full", () -> setMode(MODE_FULL));
		windowBtn = tb("Window", () -> setMode(MODE_WINDOW));
		x += 8;
		saveBtn = tb("Save", () -> grab(false), true);
		copyBtn = tb("Copy", () -> grab(true));
		tb("Cancel", () -> exit());

		toolbar.resize(x, 44);
		updateModeButtons();
	}

	function setMode(m:Int):Void {
		mode = m;
		switch (m) {
			case MODE_FULL:
				overlay.setSelection(0, 0, stage.stageWidth, stage.stageHeight);
			case MODE_WINDOW:
				if (windowRect != null) {
					var r = screenToStage(windowRect);
					overlay.setSelection(r.x, r.y, r.width, r.height);
				} else {
					setHint("No active-window rect — using full screen");
					overlay.setSelection(0, 0, stage.stageWidth, stage.stageHeight);
				}
			default:
				overlay.clearSelection();
		}
		updateModeButtons();
		onSelectionChanged();
	}

	function updateModeButtons():Void {
		regionBtn.accent = (mode == MODE_REGION);
		fullBtn.accent = (mode == MODE_FULL);
		windowBtn.accent = (mode == MODE_WINDOW);
	}

	function onSelectionChanged():Void {
		var valid = overlay.selValid;
		hint.visible = !valid;
		dimLabel.visible = valid;
		saveBtn.enabled = valid;
		copyBtn.enabled = valid;
		if (valid) {
			var sel = overlay.selection();
			var r = stageToScreen(sel);
			dimLabel.text = r.w + " × " + r.h + " px";
			dimLabel.x = Math.max(6, sel.x);
			dimLabel.y = Math.max(6, sel.y - 22);
		}
	}

	function onKey(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case 27: // Escape
				exit();
			case 13: // Enter
				grab(false);
		}
	}

	function grab(copy:Bool):Void {
		if (screen == null) {
			exit();
			return;
		}
		var r = stageToScreen(overlay.selection());
		if (r.w < 2 || r.h < 2) {
			setHint("Nothing selected — drag a region first");
			return;
		}
		var path = saveCrop(r);
		if (path == null) {
			setHint("Save failed");
			return;
		}
		if (copy)
			copyToClipboard(path);
		exit();
	}

	function saveCrop(r:Rect):String {
		var crop = new BitmapData(r.w, r.h, true, 0);
		crop.copyPixels(screen, new Rectangle(r.x, r.y, r.w, r.h), new Point(0, 0));
		var bytes:ByteArray = crop.encode(new Rectangle(0, 0, r.w, r.h), new PNGEncoderOptions());
		var out = destFile();
		try {
			File.saveBytes(out, bytes);
			return out;
		} catch (e:Dynamic) {
			return null;
		}
	}

	function setHint(msg:String):Void {
		if (hint != null) {
			hint.text = msg;
			hint.visible = true;
			layout();
		}
	}

	function layout():Void {
		if (stage == null)
			return;
		var sw:Float = stage.stageWidth;
		if (overlay != null)
			overlay.resize(sw, stage.stageHeight);
		if (toolbar != null) {
			toolbar.x = (sw - toolbar.w) / 2;
			toolbar.y = 22;
		}
		if (hint != null) {
			hint.x = (sw - hint.measure()) / 2;
			hint.y = stage.stageHeight * 0.5;
		}
	}

	// coordinate mapping between the on-screen overlay (stage) and the captured image (pixels)
	function stageToScreen(s:Rectangle):Rect {
		var fx = screen.width / stage.stageWidth;
		var fy = screen.height / stage.stageHeight;
		var x = Std.int(s.x * fx);
		var y = Std.int(s.y * fy);
		var w = Std.int(s.width * fx);
		var h = Std.int(s.height * fy);
		if (x < 0) x = 0;
		if (y < 0) y = 0;
		if (x + w > screen.width) w = screen.width - x;
		if (y + h > screen.height) h = screen.height - y;
		return {x: x, y: y, w: w, h: h};
	}

	function screenToStage(r:Rectangle):Rectangle {
		var fx = stage.stageWidth / screen.width;
		var fy = stage.stageHeight / screen.height;
		return new Rectangle(r.x * fx, r.y * fy, r.width * fx, r.height * fy);
	}

	// platform shell-outs
	function captureScreen(path:String):Bool {
		#if windows
		var script = "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; "
			+ "$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; "
			+ "$bmp=New-Object System.Drawing.Bitmap($b.Width,$b.Height); "
			+ "$g=[System.Drawing.Graphics]::FromImage($bmp); "
			+ "$g.CopyFromScreen($b.X,$b.Y,0,0,$b.Size); "
			+ "$bmp.Save('" + path + "',[System.Drawing.Imaging.ImageFormat]::Png); "
			+ "$g.Dispose(); $bmp.Dispose()";
		return run("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script]) == 0;
		#elseif mac
		return run("screencapture", ["-x", path]) == 0;
		#elseif linux
		if (run("grim", [path]) == 0 && FileSystem.exists(path))
			return true;
		if (run("scrot", ["-o", path]) == 0 && FileSystem.exists(path))
			return true;
		return run("import", ["-window", "root", path]) == 0;
		#else
		return false;
		#end
	}

	function foregroundRect():Rectangle {
		#if windows
		var ps = tempPath("smidr_fg.ps1");
		var script = "$sig = @'\n"
			+ "using System;\n"
			+ "using System.Runtime.InteropServices;\n"
			+ "public class Fg {\n"
			+ "  [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();\n"
			+ "  [StructLayout(LayoutKind.Sequential)] public struct R { public int L,T,Rt,B; }\n"
			+ "  [DllImport(\"user32.dll\")] public static extern bool GetWindowRect(IntPtr h, out R r);\n"
			+ "}\n"
			+ "'@\n"
			+ "Add-Type -TypeDefinition $sig\n"
			+ "$h = [Fg]::GetForegroundWindow()\n"
			+ "$r = New-Object Fg+R\n"
			+ "[void][Fg]::GetWindowRect($h, [ref]$r)\n"
			+ "Write-Output (\"{0},{1},{2},{3}\" -f $r.L,$r.T,($r.Rt-$r.L),($r.B-$r.T))\n";
		try
			File.saveContent(ps, script)
		catch (e:Dynamic)
			return null;
		var out = runOut("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps]);
		if (out == null)
			return null;
		var parts = StringTools.trim(out).split(",");
		if (parts.length != 4)
			return null;
		var x = Std.parseInt(parts[0]);
		var y = Std.parseInt(parts[1]);
		var w = Std.parseInt(parts[2]);
		var h = Std.parseInt(parts[3]);
		if (x == null || y == null || w == null || h == null || w < 40 || h < 40)
			return null;
		return new Rectangle(x, y, w, h);
		#else
		return null;
		#end
	}

	function copyToClipboard(path:String):Void {
		#if windows
		var script = "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; "
			+ "[System.Windows.Forms.Clipboard]::SetImage([System.Drawing.Image]::FromFile('" + path + "'))";
		run("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script]);
		#elseif linux
		run("sh", ["-c", "xclip -selection clipboard -t image/png -i '" + path + "' 2>/dev/null || wl-copy < '" + path + "' 2>/dev/null"]);
		#elseif mac
		run("osascript", ["-e", "set the clipboard to (read (POSIX file \"" + path + "\") as «class PNGf»)"]);
		#end
	}

	function run(cmd:String, args:Array<String>):Int {
		try {
			var p = new Process(cmd, args);
			var code = p.exitCode(true);
			p.close();
			return code;
		} catch (e:Dynamic) {
			return -1;
		}
	}

	function runOut(cmd:String, args:Array<String>):String {
		try {
			var p = new Process(cmd, args);
			var out = p.stdout.readAll().toString();
			p.exitCode(true);
			p.close();
			return out;
		} catch (e:Dynamic) {
			return null;
		}
	}

	function tempPath(name:String):String {
		var dir = #if windows Sys.getEnv("TEMP") #else "/tmp" #end;
		return (dir != null ? dir : ".") + SEP + name;
	}

	function destFile():String {
		var home = #if windows Sys.getEnv("USERPROFILE") #else Sys.getEnv("HOME") #end;
		var dir = (home != null && FileSystem.exists(home + SEP + "Pictures")) ? home + SEP + "Pictures" : (home != null ? home : ".");
		return dir + SEP + "snip-" + timestamp() + ".png";
	}

	function timestamp():String {
		var d = Date.now();
		inline function p(n:Int):String
			return n < 10 ? "0" + n : "" + n;
		return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + "-" + p(d.getHours()) + p(d.getMinutes()) + p(d.getSeconds());
	}

	function exit():Void {
		Sys.exit(0);
	}
}

/** The full-screen selection overlay: dims the frozen desktop and tracks a drag rectangle. **/
private class SnipOverlay extends UIComponent {
	public var onChange:Void->Void = null;
	public var onCommit:Void->Void = null;

	public var selValid(get, never):Bool;

	var selX:Float = 0;
	var selY:Float = 0;
	var selW:Float = 0;
	var selH:Float = 0;
	var has:Bool = false;
	var dragStartX:Float = 0;
	var dragStartY:Float = 0;

	public function new() {
		super(true, true);
		hoverCursor = openfl.ui.MouseCursor.AUTO;
	}

	inline function get_selValid():Bool
		return has && selW >= 2 && selH >= 2;

	public function selection():Rectangle
		return new Rectangle(selX, selY, selW, selH);

	public function clearSelection():Void {
		has = false;
		selW = 0;
		selH = 0;
		invalidate();
	}

	public function setSelection(x:Float, y:Float, w:Float, h:Float):Void {
		selX = x;
		selY = y;
		selW = w;
		selH = h;
		has = (w >= 2 && h >= 2);
		invalidate();
	}

	override function onPress(localX:Float, localY:Float):Void {
		dragStartX = localX;
		dragStartY = localY;
		selX = localX;
		selY = localY;
		selW = 0;
		selH = 0;
		has = true;
		beginCapture();
		invalidate();
		if (onChange != null)
			onChange();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		var p = globalToLocal(new Point(stageX, stageY));
		selX = Math.min(dragStartX, p.x);
		selY = Math.min(dragStartY, p.y);
		selW = Math.abs(p.x - dragStartX);
		selH = Math.abs(p.y - dragStartY);
		invalidate();
		if (onChange != null)
			onChange();
	}

	override function onDragEnd():Void {
		if (onChange != null)
			onChange();
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var dim:Float = 0.45;
		if (!selValid) {
			g.beginFill(0, dim);
			g.drawRect(0, 0, w, h);
			g.endFill();
			return;
		}
		// dim everything except the selection (four bands around it)
		g.beginFill(0, dim);
		g.drawRect(0, 0, w, selY);
		g.drawRect(0, selY + selH, w, h - (selY + selH));
		g.drawRect(0, selY, selX, selH);
		g.drawRect(selX + selW, selY, w - (selX + selW), selH);
		g.endFill();
		// selection outline
		g.lineStyle(1.5, UIColor.rgb(UITheme.accent));
		g.drawRect(selX, selY, selW, selH);
		g.lineStyle();
	}
}
