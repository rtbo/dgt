/// Global enumerations.
module dgt.enums;

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

enum MouseButton
{
    none,

    left,
    middle,
    right
}

enum MouseState
{
    none = 0,

    left = 1,
    middle = 1 << 1,
    right = 1 << 2
}

enum FocusMethod
{
    program,
    mouse,
    keyboard
}
