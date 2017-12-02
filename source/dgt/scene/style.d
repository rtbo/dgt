module dgt.scene.style;

import dgt.css.style;
import dgt.scene.node;

/// give support to a style instance to a node
auto addStyleSupport(SMP)(Node node, SMP metaProp)
if (is(SMP : IStyleMetaProperty) && !SMP.isShorthand)
{
    auto sp = new SMP.Property(node, metaProp);
    node._styleProperties[metaProp.name] = sp;
    if (!metaProp.hasShorthand) node._styleMetaProperties ~= metaProp;
    return sp;
}

/// give support to a shorthand style instance to a node
void addShorthandStyleSupport(SMP)(Node node, SMP metaProp)
if (is(SMP : IStyleMetaProperty) && SMP.isShorthand)
{
    node._styleMetaProperties ~= metaProp;
}
