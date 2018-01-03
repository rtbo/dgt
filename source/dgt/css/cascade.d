module dgt.css.cascade;

import dgt.core.tree;
import dgt.css.om;
import dgt.css.parse;
import dgt.css.style;

import std.range : retro;

/// Entry point of the Style pass before rendering
/// This function interates over the whole tree and assign each style property
/// of each view
void cssCascade(StyleElement root, Stylesheet dgtCSS)
in {
    assert(root.isStyleRoot);
}
body {
    auto ctx = new CascadeContext;
    ctx.cascade(root, [dgtCSS]);
}

private:

final class CascadeContext
{
    void cascade(StyleElement el, Stylesheet[] css)
    {
        if (el.css.length) {
            css ~= parseCSS(el.css, null, Origin.author);
        }

        if (el.isStyleDirty) {
            if (el.inlineCSS.length) {
                auto cssStr = "*{"~el.inlineCSS~"}";
                auto inlineCSS = parseCSS(cssStr, null, Origin.author);
                doElement(el, css ~ inlineCSS);
            }
            else {
                doElement(el, css);
            }
        }

        if (el.hasChildrenStyleDirty) {
            import std.algorithm : each, filter;
            styleChildren(el)
                .filter!(c => c.isStyleDirty || c.hasChildrenStyleDirty)
                .each!(c => cascade(c, css));
        }
    }

    void doElement(StyleElement el, Stylesheet[] css)
    {
        import std.algorithm : cmp, filter, sort, SwapStrategy;

        Decl[] collectedDecls;
        // retro is used such as to have inner scope before outer scope
        foreach(s; retro(css)) {
            foreach(r; s.rules.filter!(r => r.selector.matches(el))) {
                collectedDecls ~= r.decls;
            }
        }

        // sort declarations by:
        //  1. origin priority
        //  2. specificity
        //  3. scope (already done, using stable sort)
        //  4. order of appearance (already done, using stable sort)
        static bool declCmp(Decl a, Decl b) {
            //immutable nameCmp = cmp(a.property, b.property);
            //if (nameCmp != 0) return nameCmp < 0;
            immutable prioCmp = a.origin.priority - b.origin.priority;
            if (prioCmp != 0) return prioCmp > 0;
            return a.specificity > b.specificity;
        }
        collectedDecls.sort!(declCmp, SwapStrategy.stable);

        foreach (smp; el.styleMetaProperties) {
            smp.applyCascade(el, collectedDecls);
        }
    }
}
