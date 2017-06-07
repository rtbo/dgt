module dgt.css.om;

import dgt.css.selector;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;


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
    CSSValueBase value;

    Origin origin;
    Selector selector;
    int specificity;
}
