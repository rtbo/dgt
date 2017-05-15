/// Module gathering all CSS properties implemented by DGT
module dgt.css.properties;

package:

import dgt.css.cascade;
import dgt.css.color;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;


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

    override void applyFromParent(Style target)
    {
        target.backgroundColor = target.parent.backgroundColor;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        auto cv = cast(CSSValue!Color) value;
        assert(cv);
        target.backgroundColor = cv.value;
    }
}
