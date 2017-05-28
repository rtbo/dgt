module dgt.css.cascade;

import dgt.css.om;
import dgt.css.parse;
import dgt.css.selector;
import dgt.css.token;
import dgt.css.value;
import dgt.view.style;
import dgt.view.view;

import std.experimental.logger;
import std.range;

/// Entry point of the Style pass before rendering
/// This function interates over the whole tree and assign each style property
/// of each node
void cssCascade(View root)
in {
    assert(root.isRoot);
}
body {
    // TODO: provide mechanism to allow lo-cost styling when only one node need update
    log("starting style pass");
    auto dgtCSS = parseCSS(cast(string)import("dgt.css"), null, Origin.dgt);
    auto ctx = new CascadeContext;
    ctx.cascade(root, [dgtCSS]);
}

/// A style property.
/// Each instance of this class map to a CSS property (e.g. "background-color")
/// and to a field in the Style class (e.g. "backgroundColor")
abstract class CSSProperty
{
    this(in string name, in bool inherited, CSSValueBase initial)
    {
        _name = name;
        _inherited = inherited;
        _initial = initial;
    }

    /// The name of the CSS property as it appears in the style sheets
    final @property string name()
    {
        return _name;
    }

    /// Whether this property gets inherited when no cascaded value is found
    final @property bool inherited()
    {
        return _inherited;
    }

    /// The initial value of this property
    final @property CSSValueBase initial()
    {
        return _initial;
    }

    /// Check whether the property applies to a view
    bool appliesTo(Style style) {
        return true;
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

    abstract CSSValueBase parseValueImpl(Token[] tokens);

    final void applyCascade(Style target, CSSValueBase cascaded)
    {
        auto parent = target.parent;

        if (!cascaded || cascaded.unset) {
            if (inherited && parent && appliesTo(parent)) {
                applyFromParent(target);
            }
            else {
                applyFromValue(target, initial);
            }
        }
        else {
            if (cascaded.inherit && parent && appliesTo(parent)) {
                applyFromParent(target);
            }
            else if (cascaded.inherit && !parent) {
                applyFromValue(target, initial);
            }
            else if (cascaded.initial) {
                applyFromValue(target, initial);
            }
            else {
                applyFromValue(target, cascaded);
            }
        }
    }

    abstract void applyFromParent(Style target);
    abstract void applyFromValue(Style target, CSSValueBase value);

    private string _name;
    private bool _inherited;
    private CSSValueBase _initial;
}

package(dgt)
void initializeCSSCascade() {
    import dgt.css.properties;
    import dgt.enums : Orientation;

    supportedProperties = [
        new BackgroundColorProperty,
        new FontFamilyProperty,
        new FontWeightProperty,
        new FontStyleProperty,
        new FontSizeProperty,

        new LayoutSizeProperty!(Orientation.horizontal),
        new LayoutSizeProperty!(Orientation.vertical),
    ];
}

private:

__gshared CSSProperty[] supportedProperties;

final class CascadeContext
{
    void cascade(View view, Stylesheet[] css)
    {
        if (view.cssStyle.length) {
            css ~= parseCSS(view.cssStyle, null, Origin.app);
        }
        doView(view, css);

        import std.algorithm : each;
        view.children.each!(c => cascade(c, css));
    }

    void doView(View view, Stylesheet[] css)
    {
        import std.algorithm : filter;

        // collect all relevant declarations sorted by origin and importance
        enum numOrigImp = 6;
        Decl[][numOrigImp] origImpDecls;
        foreach(s; css) {
            immutable origin = cast(int)s.origin;
            foreach(r; s.rules.filter!(r => r.selector.matches(view))) {
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
            auto style = view.style;
            if (!p.appliesTo(style)) continue;
            // selecting the highest priority origin and importance
            Decl cascaded;
            foreach(origImp; origImpDecls) {
                foreach(d; origImp) {
                    if (d.property == p.name) {
                        cascaded = d;
                        break;
                    }
                }
                if (cascaded) break;
            }

            CSSValueBase cascadedVal;
            if (cascaded && !cascaded.value) {
                if (!cascaded.value) cascaded.value = p.parseValue(cascaded.valueTokens);
                cascadedVal = cascaded.value;
            }

            p.applyCascade(style, cascadedVal);
        }
    }
}
