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


class CSSValueBase
{
    this()
    {}

    this(CSSWideValue val)
    {
        _cssWideVal = val;
    }

    final @property bool initial()
    {
        return _cssWideVal == CSSWideValue.initial;
    }
    final @property bool inherit()
    {
        return _cssWideVal == CSSWideValue.inherit;
    }
    final @property bool unset()
    {
        return _cssWideVal == CSSWideValue.unset;
    }

    private CSSWideValue _cssWideVal = CSSWideValue.none;
}


class CSSValue(T) : CSSValueBase
{
    this(T value)
    {
        _value = value;
    }

    final @property T value()
    {
        return _value;
    }

    private T _value;
}
