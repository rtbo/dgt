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
            "background-color", false,
            new CSSValue!Color(Color(ColorName.transparent))
        );
    }

    override CSSValue!Color parseValueImpl(Token[] tokens)
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

final class FontFamilyProperty : CSSProperty
{
    this()
    {
        super(
            "font-family", true,
            new CSSValue!(string[])(["sans-serif"])
        );
    }

    override CSSValue!(string[]) parseValueImpl(Token[] tokens)
    {
        import std.algorithm : filter;
        auto toks = tokens.filter!(t => t.tok != Tok.whitespace);

        string[] families;
        while (!toks.empty) {
            if (toks.front.tok == Tok.ident) {
                string fam = toks.front.str;
                toks.popFront();
                while (!toks.empty && toks.front.tok == Tok.ident) {
                    fam ~= " " ~ toks.front.str;
                    toks.popFront();
                }
                families ~= fam;
            }
            else if (toks.front.tok == Tok.str) {
                families ~= toks.front.str;
                toks.popFront();
            }
            if (!toks.empty && toks.front.tok != Tok.comma) {
                return null; // invalid
            }
            else if (!toks.empty) {
                toks.popFront();
            }
        }
        return new CSSValue!(string[])(families);
    }

    override void applyFromParent(Style target)
    {
        target.fontFamily = target.parent.fontFamily;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        auto cv = cast(CSSValue!(string[])) value;
        assert(cv);
        target.fontFamily = cv.value;
    }
}
