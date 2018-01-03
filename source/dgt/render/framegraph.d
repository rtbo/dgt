/// The frame graph is an immutable tree structure whose purpose is to
/// transfer rendering orders from the views to the renderer (possibly lying in
/// a different thread than the views)
module dgt.render.framegraph;

import dgt.core.geometry;
import dgt.core.image;
import dgt.core.paint;
import dgt.math.mat : FMat4;
import dgt.text.layout : TextShape;

import gfx.foundation.typecons : Option;
import gfx.pipeline.draw;

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


/// Transient frame graph node tree
/// A graph structure that tells a renderer what to render, no more, no less.
/// Is meant to be collected as immutable during frame construct and sent to a renderer
/// that can reside peacefully in a dedicated thread and perform lock-free rendering.
/// Application (or widgets or whatever) can still cache the nodes in their immutable form.
abstract class FGNode
{
    enum Type
    {
        group,
        transform,
        rect,
        text,
    }

    Type type;

    immutable this(in Type type)
    {
        this.type = type;
    }
}

final class FGGroupNode : FGNode
{
    immutable(FGNode)[] children;

    immutable this(immutable(FGNode)[] children)
    {
        this.children = children;
        super(Type.group);
    }
}

final class FGTransformNode : FGNode
{
    FMat4 transform;
    immutable(FGNode) child;

    immutable this(in FMat4 transform, immutable(FGNode) child)
    {
        this.transform = transform;
        this.child = child;
        super(Type.transform);
    }
}

struct RectBorder {
    FVec4 color;
    float width;
}

final class FGRectNode : FGNode
{
    private FRect _rect;
    private float _radius;
    private Paint _paint;
    private Option!RectBorder _border;
    private CacheCookie _cookie;

    immutable this(in FRect rect, in float radius, immutable Paint paint,
                   in Option!RectBorder border, in CacheCookie=nullCookie)
    {
        super(Type.rect);
        _rect = rect;
        _radius = radius;
        _paint = paint;
        _border = border;
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

final class FGTextNode : FGNode
{
    FVec2 bearing;
    immutable(TextShape)[] shapes;
    FVec4 color;

    immutable this(in FVec2 bearing, immutable(TextShape)[] shapes, in FVec4 color) {
        this.bearing = bearing;
        this.shapes = shapes;
        this.color = color;
        super(Type.text);
    }
}

/// Cookie to be used as a key in a cache.
struct CacheCookie
{
    immutable size_t payload;

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
        switch (node.type) {
        case FGNode.Type.group:
            immutable gnode = cast(immutable(FGGroupNode))node;
            stack ~= Stage (gnode.children, 0);
            return;
        case FGNode.Type.transform:
            immutable tnode = cast(immutable(FGTransformNode))node;
            stack ~= Stage ([ tnode.child ], 0);
            return;
        default:
            break;
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
        switch (node.type) {
        case FGNode.Type.group:
            immutable gnode = cast(immutable(FGGroupNode))node;
            nextLevel ~= gnode.children;
            break;
        case FGNode.Type.transform:
            immutable tnode = cast(immutable(FGTransformNode))node;
            nextLevel ~= tnode.child;
            break;
        default:
            break;
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

    static assert(isForwardRange!FgDepthFirstRange);
    static assert(isForwardRange!FgBreadthFirstRange);

    immutable(FGNode) makeTestFG() {
        return new immutable(FGGroupNode) ([
            new immutable(FGTransformNode)(
                FMat4.identity,
                new immutable(FGGroupNode)( [
                    new immutable(FGImageNode)(fvec(0, 0), null),
                    new immutable(FGImageNode)(fvec(0, 0), null),
                    new immutable(FGImageNode)(fvec(0, 0), null),
                    new immutable(FGImageNode)(fvec(0, 0), null),
                ])
            ),
            new immutable(FGTransformNode)(
                FMat4.identity,
                new immutable(FGGroupNode)([
                    new immutable(FGTransformNode)(
                        FMat4.identity,
                        new immutable(FGTextNode)(fvec(0, 0), null, fvec(0, 0, 0, 0)),
                    ),
                    new immutable(FGImageNode)(fvec(0, 0), null)
                ])
            )
        ]);
    }
}

unittest {
    import std.algorithm : equal, map;
    immutable fg = makeTestFG();
    assert(fg.depthFirst.map!(n => n.type).equal([
        FGNode.Type.group,
        FGNode.Type.transform,
        FGNode.Type.group,
        FGNode.Type.image,
        FGNode.Type.image,
        FGNode.Type.image,
        FGNode.Type.image,
        FGNode.Type.transform,
        FGNode.Type.group,
        FGNode.Type.transform,
        FGNode.Type.text,
        FGNode.Type.image,
    ]));
}

unittest {
    import std.algorithm : equal, map;
    immutable fg = makeTestFG();
    assert(fg.breadthFirst.map!(n => n.type).equal([
        FGNode.Type.group,
        FGNode.Type.transform,
        FGNode.Type.transform,
        FGNode.Type.group,
        FGNode.Type.group,
        FGNode.Type.image,
        FGNode.Type.image,
        FGNode.Type.image,
        FGNode.Type.image,
        FGNode.Type.transform,
        FGNode.Type.image,
        FGNode.Type.text,
    ]));
}
