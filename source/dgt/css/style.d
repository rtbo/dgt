module dgt.css.style;

import dgt.css.om;
import dgt.css.token;
import dgt.css.value;
import dgt.geometry;
import dgt.event.handler;

import std.range;

/// Bit flags that describe the pseudo state of a Style.
/// Several states can be active at the same time (e.g. disabled and checked).
/// Pseudo state style can be specified by using corresponding
/// css pseudo-class selectors.
enum PseudoState
{
    // default state
    def             = 0,

    // UI state
    uiMask          = 0x0f,
    checked         = 0x01,
    disabled        = 0x02,
    indeterminate   = 0x04,

    // dynamic state
    dynMask         = 0xf0,
    active          = 0x10,
    hover           = 0x20,
    focus           = 0x40,

    /// application specific state can be used under the following reserved mask
    userMask        = 0xffff_f000,
}


interface Style
{
    @property Style parent();
    @property bool isRoot();
    @property Style root();
    @property Style prevSibling();
    @property Style nextSibling();

    @property FSize viewportSize();
    @property float dpi();
    @property string cssType();
    @property string id();
    @property string cssClass();
    @property PseudoState pseudoState();
    IStyleProperty styleProperty(string name);
}

/// Font style as defined by the CSS specification
enum FontSlant
{
    normal,
    italic,
    oblique,
}

interface FontStyle
{
    @property string[] fontFamily();
    @property int fontWeight();
    @property FontSlant fontSlant();
    @property int fontSize();
}


interface IStyleProperty
{
    @property Style style();
    @property string name();
    @property Origin origin();
    bool assignFrom(IStyleProperty other, Origin origin);
}

class StyleProperty(T) : IStyleProperty
{
    this(SMP)(Style style, SMP metaProperty)
    if (is(SMP : IStyleMetaProperty) && is(SMP.Value == T))
    {
        _style = style;
        _name = metaProperty.name;
        _value = metaProperty.convert(
            (cast(SMP.CSSValue)metaProperty.initial).value, style
        );
    }

    @property Style style() {
        return _style;
    }

    @property string name() {
        return _name;
    }

    @property Origin origin()
    {
        return _origin;
    }

    @property Signal!() onChange()
    {
        return _onChanged;
    }

    override bool assignFrom(IStyleProperty other, Origin origin)
    {
        auto o = cast(StyleProperty!T)other;
        return setValue(o.value, origin);
    }

    @property T value()
    {
        return _value;
    }

    bool setValue(T val, Origin orig=Origin.code)
    {
        if (orig.priority >= _origin.priority) {
            _origin = orig;
            if (_value != val) {
                _value = val;
                _onChanged.fire();
            }
            return true;
        }
        else {
            return false;
        }
    }

    override string toString()
    {
        import std.conv : to;
        import std.format : format;
        return format("%s: %s (origin %s)", _name, _value, _origin);
    }

    private Style _style;
    private string _name;
    private Origin _origin;
    private T _value;
    private FireableSignal!() _onChanged = new FireableSignal!();
}

interface IStyleMetaProperty
{
    @property string name();
    @property IStyleMetaProperty[] subProperties();
    bool appliesTo(Style style);
    bool applyCascade(Style target, Decl winning);
}

abstract class StyleMetaProperty(V, PV=V) : IStyleMetaProperty
{
    alias Value = V;
    alias ParsedValue = PV;
    alias Property = StyleProperty!V;
    alias CSSValue = TCSSValue!ParsedValue;

    this(string name, in bool inherited, ParsedValue initial, IStyleMetaProperty[] subProperties=[])
    {
        _name = name;
        _inherited = inherited;
        _initial = new CSSValue(initial);
        _subProperties = subProperties;
    }

    final @property string name() {
        return _name;
    }

    final @property bool inherited() {
        return _inherited;
    }

    final @property CSSValue initial() {
        return _initial;
    }

    @property IStyleMetaProperty[] subProperties()
    {
        return _subProperties;
    }

    /// Check whether this property is supported by the given style
    final bool appliesTo(Style style)
    {
        return style.styleProperty(name) !is null;
    }

    bool applyCascade(Style target, Decl winning) {
        CSSValueBase winningVal;
        if (winning) {
            winningVal = winning.value;
            if (!winningVal) {
                winningVal = parseValue(winning.valueTokens);
                winning.value = winningVal;
            }
        }

        return applyCascade(target, winningVal,
                winning ? winning.origin : Origin.init,
                fstSupportingParent(target));
    }

    private Style fstSupportingParent(Style style)
    {
        auto p = style.parent;
        if (p && appliesTo(p)) return p;
        else if (p) return fstSupportingParent(p);
        else return null;
    }

    private bool applyCascade(Style target, CSSValueBase cascaded, Origin origin, lazy Style parent)
    {
        if (!cascaded || cascaded.unset) {
            if (inherited && parent) {
                return applyFromOther(target, parent);
            }
            else {
                return applyFromValue(target, initial, Origin.initial);
            }
        }
        else {
            if (cascaded.inherit && parent) {
                return applyFromOther(target, parent, origin);
            }
            else if (cascaded.inherit) {
                return applyFromValue(target, initial, origin);
            }
            else if (cascaded.initial) {
                return applyFromValue(target, initial, origin);
            }
            else {
                return applyFromValue(target, cascaded, origin);
            }
        }
    }

    private bool applyFromOther(Style target, Style other) {
        auto p = target.styleProperty(name);
        auto op = other.styleProperty(name);
        assert(p && op);
        return p.assignFrom(op, op.origin);
    }

    private bool applyFromOther(Style target, Style other, Origin origin) {
        auto p = target.styleProperty(name);
        auto op = other.styleProperty(name);
        assert(p && op);
        return p.assignFrom(op, origin);
    }

    private bool applyFromValue(Style target, CSSValueBase value, Origin origin)
    {
        auto p = getProperty(target);
        assert(p);
        auto v = cast(CSSValue)value;
        assert(v);
        return p.setValue(convert(v.value, target), origin);
    }

    /// Parse the value from the tokens read in the style sheet.
    /// Starts by checking whether the values is "inherit", "initial" or "unset",
    /// and calls parseValueImpl if it is none of the three.
    final CSSValueBase parseValue(Token[] tokens)
    {
        if (tokens.empty) return null;
        immutable tok = tokens.front;
        if (tok.tok == Tok.ident) {
            if (tok.str == "inherit") {
                return new CSSValueBase(CSSWideValue.inherit);
            }
            else if (tok.str == "initial") {
                return new CSSValueBase(CSSWideValue.initial);
            }
            else if (tok.str == "unset") {
                return new CSSValueBase(CSSWideValue.unset);
            }
        }
        return parseValueImpl(tokens);
    }

    abstract CSSValue parseValueImpl(Token[] tokens);

    static if (is(PV == V)) {
        final Value convert(ParsedValue v, Style target) { return v; }
    }
    else {
        abstract Value convert(ParsedValue v, Style target);
    }

    final Property getProperty(Style target)
    {
        if (!target) return null;
        else return cast(Property)target.styleProperty(name);
    }

    private string _name;
    private bool _inherited;
    private CSSValue _initial;
    private IStyleMetaProperty[] _subProperties;
}


/// template to be mixed-in instantiations of TStyleMetaProperty
/// in order to turn them into a singleton that self registers to
/// the cascade system
mixin template StyleSingleton(T)
{
    public static @property T instance()
    {
        // TODO: thread safety
        if (!_instance) {
            import dgt.css.cascade : addMetaPropertySupport;
            _instance = new T;
            addMetaPropertySupport(_instance);
        }
        return _instance;
    }
    private static __gshared T _instance;
}

/// Origin of a style declaration, including optional important flag.
enum Origin
{
    /// First initialization of the style
    initial     = 0,
    /// Style comes from DGT default stylesheet
    dgt         = 1,
    /// Style is set by the user in a user-wide stylesheet
    user        = 2,
    /// Style comes from the app style author
    author      = 3,
    /// Style override set in the code
    code        = 4,

    /// The important flag takes precedence over the origin and reverses
    /// the order.
    /// Standards: https://www.w3.org/TR/css3-cascade/#cascade-origin
    important   = 0x10,
}

/// Returns: input origin with important flag
Origin important(in Origin orig) pure
{
    return orig | Origin.important;
}

/// Whether an origin has important flag
bool isImportant(in Origin orig) pure
{
    return cast(int)(orig & Origin.important) != 0;
}

/// Get the origin part of an Origin (remove important flag if present)
@property Origin origin(in Origin orig) pure
{
    return cast(Origin)(orig & 0x0f);
}

/// Get priority order of origin taking into account the important flag.
@property int priority(in Origin orig) pure
{
    enum numOrigImp = 10;
    immutable o = cast(int)orig.origin;
    return orig.isImportant ? numOrigImp-o-1 : o;

}

/// Compare priority of two origins.
/// This function is suitable for use with sort algorithm.
/// Returns:
///     true if lhs has higher priority, false otherwise
bool origCmp (in Origin lhs, in Origin rhs) pure
{
    return lhs.priority > rhs.priority;
}

unittest
{
    auto origs = [
        Origin.dgt, Origin.code, important(Origin.user), important(Origin.author)
    ];

    import std.algorithm : equal, sort;
    origs.sort!origCmp();

    assert(equal(origs, [
        important(Origin.user),
        important(Origin.author),
        Origin.code,
        Origin.dgt
    ]));
}
