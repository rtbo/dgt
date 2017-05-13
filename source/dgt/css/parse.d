/// CSS parser module
///
/// Standards:
///    this module is a partial implementation of CSS-SYNTAX-3 §5.
///    https://www.w3.org/TR/css-syntax-3
///    The snapshot 2017 was used as reference.
module dgt.css.parse;

import std.exception;
import std.range;

enum ParseStage
{
    token,
    parse,
}

struct CssError
{
    ParseStage stage;
    int lineNum;
    string msg;
}

class CssErrorCollector
{
    void pushError(ParseStage stage, string msg)
    {
        _errors ~= CssError(stage, _lineNum, msg);
    }

    @property int lineNum()
    {
        return _lineNum;
    }

    @property void lineNum(int lineNum)
    {
        _lineNum = lineNum;
    }

    void incrLineNum()
    {
        _lineNum++;
    }

    void decrLineNum()
    {
        _lineNum--;
    }

    @property CssError[] errors()
    {
        return _errors;
    }

    private int _lineNum = 1;
    private CssError[] _errors;
}


package:

import dgt.css.token;

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
    assert(rules[0].selectorToks.length == 1);
    auto selTok = rules[0].selectorToks[0];
    assert(selTok.tok == Tok.ident);
    assert(selTok.sval == "h1");
    assert(rules[0].decls.length == 2);
    auto colDecl = rules[0].decls[0];
    auto taDecl = rules[0].decls[1];
    assert(colDecl.property == "color");
    assert(colDecl.valueToks.length == 1);
    assert(colDecl.valueToks[0].tok == Tok.hash);
    assert(colDecl.valueToks[0].sval == "123456");
    assert(!colDecl.important);
    assert(taDecl.property == "text-align");
    assert(taDecl.valueToks.length == 1);
    assert(taDecl.valueToks[0].tok == Tok.ident);
    assert(taDecl.valueToks[0].sval == "center");
    assert(!taDecl.important);
}

struct ParseRule
{
    Token[] selectorToks;
    ParseDecl[] decls;
}

struct ParseDecl
{
    string property;
    Token[] valueToks;
    bool important;
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
    ParseRule[] consumeRuleList()
    {
        ParseRule[] rules;
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
                    ParseRule r = void;
                    if (consumeQualRule(r)) {
                        rules ~= r;
                    }
                }
                break;
            case Tok.atKwd:
                atRule();
                break;
            default:
                putToken(tok);
                ParseRule r = void;
                if (consumeQualRule(r)) {
                    rules ~= r;
                }
                break;
            }
        }
    }

    // §5.4.3
    bool consumeQualRule(out ParseRule rule)
    {
        while(true) {
            auto tok = getToken();
            switch(tok.tok) {
            case Tok.eoi:
                error("unexpected token while parsing qualified rule: end of input");
                return false;
            case Tok.braceOp:
                // consumeDeclarationList returns when it sees either eoi or
                Tok endTok;
                rule.decls = consumeDeclarationList(&endTok);
                if (endTok != Tok.braceCl) {
                    error("was expecting <}-token> at end of qualified rule");
                }
                return true;
            case Tok.whitespace:
                break;
            default:
                rule.selectorToks ~= tok;
                break;
            }
        }
    }

    // Only block consisting of declarations are supported.
    // this is a mix between §5.4.4 and §5.4.7
    ParseDecl[] consumeDeclarationList(Tok* endTok=null)
    {
        ParseDecl[] decls;
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
                ParseDecl decl = void;
                if (consumeDeclaration(toks, decl)) decls ~= decl;
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

bool consumeDeclaration(Token[] tokens, out ParseDecl decl)
{
    import std.algorithm : filter;
    import std.array : array;
    import std.conv : to;

    // removing all whitespace tokens
    tokens = tokens.filter!(t => t.tok != Tok.whitespace).array;

    if (tokens.length < 3 || tokens[0].tok != Tok.ident) return false;
    decl.property = tokens[0].sval.to!string;
    if (tokens[1].tok != Tok.colon) return false;

    tokens = tokens[2 .. $];

    import std.uni : toLower;
    while (tokens.length) {
        if (tokens.length == 2 && tokens[0].tok == Tok.delim && tokens[0].sval == "!" &&
                tokens[1].tok == Tok.ident && tokens[1].sval.toLower == "important")
        {
            decl.important = true;
        }
        else {
            decl.valueToks ~= tokens[0];
        }
        tokens = tokens[1 .. $];
    }
    return true;
}
