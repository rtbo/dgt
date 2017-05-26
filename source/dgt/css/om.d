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

    Selector selector;
    int specificity;
    CSSValueBase value;
}
