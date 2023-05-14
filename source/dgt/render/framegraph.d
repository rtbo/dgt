/// The frame graph is an immutable tree structure whose purpose is to
/// transfer rendering orders from the views to the renderer (possibly lying in
/// a different thread than the views)
module dgt.render.framegraph;

import dgt.gfx.geometry;
import dgt.gfx.image;
import dgt.gfx.paint;
import dgt.text.layout : TextShape;

import gfx.core.typecons : Option;
import gfx.math.mat : FMat4;

class FrameContext {
    void prune(in CacheCookie cookie) {
        if (cookie) _prune ~= cookie;
    }
    CacheCookie[] _prune;
}

class FGFrame
{
    private IRect _viewport;
    private size_t _windowHandle;
    private Option!FVec4 _clearColor;
    private immutable(FGNode) _root;
    private immutable(CacheCookie)[] _prune;

    immutable this(size_t windowHandle, IRect viewport, Option!FVec4 clearColor,
                   immutable(FGNode) root, immutable(CacheCookie)[] prune)
    {
        _windowHandle = windowHandle;
        _viewport = viewport;
        _clearColor = clearColor;
        _root = root;
        _prune = prune;
    }

    @property IRect viewport() immutable {
        return _viewport;
    }

    @property size_t windowHandle() immutable {
        return _windowHandle;
    }

    @property Option!FVec4 clearColor() immutable {
        return _clearColor;
    }

    @property immutable(FGNode) root() immutable {
        return _root;
    }

    @property immutable(CacheCookie)[] prune() immutable {
        return _prune;
    }
}

/// Framegraph node category
enum FGTypeCat
{
    /// meta nodes does not perform rendering, but may affect how children nodes are rendered
    /// example: group, transform, clip...
    meta        = 0x100,
    /// node that perform actual rendering
    render      = 0x200,
    /// node defined by application
    user        = 0x800,
}

/// mask to apply to a node type id to obtain the index of the node type within the node category
enum uint fgTypeIndexMask = 0x00ff;
/// mask to apply to a node type id to obtain the category of the node type
enum uint fgTypeCatMask = 0xff00;

/// built-in node types in the meta category
enum FGMetaType
{
    /// node that simply groups other nodes under it
    group,
    /// node that transform it unique child with a matrix
    transform,
}

/// built-in node types in the render category
enum FGRenderType
{
    /// Renders a rectangle, with a inner paint and border.
    rect,
    /// Renders text
    text,
    /// Renders an image
    image,
    /// Renders vector graphics operations
    vg,
}

/// describes the type of a node
struct FGType
{
    uint id;

    this(T)(in FGTypeCat cat, in T index)
    in {
        assert(cast(uint)index <= fgTypeIndexMask);
    }
    body {
        id = cast(uint)cat | cast(uint)index;
    }

    @property FGTypeCat cat() const {
        return cast(FGTypeCat)(id & fgTypeCatMask);
    }

    @property uint index() const {
        return id & fgTypeIndexMask;
    }

    @property FGMetaType asMeta() const {
        assert(cat & FGTypeCat.meta);
        return cast(FGMetaType)index;
    }

    @property FGRenderType asRender() const {
        assert(cat & FGTypeCat.render);
        return cast(FGRenderType)index;
    }
}


/// Transient frame graph node tree
/// A graph structure that tells a renderer what to render, no more, no less.
/// Is meant to be collected as immutable during frame construct and sent to a renderer
/// that can reside peacefully in a dedicated thread and perform lock-free rendering.
/// Application (or widgets or whatever) can still cache the nodes in their immutable form.
abstract class FGNode
{
    FGType type;

    immutable this(in FGType type)
    {
        this.type = type;
    }
}

/// Node whose type.cat will always be FGTypeCat.meta
abstract class FGMetaNode : FGNode
{
    immutable this(in FGType type)
    {
        assert(type.cat == FGTypeCat.meta);
        super(type);
    }

    @property FGMetaType metaType() const
    {
        return cast(FGMetaType)(type.id & fgTypeIndexMask);
    }
}

/// Node whose type.cat will always be FGTypeCat.render
abstract class FGRenderNode : FGNode
{
    immutable this(in FGType type)
    {
        assert(type.cat == FGTypeCat.render);
        super(type);
    }

    @property FGRenderType renderType() const
    {
        return cast(FGRenderType)(type.id & fgTypeIndexMask);
    }
}

final class FGGroupNode : FGMetaNode
{
    static immutable FGType fgType = FGType(FGTypeCat.meta, FGMetaType.group);

    immutable(FGNode)[] children;

    immutable this(immutable(FGNode)[] children)
    in {
        import std.algorithm : all;
        assert(children.all!(c => c !is null));
    }
    body {
        this.children = children;
        super(fgType);
    }
}

final class FGTransformNode : FGMetaNode
{
    static immutable FGType fgType = FGType(FGTypeCat.meta, FGMetaType.transform);

    FMat4 transform;
    immutable(FGNode) child;

    immutable this(in FMat4 transform, immutable(FGNode) child)
    in {
        assert(child !is null);
    }
    body {
        super(fgType);
        this.transform = transform;
        this.child = child;
    }
}

struct RectBorder {
    FVec4 color;
    float width;
}

final class FGRectNode : FGRenderNode
{
    static immutable FGType fgType = FGType(FGTypeCat.render, FGRenderType.rect);

    private FRect _rect;
    private float _radius;
    private Paint _paint;
    private Option!RectBorder _border;
    private CacheCookie _cookie;

    immutable this(in FRect rect, in float radius, immutable Paint paint,
                   in Option!RectBorder border, in CacheCookie cookie=nullCookie)
    {
        super(fgType);
        _rect = rect;
        _radius = radius;
        _paint = paint;
        _border = border;
        _cookie = cookie;
    }

    @property FRect rect() immutable {
        return _rect;
    }
    @property float radius() immutable {
        return _radius;
    }
    @property immutable(Paint) paint() immutable {
        return _paint;
    }
    @property Option!RectBorder border() immutable {
        return _border;
    }
    @property CacheCookie cookie() immutable {
        return _cookie;
    }
}

final class FGTextNode : FGRenderNode
{
    static immutable FGType fgType = FGType(FGTypeCat.render, FGRenderType.text);

    FVec2 bearing;
    immutable(TextShape)[] shapes;
    FVec4 color;

    immutable this(in FVec2 bearing, immutable(TextShape)[] shapes, in FVec4 color) {
        super(fgType);
        this.bearing = bearing;
        this.shapes = shapes;
        this.color = color;
    }
}

final class FGImageNode : FGRenderNode
{
    static immutable FGType fgType = FGType(FGTypeCat.render, FGRenderType.image);

    FVec2 orig;
    immutable(Image) image;
    CacheCookie cookie;

    immutable this(in FVec2 orig, immutable(Image) image, CacheCookie cookie) {
        super(fgType);
        this.orig = orig;
        this.image = image;
        this.cookie = cookie;
    }
}

final class FGVgNode : FGRenderNode
{
    import dgt.vg.cmdbuf : CmdBuf;

    static immutable FGType fgType = FGType(FGTypeCat.render, FGRenderType.vg);

    immutable(CmdBuf) cmdBuf;
    CacheCookie cookie;

    immutable this(immutable(CmdBuf) cmdBuf, CacheCookie cookie) {
        super(fgType);
        this.cmdBuf = cmdBuf;
        this.cookie = cookie;
    }
}

/// Cookie to be used as a key in a cache.
struct CacheCookie
{
    size_t payload;

    size_t toHash() const @safe pure nothrow {
        return payload;
    }
    bool opEquals(ref const CacheCookie c) const @safe pure nothrow {
        return c.payload == payload;
    }
    bool valid() const @safe pure nothrow {
        return payload != 0;
    }
    bool opCast(T)() const @safe pure nothrow
    if(is(T == bool)) {
        return valid;
    }

    /// Each call to next() yield a different and unique cookie
    static CacheCookie next() {
        import core.atomic : atomicOp;
        static shared size_t cookie = 0;
        immutable payload = atomicOp!"+="(cookie, 1);
        return CacheCookie(payload);
    }
}

/// Default cookie
enum nullCookie = CacheCookie.init;

/// CacheCookie default value is not valid
unittest {
    assert(!CacheCookie.init.valid);
    assert(!nullCookie.valid);
}

/// CacheCookie is thread safe and yield unique valid cookies
unittest {
    import core.sync.mutex : Mutex;
    import core.thread : Thread;
    import std.algorithm : all, each, equal, map, sort, uniq;
    import std.array : array;
    import std.range : iota;

    enum numAdd = 1000;
    enum numTh = 4;

    size_t[] cookies;
    auto mut = new Mutex;

    void addNum() {
        for(int i=0; i<numAdd; ++i) {
            const c = CacheCookie.next;
            mut.lock();
            cookies ~= c.payload;
            mut.unlock();
        }
    }

    auto ths = iota(numTh)
            .map!(i => new Thread(&addNum))
            .array;
    ths.each!(th => th.start());
    ths.each!(th => th.join());

    sort(cookies);
    assert(cookies.length == numTh*numAdd);
    assert(equal(cookies, cookies.uniq));
    assert(cookies.all!(c => c != 0));
}

/// CacheCookie can be used as a AA key.
unittest {
    import std.format : format;
    string[CacheCookie] aa;
    CacheCookie[] arr;

    enum num = 1000;
    for (int i=0; i<1000; ++i) {
        const c = CacheCookie.next();
        arr ~= c;
        aa[c] = format("%s", c.payload);
    }

    for (int i=0; i<num; ++i) {
        assert(aa[arr[i]] == format("%s", arr[i].payload));
    }
}

/// Returns: a depth first forward range starting on the given root
@property auto depthFirst(immutable(FGNode) root) {
    return FgDepthFirstRange(root);
}

/// Returns: a breadth first forward range starting on the given root
@property auto breadthFirst(immutable(FGNode) root) {
    return FgBreadthFirstRange(root);
}

private:

struct FgDepthFirstRange
{
    static struct Stage {
        immutable(FGNode)[] nodes;
        size_t ind;
    }

    Stage[] stack;

    this(immutable(FGNode) root) {
        stack = [ Stage ([ root ], 0) ];
    }
    this(Stage[] stack) {
        this.stack = stack;
    }

    @property bool empty() {
        return stack.length == 0;
    }

    @property immutable(FGNode) front() {
        Stage stage = stack[$-1];
        return stage.nodes[stage.ind];
    }

    void popFront() {
        Stage stage = stack[$-1];
        immutable node = stage.nodes[stage.ind];

        // getting deeper if possible
        if (node.type.cat == FGTypeCat.meta) {
            switch (node.type.asMeta) {
            case FGMetaType.group:
                immutable gnode = cast(immutable(FGGroupNode))node;
                stack ~= Stage (gnode.children, 0);
                return;
            case FGMetaType.transform:
                immutable tnode = cast(immutable(FGTransformNode))node;
                stack ~= Stage ([ tnode.child ], 0);
                return;
            default:
                break;
            }
        }

        // otherwise going to sibling
        stack[$-1].ind += 1;
        // unstack while sibling are invalid
        while (stack[$-1].ind == stack[$-1].nodes.length) {
            stack = stack[0 .. $-1];
            if (!stack.length) return;
            else stack[$-1].ind += 1;
        }
    }

    @property FgDepthFirstRange save() {
        // The stack is mutable through Stage.ind.
        // Duplication is necessary.
        return FgDepthFirstRange(stack.dup);
    }
}

struct FgBreadthFirstRange
{
    // algo is simple, filling next level as we iterate on the current one,
    // then swap when level is exhausted
    immutable(FGNode)[] thisLevel;
    immutable(FGNode)[] nextLevel;

    this(immutable(FGNode) root) {
        thisLevel = [ root ];
    }
    this(immutable(FGNode)[] thisLevel, immutable(FGNode)[] nextLevel) {
        this.thisLevel = thisLevel;
        this.nextLevel = nextLevel;
    }

    @property bool empty() {
        return thisLevel.length == 0;
    }

    @property immutable(FGNode) front() {
        return thisLevel[0];
    }

    void popFront() {
        immutable node = thisLevel[0];

        // filling next level
        if (node.type.cat == FGTypeCat.meta) {
            switch (node.type.asMeta) {
            case FGMetaType.group:
                immutable gnode = cast(immutable(FGGroupNode))node;
                nextLevel ~= gnode.children;
                break;
            case FGMetaType.transform:
                immutable tnode = cast(immutable(FGTransformNode))node;
                nextLevel ~= tnode.child;
                break;
            default:
                break;
            }
        }

        // pop current level front and swap to next level if exhausted
        thisLevel = thisLevel[1 .. $];
        if (!thisLevel.length) {
            import std.algorithm : swap;
            swap(thisLevel, nextLevel);
        }
    }

    @property FgBreadthFirstRange save() {
        // slices to immutable data: no need to duplicate
        return FgBreadthFirstRange(thisLevel, nextLevel);
    }
}

version(unittest) {

    import std.range.primitives : isForwardRange;
    import gfx.core.typecons : none;

    static assert(isForwardRange!FgDepthFirstRange);
    static assert(isForwardRange!FgBreadthFirstRange);

    immutable rect = new immutable FGRectNode(FRect.init, 0, null, none!RectBorder);

    immutable(FGNode) makeTestFG() {
        return new immutable(FGGroupNode) ([
            new immutable(FGTransformNode)(
                FMat4.identity,
                new immutable(FGGroupNode)( [
                    rect, rect, rect, rect
                ])
            ),
            new immutable(FGTransformNode)(
                FMat4.identity,
                new immutable(FGGroupNode)([
                    new immutable(FGTransformNode)(
                        FMat4.identity,
                        new immutable(FGTextNode)(
                            fvec(0, 0), null, fvec(0, 0, 0, 0)
                        ),
                    ),
                    rect
                ])
            )
        ]);
    }
}

unittest
{
    import std.algorithm : equal, map;
    immutable fg = makeTestFG();
    assert(fg.depthFirst.map!(n => n.type).equal([
        FGGroupNode.fgType,
        FGTransformNode.fgType,
        FGGroupNode.fgType,
        FGRectNode.fgType,
        FGRectNode.fgType,
        FGRectNode.fgType,
        FGRectNode.fgType,
        FGTransformNode.fgType,
        FGGroupNode.fgType,
        FGTransformNode.fgType,
        FGTextNode.fgType,
        FGRectNode.fgType,
    ]));
}

unittest {
    import std.algorithm : equal, map;
    immutable fg = makeTestFG();
    assert(fg.breadthFirst.map!(n => n.type).equal([
        FGGroupNode.fgType,
        FGTransformNode.fgType,
        FGTransformNode.fgType,
        FGGroupNode.fgType,
        FGGroupNode.fgType,
        FGRectNode.fgType,
        FGRectNode.fgType,
        FGRectNode.fgType,
        FGRectNode.fgType,
        FGTransformNode.fgType,
        FGRectNode.fgType,
        FGTextNode.fgType,
    ]));
}
