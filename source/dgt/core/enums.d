/// Global enumerations.
module dgt.core.enums;

/// horizontal or vertical orientation
enum Orientation
{
    horizontal,
    vertical
}

/// ditto
@property bool isHorizontal(in Orientation orientation) pure
{
    return orientation == Orientation.horizontal;
}

/// ditto
@property bool isVertical(in Orientation orientation) pure
{
    return orientation == Orientation.vertical;
}

/// ditto
@property Orientation other(in Orientation orientation) pure
{
    return orientation.isHorizontal ? Orientation.vertical : Orientation.horizontal;
}


enum Alignment
{
    none        = 0x00,

    left        = 0x01,
    right       = 0x02,
    centerH     = 0x04,

    top         = 0x10,
    bottom      = 0x20,
    centerV     = 0x40,

    center      = centerH | centerV,
}

enum FocusMethod
{
    program,
    mouse,
    keyboard
}
