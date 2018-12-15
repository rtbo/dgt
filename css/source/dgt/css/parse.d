/// CSS parser module
///
/// Standards:
///    this module is a partial implementation of CSS-SYNTAX-3 §5.
///    https://www.w3.org/TR/css-syntax-3
///    The snapshot 2017 was used as reference.
module dgt.css.parse;

import dgt.css : dgtCssLog;
import dgt.css.om;
import dgt.css.selector;
import dgt.css.style;
import dgt.css.token;

import std.exception;
import std.range;
import std.traits;

Stylesheet parseCSS(CharRange)(in CharRange css, CssErrorCollector errors=null, Origin origin=Origin.author)
if (isInputRange!CharRange && isSomeChar!(ElementEncodingType!CharRange))
{
    import std.utf : byDchar;
    auto tokens = makeTokenInput(byDchar(css), errors);
    auto parser = makeParser(tokens, errors);
    auto rules = parser.consumeRuleList();
    auto ss = new Stylesheet;
    ss.origin = origin;
    ss.rules = rules;
    foreach (r; ss.rules) {
        foreach (d; r.decls) {
            // only important flag set at first
            d.origin |= origin;
        }
    }
    return ss;
}

package:


unittest
{
    import std.utf : byDchar;
    string test = `
        h1 {
            color: #123456;
            text-align: center;
        }
    `;
    auto tokInput = makeTokenInput(byDchar(test));
    auto parser = makeParser(tokInput);
    auto rules = parser.consumeRuleList();

    assert(rules.length == 1);
    assert(rules[0].decls.length == 2);
    auto colDecl = rules[0].decls[0];
    auto taDecl = rules[0].decls[1];
    assert(colDecl.property == "color");
    assert(colDecl.valueTokens.length == 1);
    assert(colDecl.valueTokens[0].tok == Tok.hash);
    assert(colDecl.valueTokens[0].str == "123456");
    assert(!colDecl.origin.isImportant);
    assert(taDecl.property == "text-align");
    assert(taDecl.valueTokens.length == 1);
    assert(taDecl.valueTokens[0].tok == Tok.ident);
    assert(taDecl.valueTokens[0].str == "center");
    assert(!taDecl.origin.isImportant);
}

auto makeParser(TokenInput)(TokenInput tokenInput, CssErrorCollector errors=null)
if (isInputRange!TokenInput && is(ElementType!TokenInput == Token))
{
    return CSSParser!TokenInput(tokenInput, errors);
}

struct CSSParser(TokenInput)
{
    TokenInput tokenInput;
    enum bool toplevel = true;
    CssErrorCollector errors;

    Token[2] aheadBuf;
    Token[] ahead;

    this(TokenInput tokenInput, CssErrorCollector errors)
    {
        this.tokenInput = tokenInput;
        this.errors = errors;
    }

    Token getToken()
    {
        if (ahead.length) {
            auto tok = ahead[$-1];
            ahead = ahead[0 .. $-1];
            return tok;
        }
        else if (tokenInput.empty) {
            return Token(Tok.eoi);
        }
        else {
            auto tok = tokenInput.front;
            tokenInput.popFront();
            return tok;
        }
    }

    void putToken(Token tok)
    {
        immutable ahl = ahead.length;
        enforce(ahl < aheadBuf.length);
        aheadBuf[ahl] = tok;
        ahead = aheadBuf[0 .. ahl+1];
    }

    void error(string msg)
    {
        if (errors) errors.pushError(ParseStage.parse, msg);
    }

    void atRule()
    {
        throw new Exception("DGT-CSS: At-rules are not supported!");
    }

    // §5.4.1
    Rule[] consumeRuleList()
    {
        Rule[] rules;
        while(true) {
            auto tok = getToken();
            switch (tok.tok) {
            case Tok.whitespace:
                break;
            case Tok.eoi:
                return rules;
            case Tok.cdOp:
            case Tok.cdCl:
                if (!toplevel) {
                    putToken(tok);
                    auto r = consumeQualRule();
                    if (r) rules ~= r;
                }
                break;
            case Tok.atKwd:
                atRule();
                break;
            default:
                putToken(tok);
                auto r = consumeQualRule();
                if (r) rules ~= r;
                break;
            }
        }
    }

    // §5.4.3
    Rule consumeQualRule()
    {
        Token[] selectorToks;
        while(true) {
            auto tok = getToken();
            switch(tok.tok) {
            case Tok.eoi:
                error("unexpected token while parsing qualified rule: end of input");
                return null;
            case Tok.braceOp:
                // consumeDeclarationList returns when it sees either eoi or }
                Tok endTok;
                auto decls = consumeDeclarationList(&endTok);
                if (endTok != Tok.braceCl) {
                    error("was expecting <}-token> at end of qualified rule");
                }
                auto sel = parseSelector(selectorToks);
                if (!sel) {
                    error("rule without valid selector");
                    return null;
                }
                auto r = new Rule;
                r.selector = sel;
                r.decls = decls;
                immutable spec = sel.specificity;
                foreach (d; decls) {
                    d.specificity = spec;
                    d.selector = sel;
                }
                return r;
            default:
                selectorToks ~= tok;
                break;
            }
        }
    }

    // Only block consisting of declarations are supported.
    // this is a mix between §5.4.4 and §5.4.7
    Decl[] consumeDeclarationList(Tok* endTok=null)
    {
        Decl[] decls;
        while(true) {
            auto tok = getToken();
            switch(tok.tok) {
            case Tok.braceCl:
            case Tok.eoi:
                if (endTok) *endTok = tok.tok;
                return decls;
            case Tok.whitespace:
            case Tok.semicolon:
                break;
            case Tok.atKwd:
                atRule();
                break;
            case Tok.ident:
                Token[] toks;
                do
                {
                    toks ~= tok;
                    tok = getToken();
                }
                while (tok.tok != Tok.eoi && tok.tok != Tok.braceCl && tok.tok != Tok.semicolon);
                putToken(tok); // for proper ending
                auto d = consumeDeclaration(toks);
                if (d) decls ~= d;
                break;
            default:
                import std.format : format;
                error(format("unexpected token: %s", tok.tok));
                while (tok.tok != Tok.braceCl && tok.tok != Tok.eoi && tok.tok != Tok.semicolon)
                {
                    tok = getToken();
                }
                break;
            }
        }
    }

}

Decl consumeDeclaration(Token[] tokens)
{
    import std.algorithm : filter;
    import std.array : array;
    import std.conv : to;

    // removing all whitespace tokens
    tokens = tokens.filter!(t => t.tok != Tok.whitespace).array;

    if (tokens.length < 3 || tokens[0].tok != Tok.ident) return null;
    if (tokens[1].tok != Tok.colon) return null;

    string property = tokens[0].str;
    Token[] valueToks;
    bool important = false;

    tokens = tokens[2 .. $];

    import std.uni : toLower;
    while (tokens.length) {
        if (tokens.length == 2 && tokens[0].tok == Tok.delim && tokens[0].delimCP == '!' &&
                tokens[1].tok == Tok.ident && tokens[1].str.toLower == "important")
        {
            important = true;
        }
        else {
            valueToks ~= tokens[0];
        }
        tokens = tokens[1 .. $];
    }
    auto d = new Decl;
    d.property = property;
    d.valueTokens = valueToks;
    if (important) d.origin = Origin.important;
    else d.origin = Origin.init;
    return d;
}
