/// Module that contains main style related interfaces and base classes
module dgt.css.style;

import dgt.css : dgtCssLog;
//import dgt.gfx.geometry;
import dgt.core.signal;
import dgt.css.om;
import dgt.css.token;
import dgt.css.value;

import std.range;

/// Bit flags that describe the pseudo state of a StyleElement.
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


/// StyleElement must be implemented by a tree structure that can receive css style properties
interface StyleElement
{
    /// The parent of this style element, or null if this element is the root.
    @property StyleElement styleParent();
    /// Whether this element is the root of the tree.
    final @property bool isStyleRoot() {
        return styleParent is null;
    }
    /// The root of the tree
    @property StyleElement styleRoot();
    /// Get the next sibling of this element.
    @property StyleElement stylePrevSibling();
    /// Get the previous sibling of this element.
    @property StyleElement styleNextSibling();
    /// Get the first child of this element.
    @property StyleElement styleFirstChild();
    /// Get the last child of this element.
    @property StyleElement styleLastChild();

    /// The inline css of this element.
    /// That is, style that apply to this node, but not to its children.
    /// It must be specified as standalone declarations (without surrounding rules).
    @property string inlineCSS();
    /// A stylesheet attached to this element. A stylesheet contains CSS rules
    /// and applies to this element and its children.
    @property string css();

    /// The cssType of this element is equivalent to element tag in html
    /// Ex. Button receive the type 'button'
    @property string cssType();
    /// The id as used by css selector rule '#'
    @property string id();
    /// The css class as used by css selector rule '.'
    @property string cssClass();
    /// The current pseudo state of the element. Usable by pseudo class selector rules.
    @property PseudoState pseudoState();

    /// Get the size of the viewport the style appears in. Used for sizes
    /// relative to view port (e.g. 12vmin)
    @property float[2] viewportSize();
    /// Get the DPI of this style. Used for absolute sizes in inch, or centimeters
    @property float dpi();

    /// The meta properties supported by this element
    /// This only lists top-level properties. E.g: if a property is supported, but
    /// has a shorthand, only the shorthand will be in this list.
    @property IStyleMetaProperty[] styleMetaProperties();
    /// Get the property object by name. (e.g. "background-color")
    IStyleProperty styleProperty(string name);

    /// Check whether the style of this element was modified and needs a pass
    @property bool isStyleDirty();
    /// Check whether one descendant of this element need a style pass
    @property bool hasChildrenStyleDirty();
}


/// Returns a bidirectional range over the children of a style element
auto styleChildren(StyleElement se) {
    return styleSiblingRange(se.styleFirstChild, se.styleLastChild);
}

/// Returns a bidirectional range that iterates from sibling to sibling, from first until last.
auto styleSiblingRange(StyleElement first, StyleElement last)
in {
    assert(
        (!first && !last) ||
        (first && last && first.styleParent is last.styleParent)
    );
}
body {
    return StyleSiblingRange(first, last);
}

/// A CSS property value
interface IStyleProperty
{
    @property StyleElement style();
    @property string name();
    @property Origin origin();
    bool assignFrom(IStyleProperty other, Origin origin);
}

/// Style property implementation for a specific type
class StyleProperty(T) : IStyleProperty
{
    this(SMP)(StyleElement style, SMP metaProperty)
    if (is(SMP : IStyleMetaProperty) && is(SMP.Value == T))
    {
        _style = style;
        _name = metaProperty.name;
        _value = metaProperty.convert(
            (cast(SMP.CSSValue)metaProperty.initial).value, style
        );
        _onChanged = new FireableSignal!();
    }

    @property StyleElement style() {
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

    private StyleElement _style;
    private string _name;
    private Origin _origin;
    private T _value;
    private FireableSignal!() _onChanged;
}

interface IStyleMetaProperty
{
    @property string name();
    @property IStyleMetaProperty[] subProperties();
    /// Check whether this property is supported by the given style
    bool appliesTo(StyleElement style);
    void applyCascade(StyleElement target, Decl[] collected);
    void applyInitial(StyleElement target, Origin origin);
    void applyFromOther(StyleElement target, StyleElement other, Origin origin);
    void applyFromValue(StyleElement target, CSSValueBase value, Origin origin);
}

abstract class StyleMetaPropertyBase(PV) : IStyleMetaProperty
{
    alias ParsedValue = PV;
    alias CSSValue = TCSSValue!ParsedValue;

    this(string name, bool inherited) {
        _name = name;
        _inherited = inherited;
    }

    final @property string name() {
        return _name;
    }

    final @property bool inherited() {
        return _inherited;
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
        ParsedValue pv;
        if (parseValueImpl(tokens, pv)) {
            return new CSSValue(pv);
        }
        else {
            return null;
        }
    }

    abstract bool parseValueImpl(ref Token[] tokens, out ParsedValue val);

    final protected StyleElement fstSupportingParent(StyleElement style)
    {
        auto p = style.styleParent;
        if (p && appliesTo(p)) return p;
        else if (p) return fstSupportingParent(p);
        else return null;
    }

    final protected Decl winningDecl(Decl[] collected)
    {
        immutable n = _name;
        foreach (d; collected) {
            if (d.property == n) return d;
        }
        return null;
    }

    final protected void applyWinning(StyleElement target, Decl winning)
    in {
        assert(winning);
    }
    body {
        CSSValueBase winningVal = winning.value;
        if (!winningVal) {
            winningVal = parseValue(winning.valueTokens);
            winning.value = winningVal;
            if (!winningVal) {
                dgtCssLog.warningf("could not parse winning declaration "~winning.property);
                applyInitial(target, winning.origin);
                return;
            }
        }
        if (winningVal.inherit) {
            auto p = fstSupportingParent(target);
            if (p) {
                applyFromOther(target, p, winning.origin);
            }
            else {
                applyInitial(target, winning.origin);
            }
        }
        else if (winningVal.initial) {
            applyInitial(target, winning.origin);
        }
        else if (winningVal.unset) {
            auto p = fstSupportingParent(target);
            if (inherited && p) {
                applyFromOther(target, p, winning.origin);
            }
            else {
                applyInitial(target, winning.origin);
            }
        }
        else {
            applyFromValue(target, winningVal, winning.origin);
        }
    }

    private string _name;
    private bool _inherited;
}

abstract class StyleShorthandProperty(PV) : StyleMetaPropertyBase!PV
{
    enum isShorthand = true;

    this(string name, bool inherited, IStyleMetaProperty[] subProperties)
    {
        super(name, inherited);
        _subProperties = subProperties;
    }

    @property IStyleMetaProperty[] subProperties()
    {
        return _subProperties;
    }

    bool appliesTo(StyleElement style)
    {
        import std.algorithm : all;
        return _subProperties.all!(sp => sp.appliesTo(style));
    }

    final void applyCascade(StyleElement target, Decl[] collected) {
        Decl winning = winningDecl(collected);
        if (winning) {
            applyWinning(target, winning);
        }
        else {
            import std.algorithm : each;
            _subProperties.each!(sp => sp.applyCascade(target, collected));
        }
    }

    final void applyInitial(StyleElement target, Origin origin) {
        import std.algorithm : each;
        _subProperties.each!(sp => sp.applyInitial(target, origin));
    }

    final void applyFromOther(StyleElement target, StyleElement other, Origin origin) {
        import std.algorithm : each;
        _subProperties.each!(sp => sp.applyFromOther(target, other, origin));
    }

    private IStyleMetaProperty[] _subProperties;
}

abstract class StyleMetaProperty(V, PV=V) : StyleMetaPropertyBase!PV
{
    alias Value = V;
    alias Property = StyleProperty!V;
    enum isShorthand = false;

    this(string name, in bool inherited, ParsedValue initial, bool hasShorthand)
    {
        super(name, inherited);
        _initialVal = initial;
        _initial = new CSSValue(initial);
        _hasShorthand = hasShorthand;
    }

    final @property bool hasShorthand() { return _hasShorthand; }

    final @property ParsedValue initialVal() {
        return _initialVal;
    }

    final @property CSSValue initial() {
        return _initial;
    }

    @property IStyleMetaProperty[] subProperties()
    {
        return [];
    }

    final bool appliesTo(StyleElement style)
    {
        return style.styleProperty(name) !is null;
    }

    void applyCascade(StyleElement target, Decl[] collected) {
        Decl winning = winningDecl(collected);
        if (winning) {
            applyWinning(target, winning);
        }
        else {
            applyInitial(target, Origin.initial);
        }
    }

    void applyInitial(StyleElement target, Origin origin)
    {
        applyFromValue(target, initial, origin);
    }

    void applyFromOther(StyleElement target, StyleElement other, Origin origin) {
        auto p = target.styleProperty(name);
        auto op = other.styleProperty(name);
        assert(p && op);
        p.assignFrom(op, origin);
    }

    void applyFromValue(StyleElement target, CSSValueBase value, Origin origin)
    {
        auto p = getProperty(target);
        assert(p);
        auto v = cast(CSSValue)value;
        assert(v);
        p.setValue(convert(v.value, target), origin);
    }


    static if (is(PV == V)) {
        pragma(inline, true)
        final Value convert(ParsedValue v, StyleElement) { return v; }
    }
    else {
        abstract Value convert(ParsedValue v, StyleElement target);
    }

    final Property getProperty(StyleElement target)
    {
        if (!target) return null;
        else return cast(Property)target.styleProperty(name);
    }

    private ParsedValue _initialVal;
    private CSSValue _initial;
    private bool _hasShorthand;
}


/// template to be mixed-in instantiations of TStyleMetaProperty
/// in order to turn them into a singleton.
mixin template StyleSingleton(T)
{
    public static @property T instance()
    {
        // TODO: thread safety
        if (!_instance) {
            _instance = new T;
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


private:

/// Bidirectional range that traverses a sibling node list
struct StyleSiblingRange
{
    StyleElement _first;
    StyleElement _last;

    this (StyleElement first, StyleElement last)
    {
        _first = first;
        _last = last;
    }

    @property bool empty() { return _first is null; }
    @property auto front() { return _first; }
    void popFront() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _first = _first.styleNextSibling;
        }
    }

    @property auto save()
    {
        return StyleSiblingRange(_first, _last);
    }

    @property auto back() { return _last; }
    void popBack() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _last = _last.stylePrevSibling;
        }
    }
}
