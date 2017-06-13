module dgt.css.cascade;

import dgt.css.om;
import dgt.css.parse;
import dgt.css.selector;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;
import dgt.view.view;

import std.experimental.logger;
import std.range;

/// Entry point of the Style pass before rendering
/// This function interates over the whole tree and assign each style property
/// of each view
void cssCascade(View root)
in {
    assert(root.isRoot);
}
body {
    // TODO: provide mechanism to allow lo-cost styling when only one view need update
    auto dgtCSS = parseCSS(cast(string)import("dgt.css"), null, Origin.dgt);
    auto ctx = new CascadeContext;
    ctx.cascade(root, [dgtCSS]);
}

private:

final class CascadeContext
{
    void cascade(View view, Stylesheet[] css)
    {
        if (view.css.length) {
            css ~= parseCSS(view.css, null, Origin.author);
        }
        if (view.inlineCSS.length) {
            auto cssStr = "*{"~view.inlineCSS~"}";
            auto inlineCSS = parseCSS(cssStr, null, Origin.author);
            doView(view, css ~ inlineCSS);
        }
        else {
            doView(view, css);
        }

        import std.algorithm : each;
        view.children.each!(c => cascade(c, css));
    }

    void doView(View view, Stylesheet[] css)
    {
        import std.algorithm : cmp, filter, sort, SwapStrategy;

        Decl[] collectedDecls;
        // retro is used such as to have inner scope before outer scope
        foreach(s; retro(css)) {
            foreach(r; s.rules.filter!(r => r.selector.matches(view))) {
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

        foreach (smp; view.styleMetaProperties) {
            smp.applyCascade(view, collectedDecls);
        }
    }
}
