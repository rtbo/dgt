/// CSS object model
module dgt.css.om;

import dgt.sg.node;

interface StyleSheet
{
    @property StyleSheet parent();
    @property string title();
    @property SgNode owner();
    @property bool disabled();
}


interface CSSStyleSheet : StyleSheet
{
    @property CSSRule ownerRule();
    @property CSSRule[] cssRules();
}


interface CSSRule
{
    enum Type {
        style       = 1,
        import_     = 3,
        media       = 4,
        fontFace    = 5,
        page        = 6,
        margin      = 9,
        namespace   = 10,
    }

    @property Type type();
    @property string cssText();
    @property CSSRule parentRule();
    @property CSSStyleSheet parentStyleSheet();
}

interface CSSStyleRule : CSSRule
{
    @property string selectorText();
    @property CSSStyleDeclaration style();
}

interface CSSStyleDeclaration
{
    @property string cssText();
    @property size_t length();
    string item(in size_t ind);
    string propertyValue(in string property);
    string propertyPriority(in string property);
}
