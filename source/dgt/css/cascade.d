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
    if (propSortDirty) {
        import std.algorithm : sort;
        supportedProperties.sort!"a.name < b.name";
        propSortDirty = false;
    }
    // TODO: provide mechanism to allow lo-cost styling when only one view need update
    auto dgtCSS = parseCSS(cast(string)import("dgt.css"), null, Origin.dgt);
    auto ctx = new CascadeContext;
    ctx.cascade(root, [dgtCSS]);
}

void addMetaPropertySupport(StyleMetaProperty smp)
{
    supportedProperties ~= smp;
    propSortDirty = true;
    debug {
        supportedPropertiesMap[smp.name] = smp;
    }
}

private:

__gshared StyleMetaProperty[] supportedProperties;
__gshared bool propSortDirty;
debug {
    __gshared StyleMetaProperty[string] supportedPropertiesMap;
}

final class CascadeContext
{
    void cascade(View view, Stylesheet[] css)
    {
        if (view.css.length) {
            css ~= parseCSS(view.css, null, Origin.author);
        }
        doView(view, css);

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
        //  1. property name
        //  2. origin priority
        //  3. specificity
        //  4. scope (already done, using stable sort)
        //  4. order of appearance (already done, using stable sort)
        static bool declCmp(Decl a, Decl b) {
            immutable nameCmp = cmp(a.property, b.property);
            if (nameCmp != 0) return nameCmp < 0;
            else return a.specificity > b.specificity;
        }
        collectedDecls.sort!(declCmp, SwapStrategy.stable);

        // the rest is handled property by property
        foreach (p; supportedProperties) {
            immutable pname = p.name;
            if (!p.appliesTo(view)) continue;
            // both collections are sorted by name, so we can safely skip some
            while (!collectedDecls.empty && collectedDecls.front.property < pname) {
                collectedDecls.popFront();
            }

            // the winning declaration is the first one here
            Decl winning;
            if (!collectedDecls.empty && collectedDecls.front.property == pname) {
                winning = collectedDecls.front;
                collectedDecls.popFront();
            }

            CSSValueBase cascadedVal;
            if (winning) {
                if (!winning.value) {
                    winning.value = p.parseValue(winning.valueTokens);
                }
                cascadedVal = winning.value;
            }
            p.applyCascade(view, cascadedVal, winning ? winning.origin : Origin.init);
        }
    }
}
