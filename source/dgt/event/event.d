/// Events module
module dgt.event.event;

import dgt.enums;
import dgt.geometry : FPoint;
import dgt.keys;
import dgt.sg.node;

/// Type of event. 3 categories: app, input and user.
/// Category can be tested using Maskwise AND.
enum EventType : uint
{
    noneMask        = 0x0000_0000,
    allMask         = 0xffff_ffff,

    appMask         = 0x1000_0000,
    inputMask       = 0x2000_0000,
    userMask        = 0x4000_0000,

    focusMask       = 0x0100_0000,
    mouseMask       = 0x0200_0000 | inputMask,
    keyMask         = 0x0400_0000 | inputMask,

    timer           = appMask | 1,

    focusIn         = focusMask | 1,
    focusOut,
    mouseDown       = mouseMask | 1,
    mouseUp,
    mouseMove,
    mouseDrag,
    mouseClick,
    mouseDblClick,
    mouseEnter,
    mouseLeave,
    keyDown         = keyMask | 1,
    keyUp,
}

abstract class Event
{
    this(in EventType type, SgNode[] nodeChain)
    {
        _nodeChain = nodeChain;
        _type = type;
    }

    final @property EventType type() const
    {
        return _type;
    }

    package(dgt) @property void type(in EventType type)
    {
        _type = type;
    }

    final @property bool consumed() const
    {
        return _consumed;
    }

    final void consume()
    {
        _consumed = true;
    }

    final @property SgNode[] nodeChain()
    {
        return _nodeChain;
    }

    /// Chain the event to the next node in the nodeChain.
    /// Some event types can override this to send an adapted event to the next node.
    /// E.g. mouse events will translate positions in the next node coordinates.
    /// The default implementation only forwards itself to the next node.
    /// Depending on this behavior, a call to this method might or might not
    /// decrement the size of nodeChain.
    /// (It will be decremented in the next node chainEvent method)
    /// Returns: the node that has consumed the event, or null if not consumed.
    SgNode chainToNext()
    in {
        assert(_nodeChain.length);
    }
    body {
        auto next = _nodeChain[0];
        _nodeChain = _nodeChain[1 .. $];
        return next.chainEvent(this);
    }

    override string toString()
    {
        import std.conv : to;

        return "Event [ type:" ~ _type.to!string ~ " ]";
    }

    private SgNode[] _nodeChain;
    private EventType _type;
    private bool _consumed;
}

abstract class AppEvent : Event
{
    this(in EventType type, SgNode[] nodeChain)
    in {
        assert(type & EventType.appMask);
    }
    body {
        super(type, nodeChain);
    }
}

class UserEvent : Event
{
    this(in int eventType, SgNode[] nodeChain)
    in {
        assert(eventType & EventType.userMask);
    }
    body {
        super(cast(EventType)type, nodeChain);
    }
}

class FocusEvent : Event
{
    this(in EventType type, SgNode[] nodeChain, in FocusMethod method)
    in {
        assert(type & EventType.focusMask);
    }
    body {
        super(type, nodeChain);
        _method = method;
    }

    @property FocusMethod method() const
    {
        return _method;
    }

    private FocusMethod _method;
}

class MouseEvent : Event
{
    this(in EventType type, SgNode[] nodeChain, in FPoint pos,
            in FPoint scenePos, in MouseButton button, in MouseState state,
            in KeyMods modifiers)
    in {
        assert(type & EventType.mouseMask);
    }
    body {
        super(type, nodeChain);
        _pos = pos;
        _scenePos = scenePos;
        _button = button;
        _state = state;
        _modifiers = modifiers;
    }

    @property FPoint pos() const
    {
        return _pos;
    }

    @property FPoint scenePos() const
    {
        return _scenePos;
    }

    @property MouseButton button() const
    {
        return _button;
    }

    @property MouseState state() const
    {
        return _state;
    }

    @property KeyMods modifiers() const
    {
        return _modifiers;
    }

    override SgNode chainToNext()
    {
        import std.typecons : scoped;
        auto next = _nodeChain[0];
        auto nextEv = scoped!MouseEvent(
            _type, _nodeChain[1 .. $], _pos - next.pos, _scenePos,
            _button, _state, _modifiers
        );
        return next.chainEvent(nextEv);
    }

    private
    {
        FPoint _pos;
        FPoint _scenePos;
        MouseButton _button;
        MouseState _state;
        KeyMods _modifiers;
    }
}

class KeyEvent : Event
{
    this(in EventType type, SgNode[] nodeChain, in KeySym sym, in KeyCode code,
            in KeyMods modifiers, string text, in uint nativeCode, in uint nativeSymbol,
            in bool repeat = false, in int repeatCount = 1)
    in {
        assert(type & EventType.keyMask);
    }
    body {
        super(type, nodeChain);
        _sym = sym;
        _code = code;
        _modifiers = modifiers;
        _text = text;
        _nativeCode = nativeCode;
        _nativeSymbol = nativeSymbol;

        _repeat = repeat;
        _repeatCount = repeatCount;
    }

    @property KeySym sym() const
    {
        return _sym;
    }

    @property KeyCode code() const
    {
        return _code;
    }

    @property KeyMods modifiers() const
    {
        return _modifiers;
    }

    @property string text() const
    {
        return _text;
    }

    @property uint nativeCode() const
    {
        return _nativeCode;
    }

    @property uint nativeSymbol() const
    {
        return _nativeSymbol;
    }

    @property bool repeat() const
    {
        return _repeat;
    }

    @property int repeatCount() const
    {
        return _repeatCount;
    }

    private
    {
        KeySym _sym;
        KeyCode _code;
        KeyMods _modifiers;
        string _text;
        uint _nativeCode;
        uint _nativeSymbol;

        bool _repeat;
        int _repeatCount;
    }
}
