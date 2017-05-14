module dgt.css.value;

import dgt.css.color;

struct Length
{
    enum Unit {
        // relative
        em, ex, ch, rem,
        // viewport relative
        vw, vh, vmin, vmax,
        // absolute
        cm, mm, q, in_, pt, pc, px
    }
    float val;
    Unit unit;
}

enum CSSWideValue
{
    none    = 0,
    initial,
    inherit,
    unset,
}

enum ValueType
{
    none        = 0,
    str,
    color,
    length,
}

enum uint cssWideShift          = 24;
enum uint typeMask              = 0x00ff_ffff;
enum uint cssWideMask           = 0xff00_0000;
enum uint cssWideShiftedMask    = 0x0000_00ff;
enum uint initialBits           = CSSWideValue.initial << cssWideShift;
enum uint inheritBits           = CSSWideValue.inherit << cssWideShift;
enum uint unsetBits             = CSSWideValue.unset   << cssWideShift;

uint valueFlags(CSSWideValue cw, ValueType vt)
{
    return (cast(uint)cw) << cssWideShift | cast(uint)vt;
}

template valueType(T)
{
    static if (is(T == string)) {
        enum valueType = ValueType.str;
    }
    else static if (is(T == Color)) {
        enum valueType = ValueType.color;
    }
    else static if (is(T == Length)) {
        enum valueType = ValueType.length;
    }
    else {
        static assert(false, T.stringof ~ " is not a supported CSS value type");
    }
}

abstract class CSSValueBase
{
    this(uint flags)
    {
        _flags = flags;
    }

    final @property uint flags() { return _flags; }

    final @property ValueType type()
    {
        return cast(ValueType)(_flags & typeMask);
    }

    final @property CSSWideValue cssWideValue()
    {
        return cast(CSSWideValue)((_flags >> cssWideShift) & cssWideShiftedMask);
    }

    final @property bool initial()
    {
        return cssWideValue == CSSWideValue.initial;
    }
    final @property bool inherit()
    {
        return cssWideValue == CSSWideValue.inherit;
    }
    final @property bool unset()
    {
        return cssWideValue == CSSWideValue.unset;
    }

    private uint _flags;
}


class CSSValue(T) : CSSValueBase
{
    this(T value)
    {
        super(valueType!T);
        _value = value;
    }

    this(CSSWideValue cssWide)
    {
        super(valueFlags(cssWide, valueType!T));
    }

    final @property T value()
    {
        return _value;
    }

    private T _value;
}
