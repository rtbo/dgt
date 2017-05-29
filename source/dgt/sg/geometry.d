/// scene graph geometry module
module dgt.sg.geometry;

import dgt.sg.defs;

import gfx.foundation.rc;
import gfx.pipeline;

public import gfx.pipeline.buffer : IndexType;
public import gfx.pipeline.pso : Primitive;

enum AttributeSet
{
    none    = 0,
    pos2    = 1,
    tex2    = 2,
    col4    = 4,
}

abstract class SGGeometryBase : RefCounted
{
    mixin(rcCode);

    abstract @property AttributeSet attributes();
    abstract @property bool indexed();

    abstract @property RawBuffer vertexBuffer();
    abstract @property RawBuffer indexBuffer();

    /// Drawing primitive of this geometry
    final @property Primitive primitive()
    {
        return _primitive;
    }
    /// ditto
    final @property void primitive(in Primitive p)
    {
        _primitive = p;
    }

    private Primitive _primitive;
}

class SGGeometry(Vertex, Index=void) : SGGeometryBase
{
    void dispose() {
        if (_vbuf) _vbuf.dispose();
        _vbuf = null;
        static if (hasIndex) {
            if (_ibuf) _ibuf.dispose();
            _ibuf = null;
        }
    }

    override @property AttributeSet attributes()
    {
        return vertexAttributeSet!Vertex;
    }

    override @property bool indexed()
    {
        return hasIndex;
    }

    @property void vertices(const(Vertex)[] vertices)
    {
        _vbuf = new VertexBuffer!Vertex(vertices);
    }

    override @property VertexBuffer!Vertex vertexBuffer()
    {
        return _vbuf;
    }

    static if (hasIndex) {
        @property void indices(const(Index)[] indices)
        {
            _ibuf = new IndexBuffer!Index(indices);
        }
    }

    override @property IndexBuffer!Index indexBuffer()
    {
        static if (hasIndex) return _ibuf;
        else return null;
    }

    private enum hasIndex = !is(Index == void);

    private VertexBuffer!Vertex _vbuf;

    static if (hasIndex) {
        private IndexBuffer!Index _ibuf;
    }
}

/// Get the attribute set of vertex at compile time
template vertexAttributeSet(Vertex)
{
    enum vertexAttributeSet = build();

    AttributeSet build()
    {
        AttributeSet res = AttributeSet.none;
        foreach (m; __traits(allMembers, Vertex)) {
            alias mt = typeof(mixin("Vertex.init."~m));
            static if (m == "pos" && is(mt == float[2])) {
                res |= AttributeSet.pos2;
            }
            else static if (m == "tex" && is(mt == float[2])) {
                res |= AttributeSet.tex2;
            }
            else static if (m == "col" && is(mt == float[4])) {
                res |= AttributeSet.col4;
            }
        }
        return res;
    }
}

unittest
{
    new SGGeometry!(P2T2Vertex, ushort);
}
