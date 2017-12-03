/// Events delivered by the operating system to DGT.
module dgt.platform.event;

import dgt.core.enums;
import dgt.core.geometry;
import dgt.input.keys;
import dgt.input.mouse;
import dgt.window;

enum PlEventType
{
    // events delivered to windows
    show, hide,
    expose, resize, move,
    close, stateChange,
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

abstract class WindowEvent : PlEvent
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

class ShowEvent : WindowEvent
{
    this(Window window)
    {
        super(PlEventType.show, window);
    }
}

class HideEvent : WindowEvent
{
    this(Window window)
    {
        super(PlEventType.hide, window);
    }
}

class ExposeEvent : WindowEvent
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

class ResizeEvent : WindowEvent
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

class MoveEvent : WindowEvent
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

class CloseEvent : WindowEvent
{
    this(Window window)
    {
        super(PlEventType.close, window);
    }

    @property bool declined() const
    {
        return _declined;
    }

    void decline()
    {
        _declined = true;
    }

    private bool _declined;
}

class StateChangeEvent : WindowEvent
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

class PlFocusEvent : WindowEvent
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

class PlMouseEvent : WindowEvent
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

class PlKeyEvent : WindowEvent
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
