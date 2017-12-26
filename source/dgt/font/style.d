module dgt.font.style;

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
    italic,
    oblique,
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
    this(in FontWeight weight, in FontSlant slant,
         in FontWidth width=FontWidth.normal) {
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

    @property string toString() const {
        import std.format : format;
        return format("FontStyle(FontWeight.%s, FontSlant.%s, FontWidth.%s)",
            weight, slant, width
        );
    }

    // algorithm from Skia
    package int css3MatchingScore(in FontStyle other) const pure {
        import std.conv : to;
        int score;
        if (other._width <= FontWidth.normal.to!int) {
            if (_width <= other._width) {
                score += 10 - other._width + _width;
            }
            else {
                score += 10 - _width;
            }
        }
        else {
            if (_width > other._width) {
                score += 10 + other._width - _width;
            }
            else {
                score += 10 + _width;
            }
        }
        score <<= 8;

        const int[3][3] slantScore = [
            //  normal,     italic,     oblique
            [   3,          1,          2],     // normal
            [   1,          3,          2],     // italic
            [   1,          2,          3]      // oblique
        ];
        assert(other._slant >= 0 && other._slant < 3);
        assert(_slant >= 0 && _slant < 3);
        score += slantScore[other._slant][_slant];
        score <<= 8;

        if (other._weight == _weight) {
            score += 1000;
        }
        else if (other._weight <= 500) {
            if (other._weight >= 400 && other._weight < 450) {
                if (_weight >= 450 && _weight <= 500) {
                    score += 500;
                }
            }
            if (_weight <= other._weight) {
                score += 1000 - other._weight + _weight;
            }
            else {
                score += 1000 - _weight;
            }
        }
        else {
            if (_weight > other._weight) {
                score += 1000 + other._weight - _weight;
            } else {
                score += _weight;
            }
        }

        return score;
    }

    private ushort _weight  = 400;
    private ubyte _slant    = 0;
    private ubyte _width    = 5;
}
