module dgt.render.framegraph;

import dgt.core.geometry;
import dgt.core.image;
import dgt.math.mat : FMat4;

import gfx.foundation.typecons : Option;
import gfx.pipeline.draw;

class FGFrame
{
    IRect _viewport;
    size_t _windowHandle;
    Option!FVec4 _clearColor;
    immutable(FGNode) _root=null;

    immutable this(size_t windowHandle, IRect viewport, Option!FVec4 clearColor, immutable(FGNode) root)
    {
        _windowHandle = windowHandle;
        _viewport = viewport;
        _clearColor = clearColor;
        _root = root;
    }

    @property size_t windowHandle() const { return _windowHandle; }
    @property IRect viewport() const { return _viewport; }

    @property Option!FVec4 clearColor() const { return _clearColor; }
    @property immutable(FGNode) root() const { return _root; }
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
        image,
        text,
    }

    private Type _type;

    immutable this(in Type type)
    {
        _type = type;
    }

    @property Type type() const { return _type; }

}

class FGGroupNode : FGNode
{
    private immutable(FGNode)[] _children;

    immutable this(immutable(FGNode)[] children)
    {
        _children = children;
        super(Type.group);
    }

    @property immutable(FGNode)[] children() const { return _children; }
}

class FGTransformNode : FGNode
{
    private FMat4 _transform;
    private immutable(FGNode) _child;

    immutable this(in FMat4 transform, immutable(FGNode) child)
    {
        _transform = transform;
        _child = child;
        super(Type.transform);
    }

    @property FMat4 transform() const { return _transform; }
    @property immutable(FGNode) child() const { return _child; }
}


abstract class FGRectNode : FGNode
{
    immutable this()
    {
        super(Type.rect);
    }

    FRect _rect;
}

class FGImageNode : FGNode
{
    private immutable(Image) _img;
    private CacheCookie _cookie;

    immutable this (in FPoint topLeft, immutable(Image) img, in CacheCookie cookie=nullCookie)
    {
        _img = img;
        _cookie = cookie;
        super(Type.image);
    }

    @property immutable(Image) image() const { return _img; }
    @property CacheCookie cookie() const { return _cookie; }
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
