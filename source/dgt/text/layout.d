module dgt.text.layout;

import dgt.text.fontcache;
import dgt.text.font;
import dgt.core.resource;
import dgt.image;

import std.exception;

enum TextFormat
{
    plain,
    html,
}

/// The layout is divided in different items, for example because a word
/// is in italic or in another color, or due to bidirectional text (unimplemented).
/// Each item is passed to the text shaper independently.
struct TextItem
{
    string text;
    Rc!Font font;
    ImageFormat renderFormat;
    uint argbColor;
}

/// A single line text layout
class TextLayout : RefCounted
{
    mixin(rcCode);
    /// Builds a layout
    this(string text, TextFormat format, FontRequest font)
    {
        _text = text;
        _format = format;
        _matchedFonts = FontCache.instance.requestFont(font);
        enforce(_matchedFonts.length, "Text layout could not match any font");
    }

    override void dispose()
    {
        reinit(_items);
    }

    /// This is the operation of splitting the text into items.
    void layout()
    {
        _items = [TextItem(
            _text, makeRc!Font(_matchedFonts[0]), ImageFormat.a8, 0,
        )];
    }

    TextItem[] items()
    {
        return _items;
    }

    private string _text;
    private TextFormat _format;
    private FontResult[] _matchedFonts;
    private TextItem[] _items;
}
