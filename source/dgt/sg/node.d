/// Scene graph node module
module dgt.sg.node;

import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.sg.context;
import dgt.sg.geometry;
import dgt.sg.paint;
import dgt.text.layout;

import gfx.foundation.rc;
import gfx.pipeline.draw;

import std.exception : enforce;
import std.typecons : Rebindable;

/// Removes a node from its parent if it has one
void orphean(SGNode node)
{
    if (node.parent) node.parent.removeChild(node);
}

/// Change parent from a node. Has no effect if newParent is already the parent
/// of node
void reparent(SGNode node, SGNode newParent, SGNode beforeChild=null)
in {
    assert(!beforeChild || beforeChild.parent is newParent);
}
body {
    if (newParent is node.parent) return;
    if (node.parent) node.parent.removeChild(node);
    if (beforeChild) {
        newParent.insertChildBefore(node, beforeChild);
    }
    else {
        newParent.appendChild(node);
    }
}

class SGNode : Disposable
{
    enum Type {
        simple, geometry, transform, clip, opacity, draw,
        // as a transition step towards new system, the following are supported
        rectFill, rectStroke, image, text,
    }

    this()
    {
        _type = Type.simple;
    }

    protected this(Type type)
    {
        _type = type;
    }

    override void dispose()
    {
        import std.algorithm : each;
        children.each!(c => c.dispose());
    }

    /// The type of this node
    @property Type type()
    {
        return _type;
    }

    /// The root of this scene graph
    @property SGNode root()
    {
        if (!_parent) return cast(SGNode)this;
        SGNode p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// Whether this node is root
    @property bool isRoot()
    {
        return _parent is null;
    }

    /// This node's parent.
    @property SGNode parent()
    {
        return _parent;
    }

    /// This node's previous sibling.
    @property SGNode prevSibling()
    {
        return _prevSibling;
    }

    /// This node's next sibling.
    @property SGNode nextSibling()
    {
        return _nextSibling;
    }

    /// Whether this node has children.
    @property bool hasChildren()
    {
        return _firstChild !is null;
    }

    /// The number of children this node has.
    @property size_t childCount()
    {
        return _childCount;
    }

    /// This node's first child.
    @property SGNode firstChild()
    {
        return _firstChild;
    }

    /// This node's last child.
    @property SGNode lastChild()
    {
        return _lastChild;
    }

    /// A bidirectional range of this node's children
    @property auto children()
    {
        return SGSiblingNodeRange(_firstChild, _lastChild);
    }

    /// Appends the given node to this node children list.
    void appendChild(SGNode node)
    {
        enforce(node && !node._parent);
        node._parent = this;

        if (!hasChildren) {
            _firstChild = node;
            _lastChild = node;
        }
        else {
            _lastChild._nextSibling = node;
            node._prevSibling = _lastChild;
            _lastChild = node;
        }
        ++_childCount;
    }

    /// Prepend the given node to this node children list.
    void prependChild(SGNode node)
    {
        enforce(node && !node._parent);
        node._parent = this;

        if (!hasChildren) {
            _firstChild = node;
            _lastChild = node;
        }
        else {
            _firstChild._prevSibling = node;
            node._nextSibling = _firstChild;
            _firstChild = node;
        }
        ++_childCount;
    }

    /// Insert the given node in this node children list, just before the given
    /// child.
    void insertChildBefore(SGNode node, SGNode child)
    {
        enforce(node && !node._parent && child._parent is this);
        node._parent = this;

        if (child is _firstChild) {
            _firstChild = node;
        }
        else {
            auto prev = child._prevSibling;
            prev._nextSibling = node;
            node._prevSibling = prev;
        }
        child._prevSibling = node;
        node._nextSibling = child;
        ++_childCount;
    }

    /// Removes the given node from this node children list.
    void removeChild(SGNode child)
    {
        enforce(child && child._parent is this);

        child._parent = null;

        if (_childCount == 1) {
            _firstChild = null;
            _lastChild = null;
        }
        else if (child is _firstChild) {
            _firstChild = child._nextSibling;
            _firstChild._prevSibling = null;
        }
        else if (child is _lastChild) {
            _lastChild = child._prevSibling;
            _lastChild._nextSibling = null;
        }
        else {
            auto prev = child._prevSibling;
            auto next = child._nextSibling;
            prev._nextSibling = next;
            next._prevSibling = prev;
        }
        --_childCount;
    }

    @property uint level()
    {
        auto p = parent;
        uint lev=0;
        while (p !is null) {
            ++lev;
            p = p.parent;
        }
        return lev;
    }

    @property string name()
    {
        return _name;
    }
    @property void name(string name)
    {
        _name = name;
    }

    override string toString()
    {
        import std.array : array;
        import std.conv : to;
        import std.format : format;
        import std.range : repeat;
        auto indent = repeat(' ', level*4).array;
        string res = format("%s{ %s:%s ", indent, name, type.to!string);
        if (hasChildren) {
            res ~= format("[\n");
            size_t ind=0;
            foreach(c; children) {
                res ~= c.toString();
                if (ind != _childCount-1) {
                    res ~= ",\n";
                }
                ++ind;
            }
            res ~= format("\n%s]", indent);
        }
        res ~= "}";
        return res;
    }

    private Type _type;

    private SGNode _parent;

    private SGNode _prevSibling;
    private SGNode _nextSibling;

    private size_t _childCount;
    private SGNode _firstChild;
    private SGNode _lastChild;

    private string _name;
}


class SGTransformNode : SGNode
{
    this()
    {
        super(Type.transform);
    }

    @property FMat4 transform()
    {
        return _transform;
    }

    @property void transform(in FMat4 tr)
    {
        _transform  = tr;
    }

    private FMat4 _transform;
}

class SGRectFillNode : SGNode
{
    this()
    {
        super(Type.rectFill);
    }

    @property FRect rect()
    {
        return _rect;
    }
    @property void rect(in FRect rect)
    {
        _rect = rect;
    }

    @property FVec4 color()
    {
        return _color;
    }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    private FRect _rect;
    private FVec4 _color;
}


class SGRectStrokeNode : SGNode
{
    this()
    {
        super(Type.rectStroke);
    }

    @property FRect rect()
    {
        return _rect;
    }
    @property void rect(in FRect rect)
    {
        _rect = rect;
    }

    @property FVec4 color()
    {
        return _color;
    }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    @property float width()
    {
        return _width;
    }
    @property void width(in float width)
    {
        _width = width;
    }

    private FRect _rect;
    private FVec4 _color;
    private float _width;
}

class SGImageNode : SGNode
{
    this()
    {
        super(Type.image);
    }

    @property FVec2 topLeft()
    {
        return _topLeft;
    }
    @property void topLeft(in FVec2 topLeft)
    {
        _topLeft = topLeft;
    }

    @property immutable(Image) image()
    {
        return _image;
    }
    @property void image(immutable(Image) image)
    {
        _image = image;
    }

    Rebindable!(immutable(Image)) _image;
    FVec2 _topLeft;
}

class SGTextNode : SGNode
{
    this()
    {
        super(Type.text);
    }

    @property immutable(ShapedGlyph)[] glyphs()
    {
        return _glyphs;
    }
    @property void glyphs(immutable(ShapedGlyph)[] glyphs)
    {
        _glyphs = glyphs;
    }

    @property FVec2 pos()
    {
        return _pos;
    }
    @property void pos(FVec2 pos)
    {
        _pos = pos;
    }

    @property FVec4 color()
    {
        return _color;
    }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    private immutable(ShapedGlyph)[] _glyphs;
    private FVec2 _pos;
    private FVec4 _color;
}

/// General node that issue drawing calls into a command buffer
abstract class SGDrawNode : SGNode
{
    this()
    {
        super(Type.draw);
    }
    abstract void draw (CommandBuffer cmdBuf, SGContext context, in FMat4 modelMat);
}

//FIXME: actual support for the following nodes

class SGGeometryNode : SGNode
{
    this()
    {
        super(Type.geometry);
    }

    override void dispose()
    {
        super.dispose();
        _geometry.unload();
        _paint.unload();
    }

    @property SGGeometryBase geometry()
    {
        return _geometry;
    }

    @property void geometry(SGGeometryBase geom)
    {
        _geometry = geometry;
    }

    @property SGPaintEffect paint()
    {
        return _paint;
    }

    @property void paint(SGPaintEffect paint)
    {
        _paint = paint;
    }

    private Rc!SGGeometryBase _geometry;
    private Rc!SGPaintEffect _paint;
}


class SGOpacityNode : SGNode
{
    this()
    {
        super(Type.opacity);
    }
    this(float opacity)
    {
        this();
        _opacity = opacity;
    }

    @property float opacity()
    {
        return _opacity;
    }
    @property void opacity(in float opacity)
    {
        _opacity = opacity;
    }

    private float _opacity;
}


class SGClipNode : SGNode
{
    this()
    {
        super(Type.clip);
    }
    this(in FRect rect)
    {
        this();
        _rect = rect;
    }

    @property FRect rect()
    {
        return _rect;
    }
    @property void rect(in FRect rect)
    {
        _rect = rect;
    }

    private FRect _rect;
}

private:

/// Bidirectional range that traverses a sibling view list
struct SGSiblingNodeRange
{
    SGNode _first;
    SGNode _last;

    this (SGNode first, SGNode last)
    {
        _first = first;
        _last = last;
    }

    @property bool empty() { return _first is null; }
    @property SGNode front() { return _first; }
    void popFront() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _first = _first._nextSibling;
        }
    }

    @property auto save()
    {
        return SGSiblingNodeRange(_first, _last);
    }

    @property SGNode back() { return _last; }
    void popBack() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _last = _last._prevSibling;
        }
    }
}

import std.range : isBidirectionalRange;

static assert (isBidirectionalRange!SGSiblingNodeRange);
static assert (isBidirectionalRange!SGSiblingNodeRange);
