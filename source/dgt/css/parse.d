/// CSS parser module
///
/// Standards:
///    this module is an implementation of CSS-SYNTAX-3 §5.
///    https://www.w3.org/TR/css-syntax-3
///    The snapshot 2017 was used as reference.
module dgt.css.parse;

import dgt.css.token;



class CSSAST
{
    enum Type {
        rule,
        selector,
        block,
        declaration,
    }

    private Type _type;

    this(Type type) {
        _type = type;
    }

    @property Type type()
    {
        return _type;
    }

    @property RuleAST asRule()
    {
        assert(_type == Type.rule);
        return cast(RuleAST)this;
    }

    @property SelectorAST asSelector()
    {
        assert(_type == Type.selector);
        return cast(SelectorAST)this;
    }

    @property BlockAST asBlock()
    {
        assert(_type == Type.block);
        return cast(BlockAST)this;
    }

    @property DeclarationAST asDeclaration()
    {
        assert(_type == Type.declaration);
        return cast(DeclarationAST)this;
    }
}

class RuleAST : CSSAST
{
    this(SelectorAST selector, BlockAST block)
    {
        super(Type.rule);
        _selector = selector;
        _block = block;
    }

    @property SelectorAST selector() { return _selector; }
    @property BlockAST block() { return _block; }

    private SelectorAST _selector;
    private BlockAST _block;
}

class SelectorAST : CSSAST
{
    this(Token[] tokens)
    {
        super(Type.selector);
        _tokens = tokens;
    }

    @property Token[] tokens() { return _tokens; }

    private Token[] _tokens;
}

class BlockAST : CSSAST
{
    this(DeclarationAST[] declarations)
    {
        super(Type.block);
        _declarations = declarations;
    }

    @property DeclarationAST[] declarations() { return _declarations; }

    private DeclarationAST[] _declarations;
}

class DeclarationAST : CSSAST
{
    this(string property, string value, string priority)
    {
        super(Type.declaration);
        _property = property;
        _value = value;
        _priority = priority;
    }

    @property string property() { return _property; }
    @property string value() { return _value; }
    @property string priority() { return _priority; }

    private string _property;
    private string _value;
    private string _priority;
}

private:

struct CSSParser(Tokenizer)
{
    Tokenizer tokenInput;

    this(Tokenizer tokenInput)
    {
        this.tokenInput = tokenInput;
    }
}