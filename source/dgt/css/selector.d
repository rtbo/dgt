/// CSS Selectors
module dgt.css.selector;

import dgt.css.token;
import dgt.sg.node;

import std.exception;
import std.range;

interface Selector
{
    bool matches(SgNode node);
    @property int specificity();
}

Selector parseSelector(string css)
{
    import std.utf : byDchar;
    auto tokens = makeTokenInput(byDchar(css));
    return parseSelectorGroup(tokens);
}

Selector parseSelector(Tokens)(Tokens tokens)
if (isInputRange!Tokens && is(ElementType!Tokens == Token))
{
    return parseSelectorGroup(tokens);
}

package:

abstract class AbstractSelector : Selector
{
    enum Type {
        simple      = 0x01,
        simpleSeq   = 0x02,
        group       = 0x03,
        combinator  = 0x04,
        descendant  = 0x10 | combinator,
        child       = 0x20 | combinator,
        adjSibl     = 0x40 | combinator,
        genSibl     = 0x80 | combinator,
    }

    abstract @property Type type();
}

class SimpleSelectorSeq : AbstractSelector
{
    SimpleSelector[] seq;

    override @property Type type()
    {
        return Type.simpleSeq;
    }

    bool matches(SgNode node)
    {
        import std.algorithm : all;
        return seq.all!(s => s.matches(node));
    }

    @property int specificity()
    {
        import std.algorithm : map, sum;
        return seq.map!(s => s.specificity).sum();
    }
}

class SimpleSelector : AbstractSelector
{
    enum SSType {
        type,
        universal,
        class_,
        id,
        pseudo,
        attr,       // unsupported
    }

    SSType ssType;
    string val;

    override @property Type type()
    {
        return Type.simple;
    }

    bool matches(SgNode node)
    {
        final switch(ssType) {
        case SSType.type:
            return node.cssType == val;
        case SSType.universal:
            return true;
        case SSType.class_:
            return node.cssClass == val;
        case SSType.id:
            return node.id == val;
        case SSType.pseudo:
            if (val == "root") {
                return node.isRoot;
            }
            else {
                throw new Exception("Unsupported pseudo selector: "~val);
            }
        case SSType.attr:
            assert(false, "unimplemented");
        }
    }

    @property int specificity()
    {
        final switch(ssType) {
        case SSType.type:
            return 1;
        case SSType.class_:
        case SSType.attr:
        case SSType.pseudo:
            return 10;
        case SSType.id:
            return 100;
        case SSType.universal:
            return 0;
        }
    }
}

class Group : AbstractSelector
{
    AbstractSelector[] selectors;

    override @property Type type()
    {
        return Type.group;
    }

    bool matches(SgNode node)
    {
        import std.algorithm : any;
        return selectors.any!(s => s.matches(node));
    }

    @property int specificity()
    {
        import std.algorithm : map, sum;
        return selectors.map!(s => s.specificity).sum();
    }
}

class Combinator : AbstractSelector
{
    AbstractSelector lhs;
    AbstractSelector rhs;
    Type _type;

    override @property Type type()
    {
        return _type;
    }

    bool matches(SgNode node)
    {
        if (!rhs.matches(node)) return false;
        switch(_type) {
        case Type.descendant:
            auto p = node.parent;
            while (p) {
                if (lhs.matches(p)) return true;
                else p = p.parent;
            }
            return false;
        case Type.child:
            auto p = node.parent;
            return p ? lhs.matches(p) : false;
        case Type.adjSibl:
            auto s = node.prevSibling;
            return s ? lhs.matches(s) : false;
        case Type.genSibl:
            auto s = node.prevSibling;
            while (s) {
                if (lhs.matches(s)) return true;
                else s = s.prevSibling;
            }
            return false;
        default:
            assert(false);
        }
    }

    @property int specificity()
    {
        return lhs.specificity + rhs.specificity;
    }
}


package:

enum SelOp
{
    none = 0,
    descendant = ' ',
    child = '>',
    adjSibl = '+',
    genSibl = '~',
    group = ',',
}

AbstractSelector parseSelectorGroup(Tokens)(Tokens tokens)
{
    import std.algorithm : until;

    // left trim
    while (!tokens.empty && tokens.front.tok == Tok.whitespace) {
        tokens.popFront();
    }

    AbstractSelector[] sels = [
        parseSelectorCombinator(tokens)
    ];
    if (!sels[0]) return null;

    while (!tokens.empty) {
        immutable op = parseSelOp(tokens);
        if (op == SelOp.group) {
            auto s = parseSelectorCombinator(tokens);
            if (s) {
                sels ~= s;
            }
        }
        else {
            break;
        }
    }

    if (sels.length > 1) {
        auto g = new Group;
        g.selectors = sels;
        return g;
    }
    else {
        return sels[0];
    }
}

AbstractSelector parseSelectorCombinator(Tokens)(Tokens tokens)
{
    import std.algorithm : until;

    // left trim
    while (!tokens.empty && tokens.front.tok == Tok.whitespace) {
        tokens.popFront();
    }

    AbstractSelector s = parseSimpleSelectorSeq(tokens);

    while (!tokens.empty) {
        auto op = parseSelOp(tokens);
        AbstractSelector.Type type;
        switch (op) {
        case SelOp.descendant:
            type = AbstractSelector.Type.descendant;
            break;
        case SelOp.child:
            type = AbstractSelector.Type.child;
            break;
        case SelOp.adjSibl:
            type = AbstractSelector.Type.adjSibl;
            break;
        case SelOp.genSibl:
            type = AbstractSelector.Type.genSibl;
            break;
        case SelOp.group:
            return s;
        default:
            throw new Exception("selector parsing error");
        }

        auto lhs = s;
        auto rhs = parseSelectorCombinator(tokens);
        auto c = new Combinator;
        c.lhs = lhs;
        c.rhs = rhs;
        c._type = type;
        s = c;
    }

    return s;
}

SelOp parseSelOp(Tokens)(ref Tokens tokens)
{
    bool hadWS;
    while(!tokens.empty) {
        auto tok = tokens.front;
        if (tok.tok == Tok.whitespace) {
            hadWS = true;
        }
        else if (tok.tok == Tok.delim) {
            switch (tok.delimCP) {
            case '~':
                return SelOp.genSibl;
            case '+':
                return SelOp.adjSibl;
            case '>':
                return SelOp.child;
            case ',':
                return SelOp.group;
            default:
                break;
            }
            break;
        }
        else {
            break;
        }

        tokens.popFront();
    }
    return hadWS ? SelOp.descendant : SelOp.none;
}


AbstractSelector parseSimpleSelectorSeq(Tokens)(ref Tokens tokens)
{
    import std.conv : to;
    if (tokens.empty) return null;

    SimpleSelector[] seq;

    auto tok = tokens.front;

    if (tok.tok == Tok.ident) {
        auto s = new SimpleSelector;
        s.ssType = SimpleSelector.SSType.type;
        s.val = tok.str;
        seq ~= s;
        tokens.popFront();
    }
    else if (tok.tok == Tok.delim && tok.delimCP == '*') {
        auto s = new SimpleSelector;
        s.ssType = SimpleSelector.SSType.universal;
        seq ~= s;
        tokens.popFront();
    }

    while (!tokens.empty) {
        tok = tokens.front;

        bool exit;

        if (tok.tok == Tok.hash) {
            auto s = new SimpleSelector;
            s.ssType = SimpleSelector.SSType.id;
            s.val = tok.str;
            seq ~= s;
        }
        else if (tok.tok == Tok.delim) {
            switch(tok.delimCP) {
            case '.':
                tokens.popFront();
                if (tokens.empty || tokens.front.tok != Tok.ident) {
                    throw new Exception("invalid selector class");
                }
                auto s = new SimpleSelector;
                s.ssType = SimpleSelector.SSType.class_;
                s.val = tok.str;
                seq ~= s;
                break;
            case '~':
            case '+':
            case '>':
                exit = true;
                break;
            default:
                throw new Exception("unexpected selector token");
            }
        }
        else if (tok.tok == Tok.whitespace || tok.tok == Tok.comma) {
            exit = true;
        }
        else if (tok.tok == Tok.brackOp) {
            assert(false, "attribute selectors unimplemented");
        }
        else if (tok.tok == Tok.colon) {
            tokens.popFront();
            enforce(
                !tokens.empty && tokens.front.tok == Tok.ident,
                "invalid or unsupported selector pseudo class"
            );
            auto s = new SimpleSelector;
            s.ssType = SimpleSelector.SSType.pseudo;
            s.val = tokens.front.str;
            seq ~= s;
        }
        else {
            throw new Exception("unexpected selector token");
        }

        if (exit) break;
        else tokens.popFront();
    }

    if (seq.length > 1) {
        auto s = new SimpleSelectorSeq;
        s.seq = seq;
        return s;
    }
    else if (seq.length == 1) {
        return seq[0];
    }
    else {
        return null;
    }
}
