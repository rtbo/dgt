module dgt.render.services;

import gfx.core.rc : Disposable;

final class RenderServices : Disposable
{
    import gfx.core.rc : AtomicRefCounted;

    private size_t _frameNum;
    private size_t _maxGcAge = 2;
    private Garbage _gcFirst;
    private Garbage _gcLast;

    override void dispose()
    {
        import gfx.core.rc : releaseObj;

        while(_gcFirst) {
            releaseObj(_gcFirst.obj);
            _gcFirst = _gcFirst.next;
        }
    }

    void gc (AtomicRefCounted obj)
    {
        import gfx.core.rc : retainObj;

        auto g = new Garbage(_frameNum, retainObj(obj));
        if (!_gcLast) {
            assert(!_gcFirst);
            _gcFirst = g;
            _gcLast = g;
        }
        else {
            assert(!_gcLast.next);
            _gcLast.next = g;
            _gcLast = g;
        }
    }

    package void incrFrameNum()
    {
        import gfx.core.rc : releaseObj;

        ++_frameNum;

        if (_frameNum >= _maxGcAge) {

            const lastAllowed = _frameNum - _maxGcAge;

            while (_gcFirst && _gcFirst.frameNum < lastAllowed) {
                releaseObj(_gcFirst.obj);
                _gcFirst = _gcFirst.next;
            }
        }
    }
}


private:

class Garbage
{
    import gfx.core.rc : AtomicRefCounted;

    size_t frameNum;
    AtomicRefCounted obj;
    Garbage next;

    this (size_t frameNum, AtomicRefCounted obj)
    {
        this.frameNum = frameNum;
        this.obj = obj;
    }
}
