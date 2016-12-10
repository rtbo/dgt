module dgt.enums;


enum Orientation
{
    Horizontal,
    Vertical
}


enum MouseButton
{
    None,

    Left,
    Middle,
    Right
}

enum MouseState
{
    None    = 0,

    Left    = 1,
    Middle  = 1 << 1,
    Right   = 1 << 2
}

enum FocusMethod
{
    Program,
    Mouse,
    Keyboard
}

