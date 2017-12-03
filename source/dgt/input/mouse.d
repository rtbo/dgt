module dgt.input.mouse;

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
