package smidr;

import openfl.display.Graphics;

/**
	The built-in vector glyph set, drawn directly into a `Graphics` at any size — no assets,
	crisp at every `UITheme.scale`, tinted by whatever colour the caller passes (so theme
	swaps re-tint for free in the widget's own render pass).

	Glyph ids are the named `UIGlyph` values (grouped media / actions / navigation / files /
	system-status); `UIGlyph.COUNT` bounds iteration for pickers/demos. All geometry lives inside
	a ~0.22..0.78 margin of the unit box so glyphs share optical weight when mixed.
**/
final class UIGlyphs {
	/**
		Draws a glyph into a `Graphics` (call inside a widget's `render()`; does not `clear()`).
		@param g the target graphics
		@param glyph the glyph to draw (a `UIGlyph`, e.g. `CHEVRON_LEFT`)
		@param x the icon box left edge
		@param y the icon box top edge
		@param s the icon box edge length (glyphs pad themselves within it)
		@param color the tint (`0xRRGGBB`; alpha bits masked off — use `a` for opacity)
		@param a opacity 0..1
	**/
	public static function draw(g:Graphics, glyph:UIGlyph, x:Float, y:Float, s:Float, color:Int, a:Float = 1):Void {
		var c:Int = color & 0xFFFFFF;
		var t:Float = s * 0.1;
		if (t < 1.5)
			t = 1.5;
		switch (glyph) {
			case PLAY:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.34, y + s * 0.26);
				g.lineTo(x + s * 0.34, y + s * 0.74);
				g.lineTo(x + s * 0.78, y + s * 0.5);
				g.endFill();
			case PAUSE:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.3, y + s * 0.28, s * 0.15, s * 0.44);
				g.drawRect(x + s * 0.55, y + s * 0.28, s * 0.15, s * 0.44);
				g.endFill();
			case STOP:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.3, y + s * 0.3, s * 0.4, s * 0.4);
				g.endFill();
			case PREV:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.26, y + s * 0.3, s * 0.08, s * 0.4);
				g.moveTo(x + s * 0.74, y + s * 0.3);
				g.lineTo(x + s * 0.74, y + s * 0.7);
				g.lineTo(x + s * 0.42, y + s * 0.5);
				g.endFill();
			case NEXT:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.66, y + s * 0.3, s * 0.08, s * 0.4);
				g.moveTo(x + s * 0.26, y + s * 0.3);
				g.lineTo(x + s * 0.26, y + s * 0.7);
				g.lineTo(x + s * 0.58, y + s * 0.5);
				g.endFill();
			case RECORD:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.22);
				g.endFill();
			case LOOP:
				g.lineStyle(t, c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.2);
				g.lineStyle();
				g.beginFill(c, a);
				g.moveTo(x + s * 0.6, y + s * 0.2);
				g.lineTo(x + s * 0.8, y + s * 0.3);
				g.lineTo(x + s * 0.6, y + s * 0.42);
				g.endFill();
			case SHUFFLE:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.22, y + s * 0.34);
				g.lineTo(x + s * 0.4, y + s * 0.34);
				g.lineTo(x + s * 0.6, y + s * 0.62);
				g.lineTo(x + s * 0.72, y + s * 0.62);
				g.moveTo(x + s * 0.22, y + s * 0.62);
				g.lineTo(x + s * 0.4, y + s * 0.62);
				g.lineTo(x + s * 0.6, y + s * 0.34);
				g.lineTo(x + s * 0.72, y + s * 0.34);
				g.lineStyle();
				g.beginFill(c, a);
				g.moveTo(x + s * 0.7, y + s * 0.27);
				g.lineTo(x + s * 0.84, y + s * 0.34);
				g.lineTo(x + s * 0.7, y + s * 0.41);
				g.moveTo(x + s * 0.7, y + s * 0.55);
				g.lineTo(x + s * 0.84, y + s * 0.62);
				g.lineTo(x + s * 0.7, y + s * 0.69);
				g.endFill();
			case VOLUME:
				speaker(g, x, y, s, c, a);
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.6, y + s * 0.38);
				g.curveTo(x + s * 0.72, y + s * 0.5, x + s * 0.6, y + s * 0.62);
				g.moveTo(x + s * 0.66, y + s * 0.28);
				g.curveTo(x + s * 0.86, y + s * 0.5, x + s * 0.66, y + s * 0.72);
				g.lineStyle();
			case MUTE:
				speaker(g, x, y, s, c, a);
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.6, y + s * 0.4);
				g.lineTo(x + s * 0.8, y + s * 0.6);
				g.moveTo(x + s * 0.8, y + s * 0.4);
				g.lineTo(x + s * 0.6, y + s * 0.6);
				g.lineStyle();
			case PLUS:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.28, y + s * 0.46, s * 0.44, s * 0.08);
				g.drawRect(x + s * 0.46, y + s * 0.28, s * 0.08, s * 0.44);
				g.endFill();
			case MINUS:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.28, y + s * 0.46, s * 0.44, s * 0.08);
				g.endFill();
			case CLOSE:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.3, y + s * 0.3);
				g.lineTo(x + s * 0.7, y + s * 0.7);
				g.moveTo(x + s * 0.7, y + s * 0.3);
				g.lineTo(x + s * 0.3, y + s * 0.7);
				g.lineStyle();
			case CHECK:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.26, y + s * 0.52);
				g.lineTo(x + s * 0.44, y + s * 0.7);
				g.lineTo(x + s * 0.76, y + s * 0.32);
				g.lineStyle();
			case SEARCH:
				g.lineStyle(t, c, a);
				g.drawCircle(x + s * 0.44, y + s * 0.44, s * 0.18);
				g.moveTo(x + s * 0.58, y + s * 0.58);
				g.lineTo(x + s * 0.76, y + s * 0.76);
				g.lineStyle();
			case GEAR:
				g.lineStyle(t, c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.17);
				g.lineStyle();
				g.beginFill(c, a);
				var gi:Int = 0;
				while (gi < 4) {
					var ang:Float = gi * 1.5707963;
					var gx:Float = x + s * 0.5 + Math.cos(ang) * s * 0.27;
					var gy:Float = y + s * 0.5 + Math.sin(ang) * s * 0.27;
					g.drawRect(gx - s * 0.05, gy - s * 0.05, s * 0.1, s * 0.1);
					gi++;
				}
				g.endFill();
			case REFRESH:
				g.lineStyle(t, c, a);
				arcPath(g, x + s * 0.5, y + s * 0.5, s * 0.22, -0.4, 4.6, true);
				g.lineStyle();
				g.beginFill(c, a);
				g.moveTo(x + s * 0.66, y + s * 0.28);
				g.lineTo(x + s * 0.84, y + s * 0.36);
				g.lineTo(x + s * 0.68, y + s * 0.48);
				g.endFill();
			case TRASH:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.28, y + s * 0.26, s * 0.44, s * 0.07);
				g.drawRect(x + s * 0.42, y + s * 0.2, s * 0.16, s * 0.06);
				g.endFill();
				g.lineStyle(t, c, a);
				g.drawRoundRect(x + s * 0.33, y + s * 0.39, s * 0.34, s * 0.36, s * 0.06, s * 0.06);
				g.moveTo(x + s * 0.44, y + s * 0.46);
				g.lineTo(x + s * 0.44, y + s * 0.68);
				g.moveTo(x + s * 0.56, y + s * 0.46);
				g.lineTo(x + s * 0.56, y + s * 0.68);
				g.lineStyle();
			case EDIT:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.3, y + s * 0.6);
				g.lineTo(x + s * 0.6, y + s * 0.3);
				g.lineTo(x + s * 0.7, y + s * 0.4);
				g.lineTo(x + s * 0.4, y + s * 0.7);
				g.moveTo(x + s * 0.3, y + s * 0.6);
				g.lineTo(x + s * 0.4, y + s * 0.7);
				g.lineTo(x + s * 0.25, y + s * 0.75);
				g.endFill();
			case COPY:
				g.lineStyle(t, c, a);
				g.drawRoundRect(x + s * 0.28, y + s * 0.28, s * 0.34, s * 0.34, s * 0.06, s * 0.06);
				g.drawRoundRect(x + s * 0.4, y + s * 0.4, s * 0.34, s * 0.34, s * 0.06, s * 0.06);
				g.lineStyle();
			case DOWNLOAD:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.46, y + s * 0.24, s * 0.08, s * 0.26);
				g.moveTo(x + s * 0.34, y + s * 0.48);
				g.lineTo(x + s * 0.66, y + s * 0.48);
				g.lineTo(x + s * 0.5, y + s * 0.64);
				g.drawRect(x + s * 0.28, y + s * 0.72, s * 0.44, s * 0.07);
				g.endFill();
			case UPLOAD:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.5, y + s * 0.22);
				g.lineTo(x + s * 0.66, y + s * 0.38);
				g.lineTo(x + s * 0.34, y + s * 0.38);
				g.drawRect(x + s * 0.46, y + s * 0.38, s * 0.08, s * 0.26);
				g.drawRect(x + s * 0.28, y + s * 0.72, s * 0.44, s * 0.07);
				g.endFill();
			case EXTERNAL:
				g.lineStyle(t, c, a);
				g.drawRoundRect(x + s * 0.26, y + s * 0.34, s * 0.4, s * 0.4, s * 0.06, s * 0.06);
				g.moveTo(x + s * 0.5, y + s * 0.5);
				g.lineTo(x + s * 0.74, y + s * 0.26);
				g.lineStyle();
				g.beginFill(c, a);
				g.moveTo(x + s * 0.6, y + s * 0.22);
				g.lineTo(x + s * 0.78, y + s * 0.22);
				g.lineTo(x + s * 0.78, y + s * 0.4);
				g.endFill();
			case FILTER:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.24, y + s * 0.26);
				g.lineTo(x + s * 0.76, y + s * 0.26);
				g.lineTo(x + s * 0.57, y + s * 0.52);
				g.lineTo(x + s * 0.57, y + s * 0.72);
				g.lineTo(x + s * 0.43, y + s * 0.64);
				g.lineTo(x + s * 0.43, y + s * 0.52);
				g.endFill();
			case CHEVRON_LEFT:
				chev(g, x, y, s, t, c, a, 0.58, 0.3, 0.4, 0.5, 0.58, 0.7);
			case CHEVRON_RIGHT:
				chev(g, x, y, s, t, c, a, 0.42, 0.3, 0.6, 0.5, 0.42, 0.7);
			case CHEVRON_UP:
				chev(g, x, y, s, t, c, a, 0.3, 0.58, 0.5, 0.4, 0.7, 0.58);
			case CHEVRON_DOWN:
				chev(g, x, y, s, t, c, a, 0.3, 0.42, 0.5, 0.6, 0.7, 0.42);
			case ARROW_LEFT:
				arrow(g, x, y, s, t, c, a, 0.74, 0.5, 0.28, 0.5, 0.44, 0.34, 0.44, 0.66);
			case ARROW_RIGHT:
				arrow(g, x, y, s, t, c, a, 0.26, 0.5, 0.72, 0.5, 0.56, 0.34, 0.56, 0.66);
			case ARROW_UP:
				arrow(g, x, y, s, t, c, a, 0.5, 0.74, 0.5, 0.28, 0.34, 0.44, 0.66, 0.44);
			case ARROW_DOWN:
				arrow(g, x, y, s, t, c, a, 0.5, 0.26, 0.5, 0.72, 0.34, 0.56, 0.66, 0.56);
			case MENU:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.26, y + s * 0.32, s * 0.48, s * 0.07);
				g.drawRect(x + s * 0.26, y + s * 0.465, s * 0.48, s * 0.07);
				g.drawRect(x + s * 0.26, y + s * 0.61, s * 0.48, s * 0.07);
				g.endFill();
			case MORE:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.3, y + s * 0.5, s * 0.055);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.055);
				g.drawCircle(x + s * 0.7, y + s * 0.5, s * 0.055);
				g.endFill();
			case FILE:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.32, y + s * 0.24);
				g.lineTo(x + s * 0.56, y + s * 0.24);
				g.lineTo(x + s * 0.68, y + s * 0.36);
				g.lineTo(x + s * 0.68, y + s * 0.76);
				g.lineTo(x + s * 0.32, y + s * 0.76);
				g.lineTo(x + s * 0.32, y + s * 0.24);
				g.moveTo(x + s * 0.56, y + s * 0.24);
				g.lineTo(x + s * 0.56, y + s * 0.36);
				g.lineTo(x + s * 0.68, y + s * 0.36);
				g.lineStyle();
			case FOLDER:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.22, y + s * 0.3);
				g.lineTo(x + s * 0.42, y + s * 0.3);
				g.lineTo(x + s * 0.48, y + s * 0.38);
				g.lineTo(x + s * 0.78, y + s * 0.38);
				g.lineTo(x + s * 0.78, y + s * 0.72);
				g.lineTo(x + s * 0.22, y + s * 0.72);
				g.endFill();
			case FOLDER_OPEN:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.22, y + s * 0.68);
				g.lineTo(x + s * 0.22, y + s * 0.3);
				g.lineTo(x + s * 0.4, y + s * 0.3);
				g.lineTo(x + s * 0.46, y + s * 0.38);
				g.lineTo(x + s * 0.72, y + s * 0.38);
				g.lineTo(x + s * 0.72, y + s * 0.44);
				g.lineStyle();
				g.beginFill(c, a);
				g.moveTo(x + s * 0.28, y + s * 0.46);
				g.lineTo(x + s * 0.84, y + s * 0.46);
				g.lineTo(x + s * 0.74, y + s * 0.7);
				g.lineTo(x + s * 0.2, y + s * 0.7);
				g.endFill();
			case IMAGE:
				g.lineStyle(t, c, a);
				g.drawRoundRect(x + s * 0.24, y + s * 0.28, s * 0.52, s * 0.44, s * 0.06, s * 0.06);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.38, y + s * 0.4, s * 0.045);
				g.moveTo(x + s * 0.3, y + s * 0.66);
				g.lineTo(x + s * 0.48, y + s * 0.46);
				g.lineTo(x + s * 0.62, y + s * 0.66);
				g.moveTo(x + s * 0.54, y + s * 0.66);
				g.lineTo(x + s * 0.62, y + s * 0.56);
				g.lineTo(x + s * 0.72, y + s * 0.66);
				g.endFill();
			case SAVE:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.26, y + s * 0.26);
				g.lineTo(x + s * 0.64, y + s * 0.26);
				g.lineTo(x + s * 0.74, y + s * 0.36);
				g.lineTo(x + s * 0.74, y + s * 0.74);
				g.lineTo(x + s * 0.26, y + s * 0.74);
				g.lineTo(x + s * 0.26, y + s * 0.26);
				g.drawRect(x + s * 0.36, y + s * 0.5, s * 0.28, s * 0.24);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawRect(x + s * 0.38, y + s * 0.26, s * 0.2, s * 0.13);
				g.endFill();
			case CLIPBOARD:
				g.lineStyle(t, c, a);
				g.drawRoundRect(x + s * 0.3, y + s * 0.28, s * 0.4, s * 0.5, s * 0.06, s * 0.06);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawRoundRect(x + s * 0.4, y + s * 0.22, s * 0.2, s * 0.1, s * 0.05, s * 0.05);
				g.endFill();
			case INFO:
				g.lineStyle(t, c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.24);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.37, s * 0.04);
				g.drawRect(x + s * 0.465, y + s * 0.45, s * 0.07, s * 0.2);
				g.endFill();
			case WARNING:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.5, y + s * 0.24);
				g.lineTo(x + s * 0.78, y + s * 0.74);
				g.lineTo(x + s * 0.22, y + s * 0.74);
				g.lineTo(x + s * 0.5, y + s * 0.24);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawRect(x + s * 0.465, y + s * 0.42, s * 0.07, s * 0.15);
				g.drawCircle(x + s * 0.5, y + s * 0.65, s * 0.04);
				g.endFill();
			case ERROR:
				g.lineStyle(t, c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.24);
				g.moveTo(x + s * 0.4, y + s * 0.4);
				g.lineTo(x + s * 0.6, y + s * 0.6);
				g.moveTo(x + s * 0.6, y + s * 0.4);
				g.lineTo(x + s * 0.4, y + s * 0.6);
				g.lineStyle();
			case HOME:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.5, y + s * 0.22);
				g.lineTo(x + s * 0.8, y + s * 0.48);
				g.lineTo(x + s * 0.2, y + s * 0.48);
				g.drawRect(x + s * 0.3, y + s * 0.48, s * 0.4, s * 0.28);
				g.endFill();
			case LOCK:
				g.lineStyle(t, c, a);
				arcPath(g, x + s * 0.5, y + s * 0.44, s * 0.13, 3.14159, 6.28318, true);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawRoundRect(x + s * 0.32, y + s * 0.44, s * 0.36, s * 0.32, s * 0.08, s * 0.08);
				g.endFill();
			case UNLOCK:
				g.lineStyle(t, c, a);
				arcPath(g, x + s * 0.5, y + s * 0.42, s * 0.13, 3.14159, 5.5, true);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawRoundRect(x + s * 0.32, y + s * 0.44, s * 0.36, s * 0.32, s * 0.08, s * 0.08);
				g.endFill();
			case EYE:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.22, y + s * 0.5);
				g.curveTo(x + s * 0.5, y + s * 0.22, x + s * 0.78, y + s * 0.5);
				g.curveTo(x + s * 0.5, y + s * 0.78, x + s * 0.22, y + s * 0.5);
				g.lineStyle();
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.09);
				g.endFill();
			case STAR:
				g.beginFill(c, a);
				var si:Int = 0;
				var cx:Float = x + s * 0.5;
				var cy:Float = y + s * 0.52;
				while (si < 10) {
					var r:Float = (si & 1 == 0) ? s * 0.28 : s * 0.115;
					var ang:Float = -1.5707963 + si * 0.62831853;
					var px:Float = cx + Math.cos(ang) * r;
					var py:Float = cy + Math.sin(ang) * r;
					if (si == 0)
						g.moveTo(px, py);
					else
						g.lineTo(px, py);
					si++;
				}
				g.endFill();
			case HEART:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.5, y + s * 0.74);
				g.curveTo(x + s * 0.14, y + s * 0.48, x + s * 0.3, y + s * 0.3);
				g.curveTo(x + s * 0.42, y + s * 0.2, x + s * 0.5, y + s * 0.36);
				g.curveTo(x + s * 0.58, y + s * 0.2, x + s * 0.7, y + s * 0.3);
				g.curveTo(x + s * 0.86, y + s * 0.48, x + s * 0.5, y + s * 0.74);
				g.endFill();
			case BELL:
				g.beginFill(c, a);
				g.moveTo(x + s * 0.26, y + s * 0.64);
				g.lineTo(x + s * 0.74, y + s * 0.64);
				g.lineTo(x + s * 0.66, y + s * 0.55);
				g.lineTo(x + s * 0.66, y + s * 0.42);
				g.curveTo(x + s * 0.66, y + s * 0.27, x + s * 0.5, y + s * 0.27);
				g.curveTo(x + s * 0.34, y + s * 0.27, x + s * 0.34, y + s * 0.42);
				g.lineTo(x + s * 0.34, y + s * 0.55);
				g.moveTo(x + s * 0.5, y + s * 0.74);
				g.drawCircle(x + s * 0.5, y + s * 0.72, s * 0.05);
				g.endFill();
			case CLOCK:
				g.lineStyle(t, c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.24);
				g.moveTo(x + s * 0.5, y + s * 0.36);
				g.lineTo(x + s * 0.5, y + s * 0.52);
				g.lineTo(x + s * 0.62, y + s * 0.58);
				g.lineStyle();
			case POWER:
				g.lineStyle(t, c, a);
				arcPath(g, x + s * 0.5, y + s * 0.54, s * 0.2, -1.02, 4.16, true);
				g.moveTo(x + s * 0.5, y + s * 0.22);
				g.lineTo(x + s * 0.5, y + s * 0.48);
				g.lineStyle();
			case USER:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.36, s * 0.12);
				g.moveTo(x + s * 0.26, y + s * 0.78);
				arcPath(g, x + s * 0.5, y + s * 0.78, s * 0.24, 3.14159, 6.28318, false);
				g.endFill();
			case GRID:
				g.beginFill(c, a);
				g.drawRect(x + s * 0.26, y + s * 0.26, s * 0.2, s * 0.2);
				g.drawRect(x + s * 0.54, y + s * 0.26, s * 0.2, s * 0.2);
				g.drawRect(x + s * 0.26, y + s * 0.54, s * 0.2, s * 0.2);
				g.drawRect(x + s * 0.54, y + s * 0.54, s * 0.2, s * 0.2);
				g.endFill();
			case LIST:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.3, y + s * 0.34, s * 0.04);
				g.drawCircle(x + s * 0.3, y + s * 0.5, s * 0.04);
				g.drawCircle(x + s * 0.3, y + s * 0.66, s * 0.04);
				g.drawRect(x + s * 0.4, y + s * 0.31, s * 0.34, s * 0.06);
				g.drawRect(x + s * 0.4, y + s * 0.47, s * 0.34, s * 0.06);
				g.drawRect(x + s * 0.4, y + s * 0.63, s * 0.34, s * 0.06);
				g.endFill();
			case DRAG:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.42, y + s * 0.32, s * 0.045);
				g.drawCircle(x + s * 0.58, y + s * 0.32, s * 0.045);
				g.drawCircle(x + s * 0.42, y + s * 0.5, s * 0.045);
				g.drawCircle(x + s * 0.58, y + s * 0.5, s * 0.045);
				g.drawCircle(x + s * 0.42, y + s * 0.68, s * 0.045);
				g.drawCircle(x + s * 0.58, y + s * 0.68, s * 0.045);
				g.endFill();
			case FULLSCREEN:
				g.lineStyle(t, c, a);
				g.moveTo(x + s * 0.26, y + s * 0.38);
				g.lineTo(x + s * 0.26, y + s * 0.26);
				g.lineTo(x + s * 0.38, y + s * 0.26);
				g.moveTo(x + s * 0.62, y + s * 0.26);
				g.lineTo(x + s * 0.74, y + s * 0.26);
				g.lineTo(x + s * 0.74, y + s * 0.38);
				g.moveTo(x + s * 0.74, y + s * 0.62);
				g.lineTo(x + s * 0.74, y + s * 0.74);
				g.lineTo(x + s * 0.62, y + s * 0.74);
				g.moveTo(x + s * 0.38, y + s * 0.74);
				g.lineTo(x + s * 0.26, y + s * 0.74);
				g.lineTo(x + s * 0.26, y + s * 0.62);
				g.lineStyle();
			case PIN:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.38, s * 0.14);
				g.moveTo(x + s * 0.4, y + s * 0.46);
				g.lineTo(x + s * 0.6, y + s * 0.46);
				g.lineTo(x + s * 0.5, y + s * 0.76);
				g.endFill();
			case DOT:
				g.beginFill(c, a);
				g.drawCircle(x + s * 0.5, y + s * 0.5, s * 0.16);
				g.endFill();
		}
	}

	/**
		Draws a speaker body fill (shared by `VOLUME`/`MUTE`).
		@param g the target graphics
		@param x the icon box left edge
		@param y the icon box top edge
		@param s the icon box edge length
		@param c the RGB tint
		@param a opacity 0..1
	**/
	static function speaker(g:Graphics, x:Float, y:Float, s:Float, c:Int, a:Float):Void {
		g.beginFill(c, a);
		g.moveTo(x + s * 0.2, y + s * 0.4);
		g.lineTo(x + s * 0.34, y + s * 0.4);
		g.lineTo(x + s * 0.5, y + s * 0.26);
		g.lineTo(x + s * 0.5, y + s * 0.74);
		g.lineTo(x + s * 0.34, y + s * 0.6);
		g.lineTo(x + s * 0.2, y + s * 0.6);
		g.endFill();
	}

	/**
		Strokes a two-segment chevron (fractions of the icon box).
		@param g the target graphics
		@param x the icon box left edge
		@param y the icon box top edge
		@param s the icon box edge length
		@param t the stroke thickness
		@param c the RGB tint
		@param a opacity 0..1
		@param x1 first point x fraction
		@param y1 first point y fraction
		@param x2 apex x fraction
		@param y2 apex y fraction
		@param x3 last point x fraction
		@param y3 last point y fraction
	**/
	static function chev(g:Graphics, x:Float, y:Float, s:Float, t:Float, c:Int, a:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Void {
		g.lineStyle(t, c, a);
		g.moveTo(x + s * x1, y + s * y1);
		g.lineTo(x + s * x2, y + s * y2);
		g.lineTo(x + s * x3, y + s * y3);
		g.lineStyle();
	}

	/**
		Strokes an arrow: shaft from tail to tip plus two head barbs (fractions of the icon box).
		@param g the target graphics
		@param x the icon box left edge
		@param y the icon box top edge
		@param s the icon box edge length
		@param t the stroke thickness
		@param c the RGB tint
		@param a opacity 0..1
		@param tx tail x fraction
		@param ty tail y fraction
		@param hx tip x fraction
		@param hy tip y fraction
		@param b1x first barb end x fraction
		@param b1y first barb end y fraction
		@param b2x second barb end x fraction
		@param b2y second barb end y fraction
	**/
	static function arrow(g:Graphics, x:Float, y:Float, s:Float, t:Float, c:Int, a:Float, tx:Float, ty:Float, hx:Float, hy:Float, b1x:Float, b1y:Float,
			b2x:Float, b2y:Float):Void {
		g.lineStyle(t, c, a);
		g.moveTo(x + s * tx, y + s * ty);
		g.lineTo(x + s * hx, y + s * hy);
		g.moveTo(x + s * hx, y + s * hy);
		g.lineTo(x + s * b1x, y + s * b1y);
		g.moveTo(x + s * hx, y + s * hy);
		g.lineTo(x + s * b2x, y + s * b2y);
		g.lineStyle();
	}

	/**
		Appends a segmented arc to the current path (usable inside strokes and fills).
		@param g the target graphics
		@param cx the arc centre x
		@param cy the arc centre y
		@param r the radius
		@param a0 the start angle in radians
		@param a1 the end angle in radians
		@param move `true` starts with `moveTo`, `false` continues the current path with `lineTo`
	**/
	static function arcPath(g:Graphics, cx:Float, cy:Float, r:Float, a0:Float, a1:Float, move:Bool):Void {
		var steps:Int = Std.int(Math.abs(a1 - a0) / 0.3) + 2;
		var da:Float = (a1 - a0) / steps;
		var ang:Float = a0;
		if (move)
			g.moveTo(cx + Math.cos(ang) * r, cy + Math.sin(ang) * r);
		else
			g.lineTo(cx + Math.cos(ang) * r, cy + Math.sin(ang) * r);
		var i:Int = 0;
		while (i < steps) {
			ang += da;
			g.lineTo(cx + Math.cos(ang) * r, cy + Math.sin(ang) * r);
			i++;
		}
	}
}
