module dgt.css.cascade;

import dgt.css.color;
import dgt.css.om;
import dgt.css.parse;
import dgt.css.selector;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;
import dgt.sg.node;
import dgt.sg.parent;

import std.range;

abstract class CSSProperty
{
    this(in string name, in ValueType type, in bool inherited, CSSValueBase initial)
    {
        _name = name;
        _type = type;
        _inherited = inherited;
        _initial = initial;
    }

    final @property string name()
    {
        return _name;
    }

    final @property ValueType type()
    {
        return _type;
    }

    final @property bool inherited()
    {
        return _inherited;
    }

    final @property CSSValueBase initial()
    {
        return _initial;
    }

    final CSSValueBase parse(Token[] tokens)
    {
        if (tokens.empty) return null;
        immutable tok = tokens.front;
        if (tok.tok == Tok.ident) {
            if (tok.str == "inherit") {
                return makeValue(CSSWideValue.inherit);
            }
            else if (tok.str == "initial") {
                return makeValue(CSSWideValue.initial);
            }
            else if (tok.str == "unset") {
                return makeValue(CSSWideValue.unset);
            }
        }
        return parseValue(tokens);
    }

    final void applyCascade(Style target, Style parent, CSSValueBase cascaded)
    {
        if (!cascaded || cascaded.unset) {
            if (inherited && parent) {
                applyFromParent(target, parent);
            }
            else {
                applyFromValue(target, initial, null);
            }
        }
        else {
            if (cascaded.inherit && parent) {
                applyFromParent(target, parent);
            }
            else if (cascaded.inherit && !parent) {
                applyFromValue(target, initial, null);
            }
            else if (cascaded.initial) {
                applyFromValue(target, initial, null);
            }
            else {
                applyFromValue(target, cascaded, parent);
            }
        }
    }

    abstract CSSValueBase makeValue(CSSWideValue value);
    abstract CSSValueBase parseValue(Token[] tokens);

    abstract void applyFromParent(Style target, Style parent);
    abstract void applyFromValue(Style target, CSSValueBase value, Style parent);

    private string _name;
    private ValueType _type;
    private bool _inherited;
    private CSSValueBase _initial;
}


final class BackgroundColorProperty : CSSProperty
{
    this()
    {
        super(
            "background-color", ValueType.color, false,
            new CSSValue!Color(Color(ColorName.transparent))
        );
    }

    override CSSValue!Color makeValue(CSSWideValue value)
    {
        return new CSSValue!Color(value);
    }

    override CSSValue!Color parseValue(Token[] tokens)
    {
        return new CSSValue!Color(parseColor(tokens));
    }

    override void applyFromParent(Style target, Style parent)
    {
        target.backgroundColor = parent.backgroundColor;
    }

    override void applyFromValue(Style target, CSSValueBase value, Style parent)
    {
        auto cv = cast(CSSValue!Color) value;
        assert(cv);
        target.backgroundColor = cv.value;
    }
}

__gshared CSSProperty[] supportedProperties;

shared static this()
{
    supportedProperties = [
        new BackgroundColorProperty,
    ];
}

void cssCascade(SgParent root)
in {
    assert(root.isRoot);
}
body {
    auto dgtCSS = parseCSS(cast(string)import("dgt.css"), null, Origin.dgt);
    auto ctx = new CascadeContext;
    ctx.cascade(root, [dgtCSS]);
}

final class CascadeContext
{
    void cascade(SgParent node, Stylesheet[] css)
    {
        if (node.cssStyle.length) {
            css ~= parseCSS(node.cssStyle, null, Origin.app);
        }
        doNode(node, css);
        foreach(c; node.children) {
            auto p = cast(SgParent)c;
            if (p) cascade(p, css);
            else cascade(c, css);
        }
    }

    void cascade(SgNode node, Stylesheet[] css)
    {
        if (node.cssStyle.length) {
            css ~= parseCSS(node.cssStyle, null, Origin.app);
        }
        doNode(node, css);
    }

    void doNode(SgNode node, Stylesheet[] css)
    {
        import std.algorithm : filter;

        // collect all relevant declarations sorted by origin and importance
        enum numOrigImp = 6;
        Decl[][numOrigImp] origImpDecls;
        foreach(s; css) {
            immutable origin = cast(int)s.origin;
            foreach(r; s.rules.filter!(r => r.selector.matches(node))) {
                foreach(d; r.decls) {
                    immutable ind = d.important ? numOrigImp-origin-1 : origin;
                    origImpDecls[ind] ~= d;
                }
            }
        }

        // sort them by specificity
        foreach (decls; origImpDecls) {
            import std.algorithm : sort, SwapStrategy;
            // bigger specificity first
            alias specCmp = (a, b) => a.specificity > b.specificity;
            // stable to keep order of declaration
            decls.sort!(specCmp, SwapStrategy.stable);
        }

        // the rest is handled property by property
        foreach (p; supportedProperties) {
            // selecting the highest priority origin and importance
            Decl[] decls = null;
            foreach(origImp; origImpDecls) {
                foreach(d; origImp) {
                    if (d.property == p.name) {
                        decls = origImp;
                        break;
                    }
                }
                if (decls.length) break;
            }

            auto cascaded = decls.length ? decls[0] : null;
            CSSValueBase cascadedVal;
            if (cascaded && !cascaded.value) {
                if (!cascaded.value) cascaded.value = p.parse(cascaded.valueTokens);
                cascadedVal = cascaded.value;
            }

            auto ps = node.parent ? node.parent.style : null;
            p.applyCascade(node.style, ps, cascadedVal);
        }
    }
}
