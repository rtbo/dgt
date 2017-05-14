module dgt.css.om;

import dgt.css.selector;
import dgt.css.token;
import dgt.css.value;

enum Origin
{
    app     = 0,
    user    = 1,
    dgt     = 2,
}

class Stylesheet
{
    Origin origin;
    Rule[] rules;

    void setSpecificity()
    {
        foreach(r; rules) {
            immutable s = r.selector.specificity;
            foreach (d; r.decls) {
                d.specificity = s;
            }
        }
    }
}

class Rule
{
    Selector selector;
    Decl[] decls;
}

class Decl
{
    string property;
    Token[] valueTokens;
    bool important;

    int specificity;
    CSSValueBase value;
}
