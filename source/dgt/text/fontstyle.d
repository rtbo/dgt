module dgt.text.fontstyle;

/// Font weight as defined by the CSS specification.
/// An integer is typically expected for the weight. Either a value of this enum
/// or a number between 100 and 900 can be provided in place.
enum FontWeight : int
{
    normal      = 400,
    invisible   = 0,
    thin        = 100,
    extraLight  = 200,
    light       = 300,
    medium      = 500,
    semiBold    = 600,
    bold        = 700,
    large       = 800,
    extraLarge  = 900,
}

enum FontSlant {
    normal,
    oblique,
    italic,
}

enum FontWidth {
    normal           = 5,
    ultraCondensed   = 1,
    extraCondensed   = 2,
    condensed        = 3,
    semiCondensed    = 4,
    semiExpanded     = 6,
    expanded         = 7,
    extraExpanded    = 8,
    ultraExpanded    = 9,
}

struct FontStyle
{
    this(FontWeight weight, FontSlant slant, FontWidth width) {
        _weight = cast(ushort)weight;
        _slant = cast(ubyte)slant;
        _width = cast(ubyte)width;
    }

    @property FontWeight weight() const {
        return cast(FontWeight)_weight;
    }

    @property FontSlant slant() const {
        return cast(FontSlant)_slant;
    }

    @property FontWidth width() const {
        return cast(FontWidth)_width;
    }

    private ushort _weight  = 400;
    private ubyte _slant    = 0;
    private ubyte _width    = 5;
}
