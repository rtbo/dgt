module dgt.css.value;

import dgt.css.color;
import dgt.css.token;

struct Length
{
    enum Unit {
        // relative
        em, ex, ch, rem,
        // viewport relative
        vw, vh, vmin, vmax,
        // absolute
        cm, mm, q, inch, pt, pc, px
    }
    float val;
    Unit unit;
}

/// Parse a Length from a dimension token.
/// Returns: true if parsing is successful, false otherwise.
bool parseLength(Token tok, ref Length l)
in {
    assert(tok.tok == Tok.dimension);
}
body {
    import std.uni : toLower;
    Length.Unit unit;
    switch(tok.unit.toLower) {
    case "em":
        unit = Length.Unit.em;
        break;
    case "ex":
        unit = Length.Unit.ex;
        break;
    case "ch":
        unit = Length.Unit.ch;
        break;
    case "rem":
        unit = Length.Unit.rem;
        break;
    case "vw":
        unit = Length.Unit.vw;
        break;
    case "vh":
        unit = Length.Unit.vh;
        break;
    case "vmin":
        unit = Length.Unit.vmin;
        break;
    case "vmax":
        unit = Length.Unit.vmax;
        break;
    case "cm":
        unit = Length.Unit.cm;
        break;
    case "mm":
        unit = Length.Unit.mm;
        break;
    case "q":
        unit = Length.Unit.q;
        break;
    case "in":
        unit = Length.Unit.inch;
        break;
    case "pt":
        unit = Length.Unit.pt;
        break;
    case "pc":
        unit = Length.Unit.pc;
        break;
    case "px":
        unit = Length.Unit.px;
        break;
    default:
        return false;
    }
    l = Length(cast(float)tok.num, unit);
    return true;
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
    this(Args...)(Args args)
    if (is(typeof(T(args))))
    {
        _value = T(args);
    }

    final @property T value()
    {
        return _value;
    }

    private T _value;
}
