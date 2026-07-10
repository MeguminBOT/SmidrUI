package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;
import smidr.widgets.UIList.UIListRow;

/**
	A hierarchical, expandable tree. It reuses `UIList`'s virtualization: the tree keeps a
	mutable node model and flattens the currently-visible nodes (collapsed subtrees excluded)
	into a flat array, which feeds the list as its provider. So a 100k-node tree still only
	instantiates the handful of rows on screen, exactly like `UIList`.

	Rows indent by depth and draw an expand/collapse chevron for parent nodes; clicking the
	chevron toggles the branch, clicking elsewhere selects the row (Up/Down + Enter work through
	the underlying list). Build the model with `UITreeNode`s and hand the roots to `setRoots`.
**/
class UITreeView extends UIComponent {
	/** Fired when the selected node changes. **/
	public var onSelect:UITreeNode->Void = null;

	/** Fired on double click / Enter (leaves only; a parent toggles instead). **/
	public var onActivate:UITreeNode->Void = null;

	/** Fired when a branch expands (`true`) or collapses (`false`). **/
	public var onToggle:UITreeNode->Bool->Void = null;

	/** The backing virtualized list (its selection/scroll drive the tree). **/
	public var list(default, null):UIList;

	/** The currently selected node, or `null`. **/
	public var selectedNode(get, never):UITreeNode;

	var roots:Array<UITreeNode> = [];
	var flat:Array<UITreeNode> = [];

	/**
		@param width layout width
		@param height visible viewport height
		@param rowHeight base (unscaled) row height; 0 picks the platform default
	**/
	public function new(width:Float, height:Float, rowHeight:Float = 0) {
		super(false, false);
		list = new UIList(width, height, rowHeight);
		list.rowFactory = function(owner:UIList):UIListRow return new UITreeRow(owner, this);
		list.onSelect = function(index:Int):Void {
			if (onSelect != null && index >= 0 && index < flat.length)
				onSelect(flat[index]);
		};
		list.onActivate = function(index:Int):Void {
			if (index >= 0 && index < flat.length)
				activate(flat[index]);
		};
		addChild(list);
		resize(width, height);
	}

	inline function get_selectedNode():UITreeNode {
		var index:Int = list.selectedIndex;
		return (index >= 0 && index < flat.length) ? flat[index] : null;
	}

	/**
		Replaces the whole model and rebuilds the visible window.
		@param roots the top-level nodes
	**/
	public function setRoots(roots:Array<UITreeNode>):Void {
		this.roots = (roots != null) ? roots : [];
		reflatten();
	}

	/** Expands every branch, then rebuilds the visible window. **/
	public function expandAll():Void {
		setExpandedDeep(roots, true);
		reflatten();
	}

	/** Collapses every branch, then rebuilds the visible window. **/
	public function collapseAll():Void {
		setExpandedDeep(roots, false);
		reflatten();
	}

	/** Rebinds the visible rows after mutating node labels in place. **/
	public inline function refresh():Void {
		list.refresh();
	}

	function setExpandedDeep(nodes:Array<UITreeNode>, expanded:Bool):Void {
		for (node in nodes) {
			if (node.children.length > 0) {
				node.expanded = expanded;
				setExpandedDeep(node.children, expanded);
			}
		}
	}

	function reflatten():Void {
		flat.resize(0);
		flattenInto(roots, 0);
		list.setProvider(flat.length, function(index:Int):String return flat[index].label);
	}

	function flattenInto(nodes:Array<UITreeNode>, depth:Int):Void {
		for (node in nodes) {
			node.depth = depth;
			flat.push(node);
			if (node.expanded && node.children.length > 0)
				flattenInto(node.children, depth + 1);
		}
	}

	@:allow(smidr.widgets.UITreeRow)
	inline function nodeAt(index:Int):UITreeNode {
		return (index >= 0 && index < flat.length) ? flat[index] : null;
	}

	@:allow(smidr.widgets.UITreeRow)
	function toggle(node:UITreeNode):Void {
		if (node.children.length == 0)
			return;
		node.expanded = !node.expanded;
		if (onToggle != null)
			onToggle(node, node.expanded);
		reflatten();
	}

	function activate(node:UITreeNode):Void {
		if (node.children.length > 0)
			toggle(node);
		else if (onActivate != null)
			onActivate(node);
	}

	override public function render():Void {
		list.resize(w, h);
	}
}

/**
	One node in a `UITreeView` model: a label, an ordered list of children, and an expanded
	flag. `depth` is derived by the tree during flattening; treat it as read-only.
**/
class UITreeNode {
	/** The displayed text. **/
	public var label:String;

	/** Ordered child nodes (empty for a leaf). **/
	public var children:Array<UITreeNode>;

	/** Whether this branch is expanded (ignored for leaves). **/
	public var expanded:Bool;

	/** Optional user payload carried with the node. **/
	public var data:Any = null;

	/** Depth from the roots (0 at top); set by the owning tree while flattening. **/
	public var depth:Int = 0;

	/**
		@param label the displayed text
		@param children optional child nodes
		@param expanded start expanded (default collapsed)
	**/
	public function new(label:String, ?children:Array<UITreeNode>, expanded:Bool = false) {
		this.label = label;
		this.children = (children != null) ? children : [];
		this.expanded = expanded;
	}

	/** Appends a child and returns it (for fluent tree building). **/
	public function add(child:UITreeNode):UITreeNode {
		children.push(child);
		return child;
	}

	/** Whether this node has any children. **/
	public var hasChildren(get, never):Bool;

	inline function get_hasChildren():Bool
		return children.length > 0;
}

/**
	A tree row: indents by node depth, draws a chevron for parent nodes, and routes a chevron
	click to a branch toggle instead of a selection.
**/
private class UITreeRow extends UIListRow {
	final tree:UITreeView;
	var pressedChevron:Bool = false;

	public function new(owner:UIList, tree:UITreeView) {
		super(owner);
		this.tree = tree;
	}

	inline function indentOf(node:UITreeNode):Float
		return UITheme.px(8) + UITheme.px(14) * node.depth;

	override function onPress(localX:Float, localY:Float):Void {
		pressedChevron = false;
		var node:UITreeNode = tree.nodeAt(index);
		if (node != null && node.hasChildren) {
			var indent:Float = indentOf(node);
			if (localX >= indent - UITheme.px(2) && localX <= indent + UITheme.px(15))
				pressedChevron = true;
		}
	}

	override function click():Void {
		if (pressedChevron) {
			pressedChevron = false;
			var node:UITreeNode = tree.nodeAt(index);
			if (node != null)
				tree.toggle(node);
			return;
		}
		super.click();
	}

	override public function render():Void {
		var node:UITreeNode = tree.nodeAt(index);
		var g = graphics;
		g.clear();
		var selected:Bool = (index >= 0 && index == owner.selectedIndex);
		if (selected) {
			g.beginFill(UIColor.rgb(UITheme.panel3));
			g.drawRect(0, 0, w, h);
			g.endFill();
			g.beginFill(UIColor.rgb(UITheme.accent));
			g.drawRect(0, UITheme.px(3), UITheme.px(2.5), h - UITheme.px(6));
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

		if (node == null)
			return;

		var indent:Float = indentOf(node);
		if (node.hasChildren) {
			var centerX:Float = indent + UITheme.px(6);
			var centerY:Float = h / 2;
			var reach:Float = UITheme.px(4);
			g.beginFill(UIColor.rgb(UITheme.text3));
			if (node.expanded) {
				g.moveTo(centerX - reach, centerY - reach * 0.5);
				g.lineTo(centerX + reach, centerY - reach * 0.5);
				g.lineTo(centerX, centerY + reach * 0.7);
			} else {
				g.moveTo(centerX - reach * 0.5, centerY - reach);
				g.lineTo(centerX + reach * 0.7, centerY);
				g.lineTo(centerX - reach * 0.5, centerY + reach);
			}
			g.endFill();
		}

		if (labelField != null) {
			UIFonts.restyle(labelField, UITheme.fs(12), selected ? UITheme.text : UITheme.text2);
			labelField.x = indent + UITheme.px(16);
			labelField.y = (h - labelField.height) / 2;
		}
	}
}
