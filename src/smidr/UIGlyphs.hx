package smidr;

import openfl.display.Graphics;
import smidr.types.UIGlyph;

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
	public static function draw(graphics:Graphics, glyph:UIGlyph, x:Float, y:Float, size:Float, color:Int, alpha:Float = 1):Void {
		var rgb:Int = color & 0xFFFFFF;
		var thickness:Float = size * 0.1;
		if (thickness < 1.5)
			thickness = 1.5;
		switch (glyph) {
			case PLAY:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.34, y + size * 0.26);
				graphics.lineTo(x + size * 0.34, y + size * 0.74);
				graphics.lineTo(x + size * 0.78, y + size * 0.5);
				graphics.endFill();
			case PAUSE:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.3, y + size * 0.28, size * 0.15, size * 0.44);
				graphics.drawRect(x + size * 0.55, y + size * 0.28, size * 0.15, size * 0.44);
				graphics.endFill();
			case STOP:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.3, y + size * 0.3, size * 0.4, size * 0.4);
				graphics.endFill();
			case PREV:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.26, y + size * 0.3, size * 0.08, size * 0.4);
				graphics.moveTo(x + size * 0.74, y + size * 0.3);
				graphics.lineTo(x + size * 0.74, y + size * 0.7);
				graphics.lineTo(x + size * 0.42, y + size * 0.5);
				graphics.endFill();
			case NEXT:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.66, y + size * 0.3, size * 0.08, size * 0.4);
				graphics.moveTo(x + size * 0.26, y + size * 0.3);
				graphics.lineTo(x + size * 0.26, y + size * 0.7);
				graphics.lineTo(x + size * 0.58, y + size * 0.5);
				graphics.endFill();
			case RECORD:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.22);
				graphics.endFill();
			case LOOP:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.2);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.6, y + size * 0.2);
				graphics.lineTo(x + size * 0.8, y + size * 0.3);
				graphics.lineTo(x + size * 0.6, y + size * 0.42);
				graphics.endFill();
			case SHUFFLE:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.22, y + size * 0.34);
				graphics.lineTo(x + size * 0.4, y + size * 0.34);
				graphics.lineTo(x + size * 0.6, y + size * 0.62);
				graphics.lineTo(x + size * 0.72, y + size * 0.62);
				graphics.moveTo(x + size * 0.22, y + size * 0.62);
				graphics.lineTo(x + size * 0.4, y + size * 0.62);
				graphics.lineTo(x + size * 0.6, y + size * 0.34);
				graphics.lineTo(x + size * 0.72, y + size * 0.34);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.7, y + size * 0.27);
				graphics.lineTo(x + size * 0.84, y + size * 0.34);
				graphics.lineTo(x + size * 0.7, y + size * 0.41);
				graphics.moveTo(x + size * 0.7, y + size * 0.55);
				graphics.lineTo(x + size * 0.84, y + size * 0.62);
				graphics.lineTo(x + size * 0.7, y + size * 0.69);
				graphics.endFill();
			case VOLUME:
				speaker(graphics, x, y, size, rgb, alpha);
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.6, y + size * 0.38);
				graphics.curveTo(x + size * 0.72, y + size * 0.5, x + size * 0.6, y + size * 0.62);
				graphics.moveTo(x + size * 0.66, y + size * 0.28);
				graphics.curveTo(x + size * 0.86, y + size * 0.5, x + size * 0.66, y + size * 0.72);
				graphics.lineStyle();
			case MUTE:
				speaker(graphics, x, y, size, rgb, alpha);
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.6, y + size * 0.4);
				graphics.lineTo(x + size * 0.8, y + size * 0.6);
				graphics.moveTo(x + size * 0.8, y + size * 0.4);
				graphics.lineTo(x + size * 0.6, y + size * 0.6);
				graphics.lineStyle();
			case PLUS:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.28, y + size * 0.46, size * 0.44, size * 0.08);
				graphics.drawRect(x + size * 0.46, y + size * 0.28, size * 0.08, size * 0.44);
				graphics.endFill();
			case MINUS:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.28, y + size * 0.46, size * 0.44, size * 0.08);
				graphics.endFill();
			case CLOSE:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.3, y + size * 0.3);
				graphics.lineTo(x + size * 0.7, y + size * 0.7);
				graphics.moveTo(x + size * 0.7, y + size * 0.3);
				graphics.lineTo(x + size * 0.3, y + size * 0.7);
				graphics.lineStyle();
			case CHECK:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.26, y + size * 0.52);
				graphics.lineTo(x + size * 0.44, y + size * 0.7);
				graphics.lineTo(x + size * 0.76, y + size * 0.32);
				graphics.lineStyle();
			case SEARCH:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawCircle(x + size * 0.44, y + size * 0.44, size * 0.18);
				graphics.moveTo(x + size * 0.58, y + size * 0.58);
				graphics.lineTo(x + size * 0.76, y + size * 0.76);
				graphics.lineStyle();
			case GEAR:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.17);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				var gi:Int = 0;
				while (gi < 4) {
					var ang:Float = gi * 1.5707963;
					var gx:Float = x + size * 0.5 + Math.cos(ang) * size * 0.27;
					var gy:Float = y + size * 0.5 + Math.sin(ang) * size * 0.27;
					graphics.drawRect(gx - size * 0.05, gy - size * 0.05, size * 0.1, size * 0.1);
					gi++;
				}
				graphics.endFill();
			case REFRESH:
				graphics.lineStyle(thickness, rgb, alpha);
				arcPath(graphics, x + size * 0.5, y + size * 0.5, size * 0.22, -0.4, 4.6, true);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.66, y + size * 0.28);
				graphics.lineTo(x + size * 0.84, y + size * 0.36);
				graphics.lineTo(x + size * 0.68, y + size * 0.48);
				graphics.endFill();
			case TRASH:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.28, y + size * 0.26, size * 0.44, size * 0.07);
				graphics.drawRect(x + size * 0.42, y + size * 0.2, size * 0.16, size * 0.06);
				graphics.endFill();
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawRoundRect(x + size * 0.33, y + size * 0.39, size * 0.34, size * 0.36, size * 0.06, size * 0.06);
				graphics.moveTo(x + size * 0.44, y + size * 0.46);
				graphics.lineTo(x + size * 0.44, y + size * 0.68);
				graphics.moveTo(x + size * 0.56, y + size * 0.46);
				graphics.lineTo(x + size * 0.56, y + size * 0.68);
				graphics.lineStyle();
			case EDIT:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.3, y + size * 0.6);
				graphics.lineTo(x + size * 0.6, y + size * 0.3);
				graphics.lineTo(x + size * 0.7, y + size * 0.4);
				graphics.lineTo(x + size * 0.4, y + size * 0.7);
				graphics.moveTo(x + size * 0.3, y + size * 0.6);
				graphics.lineTo(x + size * 0.4, y + size * 0.7);
				graphics.lineTo(x + size * 0.25, y + size * 0.75);
				graphics.endFill();
			case COPY:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawRoundRect(x + size * 0.28, y + size * 0.28, size * 0.34, size * 0.34, size * 0.06, size * 0.06);
				graphics.drawRoundRect(x + size * 0.4, y + size * 0.4, size * 0.34, size * 0.34, size * 0.06, size * 0.06);
				graphics.lineStyle();
			case DOWNLOAD:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.46, y + size * 0.24, size * 0.08, size * 0.26);
				graphics.moveTo(x + size * 0.34, y + size * 0.48);
				graphics.lineTo(x + size * 0.66, y + size * 0.48);
				graphics.lineTo(x + size * 0.5, y + size * 0.64);
				graphics.drawRect(x + size * 0.28, y + size * 0.72, size * 0.44, size * 0.07);
				graphics.endFill();
			case UPLOAD:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.5, y + size * 0.22);
				graphics.lineTo(x + size * 0.66, y + size * 0.38);
				graphics.lineTo(x + size * 0.34, y + size * 0.38);
				graphics.drawRect(x + size * 0.46, y + size * 0.38, size * 0.08, size * 0.26);
				graphics.drawRect(x + size * 0.28, y + size * 0.72, size * 0.44, size * 0.07);
				graphics.endFill();
			case EXTERNAL:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawRoundRect(x + size * 0.26, y + size * 0.34, size * 0.4, size * 0.4, size * 0.06, size * 0.06);
				graphics.moveTo(x + size * 0.5, y + size * 0.5);
				graphics.lineTo(x + size * 0.74, y + size * 0.26);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.6, y + size * 0.22);
				graphics.lineTo(x + size * 0.78, y + size * 0.22);
				graphics.lineTo(x + size * 0.78, y + size * 0.4);
				graphics.endFill();
			case FILTER:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.24, y + size * 0.26);
				graphics.lineTo(x + size * 0.76, y + size * 0.26);
				graphics.lineTo(x + size * 0.57, y + size * 0.52);
				graphics.lineTo(x + size * 0.57, y + size * 0.72);
				graphics.lineTo(x + size * 0.43, y + size * 0.64);
				graphics.lineTo(x + size * 0.43, y + size * 0.52);
				graphics.endFill();
			case CHEVRON_LEFT:
				chev(graphics, x, y, size, thickness, rgb, alpha, 0.58, 0.3, 0.4, 0.5, 0.58, 0.7);
			case CHEVRON_RIGHT:
				chev(graphics, x, y, size, thickness, rgb, alpha, 0.42, 0.3, 0.6, 0.5, 0.42, 0.7);
			case CHEVRON_UP:
				chev(graphics, x, y, size, thickness, rgb, alpha, 0.3, 0.58, 0.5, 0.4, 0.7, 0.58);
			case CHEVRON_DOWN:
				chev(graphics, x, y, size, thickness, rgb, alpha, 0.3, 0.42, 0.5, 0.6, 0.7, 0.42);
			case ARROW_LEFT:
				arrow(graphics, x, y, size, thickness, rgb, alpha, 0.74, 0.5, 0.28, 0.5, 0.44, 0.34, 0.44, 0.66);
			case ARROW_RIGHT:
				arrow(graphics, x, y, size, thickness, rgb, alpha, 0.26, 0.5, 0.72, 0.5, 0.56, 0.34, 0.56, 0.66);
			case ARROW_UP:
				arrow(graphics, x, y, size, thickness, rgb, alpha, 0.5, 0.74, 0.5, 0.28, 0.34, 0.44, 0.66, 0.44);
			case ARROW_DOWN:
				arrow(graphics, x, y, size, thickness, rgb, alpha, 0.5, 0.26, 0.5, 0.72, 0.34, 0.56, 0.66, 0.56);
			case MENU:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.26, y + size * 0.32, size * 0.48, size * 0.07);
				graphics.drawRect(x + size * 0.26, y + size * 0.465, size * 0.48, size * 0.07);
				graphics.drawRect(x + size * 0.26, y + size * 0.61, size * 0.48, size * 0.07);
				graphics.endFill();
			case MORE:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.3, y + size * 0.5, size * 0.055);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.055);
				graphics.drawCircle(x + size * 0.7, y + size * 0.5, size * 0.055);
				graphics.endFill();
			case FILE:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.32, y + size * 0.24);
				graphics.lineTo(x + size * 0.56, y + size * 0.24);
				graphics.lineTo(x + size * 0.68, y + size * 0.36);
				graphics.lineTo(x + size * 0.68, y + size * 0.76);
				graphics.lineTo(x + size * 0.32, y + size * 0.76);
				graphics.lineTo(x + size * 0.32, y + size * 0.24);
				graphics.moveTo(x + size * 0.56, y + size * 0.24);
				graphics.lineTo(x + size * 0.56, y + size * 0.36);
				graphics.lineTo(x + size * 0.68, y + size * 0.36);
				graphics.lineStyle();
			case FOLDER:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.22, y + size * 0.3);
				graphics.lineTo(x + size * 0.42, y + size * 0.3);
				graphics.lineTo(x + size * 0.48, y + size * 0.38);
				graphics.lineTo(x + size * 0.78, y + size * 0.38);
				graphics.lineTo(x + size * 0.78, y + size * 0.72);
				graphics.lineTo(x + size * 0.22, y + size * 0.72);
				graphics.endFill();
			case FOLDER_OPEN:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.22, y + size * 0.68);
				graphics.lineTo(x + size * 0.22, y + size * 0.3);
				graphics.lineTo(x + size * 0.4, y + size * 0.3);
				graphics.lineTo(x + size * 0.46, y + size * 0.38);
				graphics.lineTo(x + size * 0.72, y + size * 0.38);
				graphics.lineTo(x + size * 0.72, y + size * 0.44);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.28, y + size * 0.46);
				graphics.lineTo(x + size * 0.84, y + size * 0.46);
				graphics.lineTo(x + size * 0.74, y + size * 0.7);
				graphics.lineTo(x + size * 0.2, y + size * 0.7);
				graphics.endFill();
			case IMAGE:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawRoundRect(x + size * 0.24, y + size * 0.28, size * 0.52, size * 0.44, size * 0.06, size * 0.06);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.38, y + size * 0.4, size * 0.045);
				graphics.moveTo(x + size * 0.3, y + size * 0.66);
				graphics.lineTo(x + size * 0.48, y + size * 0.46);
				graphics.lineTo(x + size * 0.62, y + size * 0.66);
				graphics.moveTo(x + size * 0.54, y + size * 0.66);
				graphics.lineTo(x + size * 0.62, y + size * 0.56);
				graphics.lineTo(x + size * 0.72, y + size * 0.66);
				graphics.endFill();
			case SAVE:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.26, y + size * 0.26);
				graphics.lineTo(x + size * 0.64, y + size * 0.26);
				graphics.lineTo(x + size * 0.74, y + size * 0.36);
				graphics.lineTo(x + size * 0.74, y + size * 0.74);
				graphics.lineTo(x + size * 0.26, y + size * 0.74);
				graphics.lineTo(x + size * 0.26, y + size * 0.26);
				graphics.drawRect(x + size * 0.36, y + size * 0.5, size * 0.28, size * 0.24);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.38, y + size * 0.26, size * 0.2, size * 0.13);
				graphics.endFill();
			case CLIPBOARD:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawRoundRect(x + size * 0.3, y + size * 0.28, size * 0.4, size * 0.5, size * 0.06, size * 0.06);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawRoundRect(x + size * 0.4, y + size * 0.22, size * 0.2, size * 0.1, size * 0.05, size * 0.05);
				graphics.endFill();
			case INFO:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.24);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.37, size * 0.04);
				graphics.drawRect(x + size * 0.465, y + size * 0.45, size * 0.07, size * 0.2);
				graphics.endFill();
			case WARNING:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.5, y + size * 0.24);
				graphics.lineTo(x + size * 0.78, y + size * 0.74);
				graphics.lineTo(x + size * 0.22, y + size * 0.74);
				graphics.lineTo(x + size * 0.5, y + size * 0.24);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.465, y + size * 0.42, size * 0.07, size * 0.15);
				graphics.drawCircle(x + size * 0.5, y + size * 0.65, size * 0.04);
				graphics.endFill();
			case ERROR:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.24);
				graphics.moveTo(x + size * 0.4, y + size * 0.4);
				graphics.lineTo(x + size * 0.6, y + size * 0.6);
				graphics.moveTo(x + size * 0.6, y + size * 0.4);
				graphics.lineTo(x + size * 0.4, y + size * 0.6);
				graphics.lineStyle();
			case HOME:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.5, y + size * 0.22);
				graphics.lineTo(x + size * 0.8, y + size * 0.48);
				graphics.lineTo(x + size * 0.2, y + size * 0.48);
				graphics.drawRect(x + size * 0.3, y + size * 0.48, size * 0.4, size * 0.28);
				graphics.endFill();
			case LOCK:
				graphics.lineStyle(thickness, rgb, alpha);
				arcPath(graphics, x + size * 0.5, y + size * 0.44, size * 0.13, 3.14159, 6.28318, true);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawRoundRect(x + size * 0.32, y + size * 0.44, size * 0.36, size * 0.32, size * 0.08, size * 0.08);
				graphics.endFill();
			case UNLOCK:
				graphics.lineStyle(thickness, rgb, alpha);
				arcPath(graphics, x + size * 0.5, y + size * 0.42, size * 0.13, 3.14159, 5.5, true);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawRoundRect(x + size * 0.32, y + size * 0.44, size * 0.36, size * 0.32, size * 0.08, size * 0.08);
				graphics.endFill();
			case EYE:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.22, y + size * 0.5);
				graphics.curveTo(x + size * 0.5, y + size * 0.22, x + size * 0.78, y + size * 0.5);
				graphics.curveTo(x + size * 0.5, y + size * 0.78, x + size * 0.22, y + size * 0.5);
				graphics.lineStyle();
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.09);
				graphics.endFill();
			case STAR:
				graphics.beginFill(rgb, alpha);
				var si:Int = 0;
				var cx:Float = x + size * 0.5;
				var cy:Float = y + size * 0.52;
				while (si < 10) {
					var radius:Float = (si & 1 == 0) ? size * 0.28 : size * 0.115;
					var ang:Float = -1.5707963 + si * 0.62831853;
					var px:Float = cx + Math.cos(ang) * radius;
					var py:Float = cy + Math.sin(ang) * radius;
					if (si == 0)
						graphics.moveTo(px, py);
					else
						graphics.lineTo(px, py);
					si++;
				}
				graphics.endFill();
			case HEART:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.5, y + size * 0.74);
				graphics.curveTo(x + size * 0.14, y + size * 0.48, x + size * 0.3, y + size * 0.3);
				graphics.curveTo(x + size * 0.42, y + size * 0.2, x + size * 0.5, y + size * 0.36);
				graphics.curveTo(x + size * 0.58, y + size * 0.2, x + size * 0.7, y + size * 0.3);
				graphics.curveTo(x + size * 0.86, y + size * 0.48, x + size * 0.5, y + size * 0.74);
				graphics.endFill();
			case BELL:
				graphics.beginFill(rgb, alpha);
				graphics.moveTo(x + size * 0.26, y + size * 0.64);
				graphics.lineTo(x + size * 0.74, y + size * 0.64);
				graphics.lineTo(x + size * 0.66, y + size * 0.55);
				graphics.lineTo(x + size * 0.66, y + size * 0.42);
				graphics.curveTo(x + size * 0.66, y + size * 0.27, x + size * 0.5, y + size * 0.27);
				graphics.curveTo(x + size * 0.34, y + size * 0.27, x + size * 0.34, y + size * 0.42);
				graphics.lineTo(x + size * 0.34, y + size * 0.55);
				graphics.moveTo(x + size * 0.5, y + size * 0.74);
				graphics.drawCircle(x + size * 0.5, y + size * 0.72, size * 0.05);
				graphics.endFill();
			case CLOCK:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.24);
				graphics.moveTo(x + size * 0.5, y + size * 0.36);
				graphics.lineTo(x + size * 0.5, y + size * 0.52);
				graphics.lineTo(x + size * 0.62, y + size * 0.58);
				graphics.lineStyle();
			case POWER:
				graphics.lineStyle(thickness, rgb, alpha);
				arcPath(graphics, x + size * 0.5, y + size * 0.54, size * 0.2, -1.02, 4.16, true);
				graphics.moveTo(x + size * 0.5, y + size * 0.22);
				graphics.lineTo(x + size * 0.5, y + size * 0.48);
				graphics.lineStyle();
			case USER:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.36, size * 0.12);
				graphics.moveTo(x + size * 0.26, y + size * 0.78);
				arcPath(graphics, x + size * 0.5, y + size * 0.78, size * 0.24, 3.14159, 6.28318, false);
				graphics.endFill();
			case GRID:
				graphics.beginFill(rgb, alpha);
				graphics.drawRect(x + size * 0.26, y + size * 0.26, size * 0.2, size * 0.2);
				graphics.drawRect(x + size * 0.54, y + size * 0.26, size * 0.2, size * 0.2);
				graphics.drawRect(x + size * 0.26, y + size * 0.54, size * 0.2, size * 0.2);
				graphics.drawRect(x + size * 0.54, y + size * 0.54, size * 0.2, size * 0.2);
				graphics.endFill();
			case LIST:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.3, y + size * 0.34, size * 0.04);
				graphics.drawCircle(x + size * 0.3, y + size * 0.5, size * 0.04);
				graphics.drawCircle(x + size * 0.3, y + size * 0.66, size * 0.04);
				graphics.drawRect(x + size * 0.4, y + size * 0.31, size * 0.34, size * 0.06);
				graphics.drawRect(x + size * 0.4, y + size * 0.47, size * 0.34, size * 0.06);
				graphics.drawRect(x + size * 0.4, y + size * 0.63, size * 0.34, size * 0.06);
				graphics.endFill();
			case DRAG:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.42, y + size * 0.32, size * 0.045);
				graphics.drawCircle(x + size * 0.58, y + size * 0.32, size * 0.045);
				graphics.drawCircle(x + size * 0.42, y + size * 0.5, size * 0.045);
				graphics.drawCircle(x + size * 0.58, y + size * 0.5, size * 0.045);
				graphics.drawCircle(x + size * 0.42, y + size * 0.68, size * 0.045);
				graphics.drawCircle(x + size * 0.58, y + size * 0.68, size * 0.045);
				graphics.endFill();
			case FULLSCREEN:
				graphics.lineStyle(thickness, rgb, alpha);
				graphics.moveTo(x + size * 0.26, y + size * 0.38);
				graphics.lineTo(x + size * 0.26, y + size * 0.26);
				graphics.lineTo(x + size * 0.38, y + size * 0.26);
				graphics.moveTo(x + size * 0.62, y + size * 0.26);
				graphics.lineTo(x + size * 0.74, y + size * 0.26);
				graphics.lineTo(x + size * 0.74, y + size * 0.38);
				graphics.moveTo(x + size * 0.74, y + size * 0.62);
				graphics.lineTo(x + size * 0.74, y + size * 0.74);
				graphics.lineTo(x + size * 0.62, y + size * 0.74);
				graphics.moveTo(x + size * 0.38, y + size * 0.74);
				graphics.lineTo(x + size * 0.26, y + size * 0.74);
				graphics.lineTo(x + size * 0.26, y + size * 0.62);
				graphics.lineStyle();
			case PIN:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.38, size * 0.14);
				graphics.moveTo(x + size * 0.4, y + size * 0.46);
				graphics.lineTo(x + size * 0.6, y + size * 0.46);
				graphics.lineTo(x + size * 0.5, y + size * 0.76);
				graphics.endFill();
			case DOT:
				graphics.beginFill(rgb, alpha);
				graphics.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.16);
				graphics.endFill();
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
	static function speaker(graphics:Graphics, x:Float, y:Float, size:Float, color:Int, alpha:Float):Void {
		graphics.beginFill(color, alpha);
		graphics.moveTo(x + size * 0.2, y + size * 0.4);
		graphics.lineTo(x + size * 0.34, y + size * 0.4);
		graphics.lineTo(x + size * 0.5, y + size * 0.26);
		graphics.lineTo(x + size * 0.5, y + size * 0.74);
		graphics.lineTo(x + size * 0.34, y + size * 0.6);
		graphics.lineTo(x + size * 0.2, y + size * 0.6);
		graphics.endFill();
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
	static function chev(graphics:Graphics, x:Float, y:Float, size:Float, thickness:Float, color:Int, alpha:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Void {
		graphics.lineStyle(thickness, color, alpha);
		graphics.moveTo(x + size * x1, y + size * y1);
		graphics.lineTo(x + size * x2, y + size * y2);
		graphics.lineTo(x + size * x3, y + size * y3);
		graphics.lineStyle();
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
	static function arrow(graphics:Graphics, x:Float, y:Float, size:Float, thickness:Float, color:Int, alpha:Float, tx:Float, ty:Float, hx:Float, hy:Float, b1x:Float, b1y:Float,
			b2x:Float, b2y:Float):Void {
		graphics.lineStyle(thickness, color, alpha);
		graphics.moveTo(x + size * tx, y + size * ty);
		graphics.lineTo(x + size * hx, y + size * hy);
		graphics.moveTo(x + size * hx, y + size * hy);
		graphics.lineTo(x + size * b1x, y + size * b1y);
		graphics.moveTo(x + size * hx, y + size * hy);
		graphics.lineTo(x + size * b2x, y + size * b2y);
		graphics.lineStyle();
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
	static function arcPath(graphics:Graphics, cx:Float, cy:Float, radius:Float, a0:Float, a1:Float, move:Bool):Void {
		var steps:Int = Std.int(Math.abs(a1 - a0) / 0.3) + 2;
		var da:Float = (a1 - a0) / steps;
		var ang:Float = a0;
		if (move)
			graphics.moveTo(cx + Math.cos(ang) * radius, cy + Math.sin(ang) * radius);
		else
			graphics.lineTo(cx + Math.cos(ang) * radius, cy + Math.sin(ang) * radius);
		var i:Int = 0;
		while (i < steps) {
			ang += da;
			graphics.lineTo(cx + Math.cos(ang) * radius, cy + Math.sin(ang) * radius);
			i++;
		}
	}
}
