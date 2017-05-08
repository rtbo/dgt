/// implementation of CSSOM
module dgt.css.omimpl;

package:

import dgt.css.om;
import dgt.sg.node;

import std.algorithm;
import std.range;

class CSSStyleSheetImpl : CSSStyleSheet
{
    private CSSStyleSheetImpl _parent;
    private string _title;
    private SgNode _owner;
    private CSSRule[] _cssRules;

    @property StyleSheet parent() { return _parent; }
    @property string title() { return _title; }
    @property SgNode owner() { return  _owner; }
    @property bool disabled() { return false; }
    @property CSSRule ownerRule() { return null; }
    @property CSSRule[] cssRules()
    {
        return _cssRules;
    }
}

class CSSStyleRuleImpl : CSSStyleRule
{
    private CSSRule _parentRule;
    private CSSStyleSheet _parentStyleSheet;
    private string _selectorText;
    private CSSStyleDeclarationImpl _style;

    @property Type type() { return Type.style; }
    @property string cssText()
    {
        assert(false, "unimplemented");
    }
    @property CSSRule parentRule() { return _parentRule; }
    @property CSSStyleSheet parentStyleSheet() { return _parentStyleSheet; }
    @property string selectorText() { return _selectorText; }
    @property CSSStyleDeclaration style() { return _style; }
}

struct CSSProp
{
    string prop;
    string value;
    string prio;
}

class CSSStyleDeclarationImpl : CSSStyleDeclaration
{
    private CSSProp[] _props;

    @property string cssText() { assert(false, "unimplemented"); }
    @property size_t length() { return _props.length; }
    string item(in size_t ind) { return _props[ind].prop; }
    string propertyValue(in string property)
    {
        auto p = _props.find!(p => p.prop == property);
        if (!p.empty) {
            return p.front.value;
        }
        else {
            return "";
        }
    }
    string propertyPriority(in string property)
    {
        auto p = _props.find!(p => p.prop == property);
        if (!p.empty) {
            return p.front.prio;
        }
        else {
            return "";
        }
    }
}
