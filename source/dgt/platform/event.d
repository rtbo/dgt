/// Events delivered by the operating system to DGT.
module dgt.platform.event;

import dgt.core.enums;
import dgt.gfx.geometry;
import dgt.core.signal;
import dgt.input;
import dgt.window;

enum PlEventType
{
    timer,
    // events delivered to windows
    show, hide,
    expose, resize, move,
    closeRequest, stateChange,
    focusIn, focusOut,
    mouseDown, mouseUp, mouseMove, mouseWheel,
    mouseEnter, mouseLeave,
    keyDown, keyUp,
}

abstract class PlEvent
{
    this(PlEventType type)
    {
        _type = type;
    }

    final @property PlEventType type() const
    {
        return _type;
    }

    final @property bool consumed() const
    {
        return _consumed;
    }

    void consume()
    {
        _consumed = true;
    }

    override string toString()
    {
        import std.conv : to;

        return "PlEvent [ type:" ~ _type.to!string ~ " ]";
    }

    private PlEventType _type;
    private bool _consumed;
}

class PlTimerEvent : PlEvent
{
    this(void delegate() handler)
    {
        super(PlEventType.timer);
        _handler = handler;
    }

    void handle() {
        _handler();
    }

    private Slot!() _handler;
}

abstract class PlWindowEvent : PlEvent
{
    this(PlEventType type, Window window)
    {
        super(type);
        _window = window;
    }

    @property inout(Window) window() inout
    {
        return _window;
    }

    private Window _window;
}

class PlShowEvent : PlWindowEvent
{
    this(Window window)
    {
        super(PlEventType.show, window);
    }
}

class PlHideEvent : PlWindowEvent
{
    this(Window window)
    {
        super(PlEventType.hide, window);
    }
}

class PlExposeEvent : PlWindowEvent
{
    this(Window window, IRect exposedArea)
    {
        super(PlEventType.expose, window);
        _exposedArea = exposedArea;
    }

    @property IRect exposedArea() const
    {
        return _exposedArea;
    }

    private IRect _exposedArea;
}

class PlResizeEvent : PlWindowEvent
{
    this(Window window, ISize size)
    {
        super(PlEventType.resize, window);
        _size = size;
    }

    @property ISize size() const
    {
        return _size;
    }

    package(dgt) @property void size(in ISize s)
    {
        _size = s;
    }

    private ISize _size;
}

class PlMoveEvent : PlWindowEvent
{
    this(Window window, IPoint point)
    {
        super(PlEventType.move, window);
    }

    @property IPoint point() const
    {
        return _point;
    }

    package(dgt) @property void point(in IPoint p)
    {
        _point = p;
    }

    private IPoint _point;
}

class PlCloseRequestEvent : PlWindowEvent
{
    this(Window window)
    {
        super(PlEventType.closeRequest, window);
    }
}

class PlStateChangeEvent : PlWindowEvent
{
    this(Window window, WindowState state)
    {
        super(PlEventType.stateChange, window);
        _state = state;
    }

    @property WindowState state() const
    {
        return _state;
    }

    private WindowState _state;
}

class PlFocusEvent : PlWindowEvent
{
    this(PlEventType type, Window window, FocusMethod method)
    in
    {
        assert(type == PlEventType.focusIn || type == PlEventType.focusOut);
    }
    body
    {
        super(type, window);
        _method = method;
    }

    @property FocusMethod method() const
    {
        return _method;
    }

    private FocusMethod _method;
}

class PlMouseEvent : PlWindowEvent
{
    this(PlEventType type, Window window, IPoint point, MouseButton button,
            MouseState state, KeyMods modifiers)
    in
    {
        import std.algorithm : startsWith;
        import std.conv : to;
        assert(type.to!string.startsWith("mouse"));
    }
    body
    {
        super(type, window);
        _point = point;
        _button = button;
        _state = state;
        _modifiers = modifiers;
    }

    @property IPoint point() const
    {
        return _point;
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

    package(dgt) @property void point(in IPoint point)
    {
        _point = point;
    }
    package(dgt) @property void modifiers(in KeyMods mods)
    {
        _modifiers = mods;
    }

    private
    {
        IPoint _point;
        MouseButton _button;
        MouseState _state;
        KeyMods _modifiers;
    }
}

class PlKeyEvent : PlWindowEvent
{
    this(PlEventType type, Window window, KeySym sym, KeyCode code,
            KeyMods modifiers, string text, uint nativeCode, uint nativeSymbol,
            bool repeat = false, int repeatCount = 1)
    in
    {
        assert(type == PlEventType.keyDown || type == PlEventType.keyUp);
    }
    body
    {
        super(type, window);
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
