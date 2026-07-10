package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;
import smidr.types.UIAlign;
import smidr.widgets.UIList.UIListRow;

/**
	A virtualized data table: a fixed header of columns above a `UIList` of rows, where each row
	draws one text cell per column. Only on-screen rows exist as display objects (inherited from
	`UIList`), so a table of any height stays cheap.

	Data is provider-driven (`setData(rowCount, cellProvider)`): the grid never copies the source,
	it just asks for `cell(row, column)` text on demand. Clicking a sortable column header sorts a
	display-order permutation in place (the source is untouched); selection is reported and kept in
	SOURCE row indices across sorts.
**/
class UIDataGrid extends UIComponent {
	/** Fired when the selected row changes (source row index, or -1). **/
	public var onSelect:Int->Void = null;

	/** Fired on double click / Enter (source row index). **/
	public var onActivate:Int->Void = null;

	/** The backing virtualized list. **/
	public var list(default, null):UIList;

	/** The selected SOURCE row index, or -1. **/
	public var selectedRow(get, never):Int;

	/** The sorted column, or -1. **/
	public var sortColumn(default, null):Int = -1;

	/** Sort direction of `sortColumn`. **/
	public var sortAscending(default, null):Bool = true;

	/** Base (unscaled) header height. **/
	public var headerHeightBase:Float = 28;

	var columns:Array<UIDataColumn> = [];
	var sourceRowCount:Int = 0;
	var cellProvider:Int->Int->String = null;
	var order:Array<Int> = [];
	var header:UIDataGridHeader;

	/**
		@param width layout width
		@param height total height (header + rows)
		@param rowHeight base (unscaled) row height; 0 picks the platform default
	**/
	public function new(width:Float, height:Float, rowHeight:Float = 0) {
		super(false, false);
		header = new UIDataGridHeader(this);
		list = new UIList(width, height, rowHeight);
		list.rowFactory = function(owner:UIList):UIListRow return new UIDataRow(owner, this);
		list.onSelect = function(index:Int):Void {
			if (onSelect != null)
				onSelect(sourceOf(index));
		};
		list.onActivate = function(index:Int):Void {
			if (onActivate != null)
				onActivate(sourceOf(index));
		};
		addChild(list);
		addChild(header);
		resize(width, height);
	}

	inline function sourceOf(displayIndex:Int):Int {
		return (displayIndex >= 0 && displayIndex < order.length) ? order[displayIndex] : -1;
	}

	inline function get_selectedRow():Int {
		return sourceOf(list.selectedIndex);
	}

	/**
		Sets the columns and repaints the header.
		@param columns the column definitions (widths in base/unscaled units)
	**/
	public function setColumns(columns:Array<UIDataColumn>):Void {
		this.columns = (columns != null) ? columns : [];
		sortColumn = -1;
		header.invalidate();
		list.refresh();
	}

	/**
		Sets the row data source. `cell(row, column)` is asked for text lazily.
		@param rowCount the number of source rows
		@param cell resolves a cell's text for a (source row, column) pair
	**/
	public function setData(rowCount:Int, cell:Int->Int->String):Void {
		sourceRowCount = (rowCount > 0) ? rowCount : 0;
		cellProvider = cell;
		rebuildOrder();
		if (sortColumn >= 0)
			applySort();
		list.setProvider(order.length, function(_:Int):String return "");
	}

	/** Rebinds the visible rows after mutating cell values in place. **/
	public inline function refresh():Void {
		list.refresh();
	}

	/**
		Sorts by a column (toggles direction when already sorted by it).
		@param column the column index (ignored if not `sortable`)
	**/
	public function sortBy(column:Int):Void {
		if (column < 0 || column >= columns.length || !columns[column].sortable)
			return;
		if (sortColumn == column)
			sortAscending = !sortAscending;
		else {
			sortColumn = column;
			sortAscending = true;
		}
		var keepSource:Int = selectedRow;
		applySort();
		header.invalidate();
		list.refresh();
		if (keepSource >= 0) {
			var displayIndex:Int = order.indexOf(keepSource);
			if (displayIndex >= 0)
				list.select(displayIndex);
		}
	}

	function rebuildOrder():Void {
		order.resize(sourceRowCount);
		for (i in 0...sourceRowCount)
			order[i] = i;
	}

	function applySort():Void {
		if (sortColumn < 0 || cellProvider == null)
			return;
		var column:Int = sortColumn;
		var numeric:Bool = columns[column].numeric;
		var sign:Int = sortAscending ? 1 : -1;
		order.sort(function(a:Int, b:Int):Int {
			var textA:String = cellProvider(a, column);
			var textB:String = cellProvider(b, column);
			if (numeric) {
				var numA:Float = Std.parseFloat(textA);
				var numB:Float = Std.parseFloat(textB);
				if (Math.isNaN(numA))
					numA = 0;
				if (Math.isNaN(numB))
					numB = 0;
				return (numA < numB) ? -sign : (numA > numB ? sign : 0);
			}
			var lowerA:String = textA.toLowerCase();
			var lowerB:String = textB.toLowerCase();
			return (lowerA < lowerB) ? -sign : (lowerA > lowerB ? sign : 0);
		});
	}

	@:allow(smidr.widgets.UIDataGridHeader)
	@:allow(smidr.widgets.UIDataRow)
	inline function columnCount():Int
		return columns.length;

	@:allow(smidr.widgets.UIDataGridHeader)
	@:allow(smidr.widgets.UIDataRow)
	function columnAt(column:Int):UIDataColumn
		return columns[column];

	@:allow(smidr.widgets.UIDataGridHeader)
	@:allow(smidr.widgets.UIDataRow)
	function columnX(column:Int):Float {
		var x:Float = 0;
		for (i in 0...column)
			x += UITheme.px(columns[i].width);
		return x;
	}

	@:allow(smidr.widgets.UIDataRow)
	function cellText(displayIndex:Int, column:Int):String {
		if (cellProvider == null)
			return "";
		var source:Int = sourceOf(displayIndex);
		return (source >= 0) ? cellProvider(source, column) : "";
	}

	@:allow(smidr.widgets.UIDataGridHeader)
	function headerClicked(localX:Float):Void {
		var x:Float = 0;
		for (i in 0...columns.length) {
			var next:Float = x + UITheme.px(columns[i].width);
			if (localX >= x && localX < next) {
				sortBy(i);
				return;
			}
			x = next;
		}
	}

	override public function render():Void {
		var headerHeight:Float = UITheme.px(headerHeightBase);
		header.resize(w, headerHeight);
		header.y = 0;
		list.y = headerHeight;
		list.resize(w, h - headerHeight);
	}
}

/**
	One column of a `UIDataGrid`: a title, a base (unscaled) width, cell alignment, and whether
	the header sorts by it (numerically when `numeric`).
**/
class UIDataColumn {
	/** The header title. **/
	public var title:String;

	/** Base (unscaled) column width. **/
	public var width:Float;

	/** Cell text alignment. **/
	public var align:UIAlign;

	/** Whether clicking the header sorts by this column. **/
	public var sortable:Bool;

	/** Sort this column as numbers rather than text. **/
	public var numeric:Bool;

	/**
		@param title the header title
		@param width base (unscaled) column width
		@param align cell alignment (default `START`)
		@param sortable whether the header sorts by this column (default `true`)
		@param numeric sort as numbers rather than text (default `false`)
	**/
	public function new(title:String, width:Float, align:UIAlign = START, sortable:Bool = true, numeric:Bool = false) {
		this.title = title;
		this.width = width;
		this.align = align;
		this.sortable = sortable;
		this.numeric = numeric;
	}
}

/** The grid's fixed header: column titles, a sort arrow on the active column, click to sort. **/
private class UIDataGridHeader extends UIComponent {
	final grid:UIDataGrid;
	var titleFields:Array<TextField> = [];

	public function new(grid:UIDataGrid) {
		super(true, true);
		this.grid = grid;
		hoverCursor = null;
	}

	override function onPress(localX:Float, localY:Float):Void {
		grid.headerClicked(localX);
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.drawRect(0, 0, w, h);
		g.endFill();
		g.beginFill(UIColor.rgb(UITheme.border));
		g.drawRect(0, h - 1, w, 1);
		g.endFill();

		var count:Int = grid.columnCount();
		while (titleFields.length > count) {
			var extra:TextField = titleFields.pop();
			if (extra.parent != null)
				extra.parent.removeChild(extra);
		}
		while (titleFields.length < count) {
			var field:TextField = UIFonts.make(UITheme.fs(11), UITheme.text2);
			addChild(field);
			titleFields.push(field);
		}

		var padLeft:Float = UITheme.px(10);
		var padRight:Float = UITheme.px(10);
		for (i in 0...count) {
			var column:UIDataColumn = grid.columnAt(i);
			var cellX:Float = grid.columnX(i);
			var cellW:Float = UITheme.px(column.width);
			if (i > 0) {
				g.beginFill(UIColor.rgb(UITheme.border), 0.5);
				g.drawRect(cellX, UITheme.px(7), 1, h - UITheme.px(14));
				g.endFill();
			}

			var field:TextField = titleFields[i];
			UIFonts.restyle(field, UITheme.fs(11), UITheme.text2);
			if (field.text != column.title)
				field.text = column.title;
			var textW:Float = field.width;
			var arrowSpace:Float = (grid.sortColumn == i) ? UITheme.px(12) : 0;
			var available:Float = cellW - padLeft - padRight - arrowSpace;
			var textX:Float = switch (column.align) {
				case CENTER: cellX + padLeft + (available - textW) / 2;
				case END: cellX + cellW - padRight - arrowSpace - textW;
				default: cellX + padLeft;
			};
			field.x = textX;
			field.y = (h - field.height) / 2;

			if (grid.sortColumn == i) {
				var arrowX:Float = cellX + cellW - padRight - UITheme.px(6);
				var arrowY:Float = h / 2;
				var reach:Float = UITheme.px(3);
				g.beginFill(UIColor.rgb(UITheme.accent));
				if (grid.sortAscending) {
					g.moveTo(arrowX - reach, arrowY + reach * 0.6);
					g.lineTo(arrowX + reach, arrowY + reach * 0.6);
					g.lineTo(arrowX, arrowY - reach * 0.8);
				} else {
					g.moveTo(arrowX - reach, arrowY - reach * 0.6);
					g.lineTo(arrowX + reach, arrowY - reach * 0.6);
					g.lineTo(arrowX, arrowY + reach * 0.8);
				}
				g.endFill();
			}
		}
	}
}

/** One data row: draws a text cell per column plus the shared selection/hover background. **/
private class UIDataRow extends UIListRow {
	final grid:UIDataGrid;
	var cellFields:Array<TextField> = [];

	public function new(owner:UIList, grid:UIDataGrid) {
		super(owner);
		this.grid = grid;
	}

	override public function bind(index:Int):Void {
		var count:Int = grid.columnCount();
		while (cellFields.length > count) {
			var extra:TextField = cellFields.pop();
			if (extra.parent != null)
				extra.parent.removeChild(extra);
		}
		while (cellFields.length < count) {
			var field:TextField = UIFonts.make(UITheme.fs(11), UITheme.text2);
			addChild(field);
			cellFields.push(field);
		}
		for (i in 0...count) {
			var text:String = grid.cellText(index, i);
			if (cellFields[i].text != text)
				cellFields[i].text = text;
		}
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var selected:Bool = (index >= 0 && index == owner.selectedIndex);
		if (selected) {
			g.beginFill(UIColor.rgb(UITheme.panel3));
			g.drawRect(0, 0, w, h);
			g.endFill();
		} else if (hovered) {
			g.beginFill(UIColor.rgb(UITheme.panel3), 0.5);
			g.drawRect(0, 0, w, h);
			g.endFill();
		} else {
			g.beginFill(0, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();
		}

		var count:Int = grid.columnCount();
		if (cellFields.length < count)
			return;
		var padLeft:Float = UITheme.px(10);
		var padRight:Float = UITheme.px(10);
		for (i in 0...count) {
			var column:UIDataColumn = grid.columnAt(i);
			var cellX:Float = grid.columnX(i);
			var cellW:Float = UITheme.px(column.width);
			var field:TextField = cellFields[i];
			UIFonts.restyle(field, UITheme.fs(11), selected ? UITheme.text : UITheme.text2);
			var textW:Float = field.width;
			var available:Float = cellW - padLeft - padRight;
			field.x = switch (column.align) {
				case CENTER: cellX + padLeft + (available - textW) / 2;
				case END: cellX + cellW - padRight - textW;
				default: cellX + padLeft;
			};
			field.y = (h - field.height) / 2;
		}
	}
}
