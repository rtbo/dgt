/// CSS tokenizer module
///
/// Standards:
///    this module is an implementation of CSS-SYNTAX-3 §3 and §4.
///    https://www.w3.org/TR/css-syntax-3
///    The snapshot 2017 was used as reference.
module dgt.css.token;

import std.exception;
import std.range;
import std.typecons;
import std.uni : isSurrogate, toLower;
import std.utf;


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


auto makeTokenInput(Input)(Input input, CssErrorCollector errors=null)
if (isInputRange!Input && is(ElementType!Input == dchar))
{
    return TokenInput!Input(input, errors);
}

void popSpaces(TokRange)(ref TokRange tokens)
if (isInputRange!TokRange && is(ElementType!TokRange == Token))
{
    while (!tokens.empty && tokens.front.tok == Tok.whitespace) {
        tokens.popFront();
    }
}

// self contained token
struct Token
{
    Tok tok;

    union {
        dchar delimCP;
        struct {
            string str;
            Flag!"id" id;
        }
        struct {
            string numStr;
            double num;
            Flag!"integer" integer;
            string unit;
        }
        struct {
            dchar startCP;
            dchar endCP;
        }
    }

    this (in Tok tok)
    {
        this.tok = tok;
    }

    this (in Tok tok, in string str)
    {
        assert(tok == Tok.ident || tok == Tok.func || tok == Tok.atKwd || tok == Tok.str || tok == Tok.url);
        this.tok = tok;
        this.str = str;
    }

    this (in Tok tok, in string str, in Flag!"id" id = No.id)
    {
        assert(tok == Tok.hash);
        this.tok = tok;
        this.str = str;
        this.id = id;
    }

    this (in Tok tok, in dchar cp)
    {
        assert(tok == Tok.delim);
        this.tok = tok;
        this.delimCP = cp;
    }

    this (in Tok tok, in dchar startCP, in dchar endCP)
    {
        assert(tok == Tok.uniRange);
        this.tok = tok;
        this.startCP = startCP;
        this.endCP = endCP;
    }

    this (in Tok tok, in string numStr, in double num, in Flag!"integer" integer)
    {
        assert(tok == Tok.number || tok == Tok.percentage);
        this.tok = tok;
        this.numStr = numStr;
        this.num = num;
        this.integer = integer;
    }

    this (in Tok tok, in string numStr, in double num,
            in Flag!"integer" integer, in string unit)
    {
        this.tok = tok;
        this.numStr = numStr;
        this.num = num;
        this.integer = integer;
        this.unit = unit;
    }
}

enum Tok
{
    none,
    eoi,
    ident,
    func,
    atKwd,
    hash,
    str,
    badStr,
    url,
    badUrl,
    delim,
    number,
    percentage,
    dimension,
    uniRange,
    inclMatch,
    dashMatch,
    prefixMatch,
    suffixMatch,
    substrMatch,
    column,
    whitespace,
    cdOp,
    cdCl,
    colon,
    semicolon,
    comma,
    brackOp,
    brackCl,
    parenOp,
    parenCl,
    braceOp,
    braceCl,
}

private:

unittest
{
    string test = `
        h1 {
            color: #123456;
            text-align: center;
        }
    `;
    immutable Tok[] expected = [  // with whitespaces trimmed
        Tok.ident, Tok.braceOp,
            Tok.ident, Tok.colon, Tok.hash, Tok.semicolon,
            Tok.ident, Tok.colon, Tok.ident, Tok.semicolon,
        Tok.braceCl
    ];

    auto tokInput = makeTokenInput(byDchar(test));
    import std.algorithm : equal, filter, map;
    assert(equal(expected, tokInput.map!(t => t.tok).filter!(t => t != Tok.whitespace)));
}

// §4.2 - definitions

enum dchar endOfInput = cast(dchar)0xffff_ffff;
enum dchar lineFeed = '\u000A';
enum dchar nullCP = '\u0000';
enum dchar replacementCP = '\uFFFD';
enum dchar lastCP = '\U0010FFFF';

@property bool isDigit(in dchar c)
{
    return c >= '\u0030' && c <= '\u0039';
}

@property bool isHexDigit(in dchar c)
{
    return c.isDigit ||
            (c >= '\u0041' && c <= '\u0046') ||
            (c >= '\u0061' && c <= '\u0066');
}

@property bool isUCaseLetter(in dchar c)
{
    return (c >= '\u0041' && c <= '\u005A');
}

@property bool isLCaseLetter(in dchar c)
{
    return (c >= '\u0061' && c <= '\u007A');
}

@property bool isLetter(in dchar c)
{
    return c.isUCaseLetter || c.isLCaseLetter;
}

@property bool isNonASCII(in dchar c)
{
    return c >= '\u0080' && c <= lastCP;
}

@property bool isNameStart(in dchar c)
{
    return c.isLetter || c.isNonASCII || c == '\u005F';
}

@property bool isName(in dchar c)
{
    return c.isNameStart || c.isDigit || c == '\u002D';
}

@property bool isNotPrintable(in dchar c)
{
    return (c >= '\u0000' && c <= '\u0008') ||
            c == '\u000B' ||
           (c >= '\u000E' && c <= '\u001F') ||
            c == '\u007F';
}

@property bool isNewLine(in dchar c)
{
    return c == lineFeed;
}

@property bool isWhitespace(in dchar c)
{
    return c.isNewLine || c == '\u0020' || c == '\u0009';
}


struct TokenInput(DCharRange)
if (isForwardRange!DCharRange && is(ElementType!DCharRange == dchar))
{
    this(DCharRange input, CssErrorCollector errors)
    {
        this.errors = errors;
        pp = Preprocessor(input);
        frontTok = consumeToken();
    }

    @property bool empty()
    {
        return frontTok.tok == Tok.eoi;
    }

    @property Token front()
    {
        return frontTok;
    }

    void popFront()
    {
        frontTok = consumeToken();
    }

private:

    CssErrorCollector errors;
    Preprocessor pp;
    Token frontTok;


    static struct Preprocessor
    {
        DCharRange input;
        dchar[8] aheadBuf;
        size_t aheadLen;

        this(DCharRange input)
        {
            this.input = input;
        }

        dchar getChar()
        {
            dchar c = void;
            if (aheadLen) {
                c = aheadBuf[--aheadLen];
            }
            else if (!input.empty) {
                c = input.front;
                input.popFront();
                // §3.3 - preprocessing
                if (c == '\u000D' || c == '\u000C') { // CR or FF
                    c = lineFeed;
                    if (!input.empty && input.save.front == lineFeed) {
                        input.popFront();
                    }
                }
                else if (c == nullCP) {
                    c = replacementCP;
                }
            }
            else {
                c = endOfInput;
            }
            return c;
        }

        void putChar(in dchar c)
        {
            enforce(aheadLen < aheadBuf.length, "CSS parser internal error: reached the maximum look ahead number");
            aheadBuf[aheadLen++] = c;
        }
    }

    void error(string msg)
    {
        if (errors) errors.pushError(ParseStage.token, msg);
    }

    dchar getChar()
    {
        immutable dchar c = pp.getChar();
        if (c.isNewLine && errors) errors.incrLineNum();
        return c;
    }

    void putChar(Chars...)(Chars chars)
    if (Chars.length >= 1)
    {
        import std.traits : Unqual;
        foreach(c; chars) {
            static assert(is(Unqual!(typeof(c)) == dchar));
            pp.putChar(c);
            if (c.isNewLine && errors) errors.decrLineNum();
        }
    }

    dchar peekChar()
    {
        immutable c = pp.getChar();
        pp.putChar(c);
        return c;
    }

    // §4.3.1 - consume a token
    Token consumeToken()
    {
        immutable c = getChar();
        if (c.isWhitespace) {
            dchar c1 = void;
            do {
                c1 = getChar();
            }
            while (c1.isWhitespace);
            putChar(c1);
            return Token(Tok.whitespace);
        }
        else if (c == '\u0022' || c == '\u0027') { // " or '
            return consumeStringToken(c);
        }
        else if (c == '\u0023') { // #
            immutable c1 = getChar();
            immutable c2 = getChar();
            if (c1.isName || isValidEscape(c1, c2)) {
                immutable c3 = getChar();
                Flag!"id" id = isIdentStart(c1, c2, c3) ? Yes.id : No.id;
                putChar(c3, c2, c1);
                return Token(Tok.hash, consumeName(), id);
            }
            else {
                putChar(c2, c1);
            }
        }
        else if (c == '\u0024' ||           // $
                 c == '\u002A' ||           // *
                 c == '\u005E' ||           // ^
                 c == '\u007C' ||           // |
                 c == '\u007E') {           // ~
            immutable c1 = getChar();
            if (c1 == '\u003D') {           // =
                switch(c) {
                case '\u0024':
                    return Token(Tok.suffixMatch);
                case '\u002A':
                    return Token(Tok.substrMatch);
                case '\u005E':
                    return Token(Tok.prefixMatch);
                case '\u007C':
                    return Token(Tok.dashMatch);
                case '\u007E':
                    return Token(Tok.inclMatch);
                default:
                    assert(false);
                }
            }
            else if (c == '\u007C' && c1 == '\u007C') {
                return Token(Tok.column);
            }
            else {
                putChar(c1);
            }
        }
        else if (c == '\u0028') {               // (
            return Token(Tok.parenOp);
        }
        else if (c == '\u0029') {               // )
            return Token(Tok.parenCl);
        }
        else if (c == '\u002B') {               // +
            immutable c2 = getChar();
            immutable c3 = getChar();
            putChar(c3, c2);
            if (isNumberStart(c, c2, c3)) {
                putChar(c);
                return consumeNumberToken();
            }
        }
        else if (c == '\u002D') {               // -
            immutable c2 = getChar();
            immutable c3 = getChar();
            putChar(c3, c2);
            if (isNumberStart(c, c2, c3)) {
                putChar(c);
                return consumeNumberToken();
            }
            else if (isIdentStart(c, c2, c3)) {
                putChar(c);
                return consumeIndentLikeToken();
            }
            else if (c == '\u002D' && c2 == '\u003E') {    // ->
                getChar(); // reconsume c2
                return Token(Tok.cdCl);
            }
        }
        else if (c == '\u002E') {       // .
            immutable c2 = getChar();
            immutable c3 = getChar();
            putChar(c3, c2);
            if (isNumberStart(c, c2, c3)) {
                putChar(c);
                return consumeNumberToken();
            }
        }
        else if (c == '\u002F') {       // /
            auto c2 = getChar();
            if (c2 == '\u002A') {       // *
                // eat comment
                auto c1 = getChar();
                c2 = getChar();
                while (c1 != endOfInput || (c1 == '\u002A' && c2 == '\u002F')) {
                    c1 = c2;
                    c2 = getChar();
                }
                return consumeToken();
            }
            else {
                putChar(c2);
            }
        }
        else if (c == '\u002C') {
            return Token(Tok.comma);
        }
        else if (c == '\u003A') {
            return Token(Tok.colon);
        }
        else if (c == '\u003B') {
            return Token(Tok.semicolon);
        }
        else if (c == '\u003C') {   // <
            immutable c1 = getChar();
            immutable c2 = getChar();
            immutable c3 = getChar();
            if ([c1, c2, c3] == "!--"d) {
                return Token(Tok.cdOp);
            }
            else {
                putChar(c3, c2, c1);
            }
        }
        else if (c == '\u0040') {   // @
            immutable c1 = getChar();
            immutable c2 = getChar();
            immutable c3 = getChar();
            putChar(c3, c2, c1);
            if (isIdentStart(c1, c2, c3)) {
                auto name = consumeName();
                return Token(Tok.atKwd, name);
            }
        }
        else if (c == '\u005B') {   // [
            return Token(Tok.brackOp);
        }
        else if (c == '\u005C') {   // \
            immutable c2 = peekChar();
            if (isValidEscape(c, c2)) {
                putChar(c);
                return consumeIndentLikeToken();
            }
            // TODO: report error
        }
        else if (c == '\u005D') {   // [
            return Token(Tok.brackCl);
        }
        else if (c == '\u007B') {
            return Token(Tok.braceOp);
        }
        else if (c == '\u007D') {
            return Token(Tok.braceCl);
        }
        else if (c.isDigit) {
            putChar(c);
            return consumeNumberToken();
        }
        else if (c == '\u0075' || c == '\u0055') {  // U or u
            immutable c1 = getChar();
            immutable c2 = peekChar();
            if (c1 == '\u002B' && (c2 == '\u003F' || c2.isHexDigit)) { // +? or +x
                return consumeUnicodeRangeToken();
            }
            else {
                putChar(c1, c);
                return consumeIndentLikeToken();
            }
        }
        else if (c.isNameStart) {
            putChar(c);
            return consumeIndentLikeToken();
        }
        else if (c == endOfInput) {
            return Token(Tok.eoi);
        }

        return Token(Tok.delim, c);
    }

    // $4.3.2
    Token consumeNumberToken()
    {
        auto num = consumeNumber();
        auto c1 = getChar();
        auto c2 = getChar();
        auto c3 = getChar();
        if (isIdentStart(c1, c2, c3)) {
            putChar(c3, c2, c1);
            immutable unit = consumeName();
            return Token(Tok.dimension, num.expand, unit);
        }
        else if (c1 == '\u0025') {      // %
            putChar(c3, c2);
            return Token(Tok.percentage, num.expand);
        }
        else {
            putChar(c3, c2, c1);
            return Token(Tok.number, num.expand);
        }
    }

    // §4.3.3
    Token consumeIndentLikeToken()
    {
        immutable name = consumeName();
        immutable c = getChar();
        if (name.toLower == "url" && c == '\u0028') {      // (
            return consumeUrlToken();
        }
        else if (c == '\u0028') {                           // (
            return Token(Tok.func, name);
        }
        else {
            putChar(c);
            return Token(Tok.ident, name);
        }
    }

    // §4.3.4
    Token consumeStringToken(in dchar endCP)
    {
        string val;
        dchar c = void;
        do {
            c = getChar();
            if (c.isNewLine) {
                return Token(Tok.badStr, val);
            }
            else if (c == '\u005C') { // '\'
                // escape
                immutable ec = getChar();
                if (!ec.isNewLine) {
                    putChar(ec);
                    val ~= consumeEscape();
                }
                // else escaped new line is consumed
            }
            else {
                val ~= c;
            }
        }
        while (c != endCP && c != endOfInput);

        return Token(Tok.str, val);
    }

    // §4.3.5
    Token consumeUrlToken()
    {
        // 1
        auto tok = Token(Tok.url);
        // 2
        auto c = getChar();
        while (c.isWhitespace) {
            c = getChar();
        }
        // 3
        if (c == endOfInput) {
            return tok;
        }
        if (c == '\u0022' || c == '\u0027') {       // " or '
            auto strTok = consumeStringToken(c);
            if (strTok.tok == Tok.badStr) {
                consumeBadUrlRemnants();
                return Token(Tok.badUrl);
            }
            tok.str = strTok.str;
            c = getChar();
            while (c.isWhitespace) {
                c = getChar();
            }
            if (c == '\u0029' || c == endOfInput) {     // )
                return tok;
            }
            else {
                consumeBadUrlRemnants();
                return Token(Tok.badUrl);
            }
        }
        while (true) {
            if (c == '\u0029' || c == endOfInput) {     // )
                break;
            }
            while (c.isWhitespace) {
                c = getChar();
            }
            if (c == '\u0022' || c == '\u0027' || c == '\u0028' || c.isNotPrintable) {  // " ' (
                consumeBadUrlRemnants();
                return Token(Tok.badUrl);
            }
            else if (c == '\u005C') {        // \
                immutable c2 = getChar();
                putChar(c2);
                if (isValidEscape(c, c2)) {
                    tok.str ~= consumeEscape();
                }
                else {
                    consumeBadUrlRemnants();
                    return Token(Tok.badUrl);
                }
            }
            else {
                tok.str ~= c;
            }

            c = getChar();
        }
        return tok;
    }

    // §4.3.6 - u+ already consumed
    Token consumeUnicodeRangeToken()
    {
        import std.conv : to;
        bool hadQm;
        dchar[6] buf;
        size_t len;

        auto c = getChar();
        while (c.isHexDigit && len < 6) {
            buf[len++] = c;
            c = getChar();
        }
        while (c == '\u003F' && len < 6) {
            buf[len++] = c;
            c = getChar();
            hadQm = true;
        }
        putChar(c);

        if (hadQm) {
            dchar[6] bufEnd = buf;
            foreach(i; 0..len) {
                if (buf[i] == '\u003F') {   // ?
                    buf[i] = '\u0030';      // 0
                    bufEnd[i] = '\u0046';   // F
                }
            }
            immutable start = cast(dchar)(buf[0..len].to!uint(16));
            immutable end = cast(dchar)(bufEnd[0..len].to!uint(16));
            return Token(Tok.uniRange, start, end);
        }

        immutable start = cast(dchar)(buf[0..len].to!uint(16));

        c = getChar();
        immutable c2 = getChar();
        if (c == '\u002D' && c2.isHexDigit) { // -
            len = 0;
            c = c2;
            while (c.isHexDigit && len < 6) {
                buf[len++] = c;
                c = getChar();
            }
            putChar(c);
            immutable end = cast(dchar)(buf[0..len].to!uint(16));
            return Token(Tok.uniRange, start, end);
        }
        else {
            putChar(c2, c);
        }

        return Token(Tok.uniRange, start, start);
    }

    // §4.3.7 - '\' already consumed
    dchar consumeEscape()
    {
        dchar consumeHexStr(dchar c)
        {
            dchar[6] hexStr;
            size_t len=0;
            while (c.isHexDigit && len < 6) {
                hexStr[len++] = c;
                c = getChar();
            }
            if (!c.isWhitespace) {
                putChar(c);
            }
            import std.conv : to;
            c = cast(dchar)(hexStr[0 .. len].to!uint(16));
            if (c == nullCP || c.isSurrogate || c > lastCP) {
                c = replacementCP;
            }
            return c;
        }

        auto c = getChar();
        if (c.isHexDigit) {
            return consumeHexStr(c);
        }
        else if (c == endOfInput) {
            return replacementCP;
        }
        else return c;
    }

    // §4.3.8
    bool isValidEscape(in dchar c1, in dchar c2)
    {
        return c1 == '\u005D' /+ '\' +/ && !c2.isNewLine;
    }

    // §4.3.9
    bool isIdentStart(in dchar c1, in dchar c2, in dchar c3)
    {
        if (c1 == '\u002D') {
            return (c2.isNameStart || isValidEscape(c2, c3));
        }
        else if (c1.isNameStart) {
            return true;
        }
        else {
            return isValidEscape(c1, c2);
        }
    }

    // §4.3.10
    bool isNumberStart(in dchar c1, in dchar c2, in dchar c3)
    {
        if (c1 == '\u002B' || c1 == '\u002D') {                     // sign
            return c2.isDigit || (c3.isDigit && c2 == '\u002E');    // .
        }
        else if (c1 == '\u002E') {                                  // .
            return c2.isDigit;
        }
        else {
            return c1.isDigit;
        }
    }

    // §4.3.11
    string consumeName()
    {
        string name;
        while (true) {
            immutable c1 = getChar();
            immutable c2 = peekChar();
            if (c1.isName) {
                name ~= c1;
            }
            else if (isValidEscape(c1, c2)) {
                name ~= consumeEscape();
            }
            else {
                putChar(c1);
                break;
            }
        }
        return name;
    }

    // $4.3.12
    Tuple!(string, double, Flag!"integer") consumeNumber()
    {
        import std.conv : to;
        // 1 - init
        string repr;
        Flag!"integer" flag = Yes.integer;
        // 2 - sign
        auto c1 = getChar();
        if (c1 == '\u002B' || c1 == '\u002D') {       // + or -
            repr ~= c1;
            c1 = getChar();
        }
        // 3 - numeric part
        while(c1.isDigit) {
            repr ~= c1;
            c1 = getChar();
        }
        // 4 - decimal part
        auto c2 = getChar();
        if (c1 == '\u002E' /+ . +/ && c2.isDigit()) {
            repr ~= c1;
            repr ~= c2;
            flag = No.integer;
            c1 = getChar();
            while (c1.isDigit) {
                repr ~= c1;
                c1 = getChar();
            }
            c2 = getChar();
        }
        // 5 - exponent
        auto c3 = getChar();
        if ((c1 == '\u0045' || c1 == '\u0065') && (c2.isDigit ||        // E or e
                ((c2 == '\u002B' || c2 == '\u002D') && c3.isDigit))) {  // + or -
            // e(+-)123 or E(+-)123
            repr ~= c1;
            repr ~= c2;
            flag = No.integer;
            c1 = c3.isDigit ? c3 : getChar();
            while (c1.isDigit) {
                repr ~= c1;
                c1 = getChar();
            }
        }
        else {
            putChar(c3, c2);
        }
        putChar(c1);
        // 6 - conversion
        immutable nval = repr.to!double();
        // 7 - result
        return typeof(return)(repr, nval, flag);
    }

    // §4.3.14
    void consumeBadUrlRemnants()
    {
        while (true) {
            immutable c1 = getChar();
            immutable c2 = getChar();
            putChar(c2);
            if (c1 == '\u0029' || c1 == endOfInput) {   // )
                return;
            }
            else if (!isValidEscape(c1, c2)) {
                consumeEscape();
            }
        }
    }
}
