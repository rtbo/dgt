module dgt.platform.win32.keymap;

version (Windows):

import key = dgt.keys;
import core.sys.windows.windows;


static key.Sym getKeysym(in WPARAM vkey)
{
    assert(cast(ubyte)vkey == vkey);
    immutable sym = keysymTable[vkey];
    return (sym == key.Sym.none) ?
        cast(key.Sym)vkey :
        sym;
}

static key.Code getKeycode(in ubyte scancode)
{
    return keycodeTable[scancode];
}


private
{

    immutable key.Sym[256] keysymTable;
    immutable key.Code[256] keycodeTable;

    shared static this()
    {

        keycodeTable = [
            // 0x00     0
            key.Code.unknown,
            key.Code.escape,
            key.Code.d1,
            key.Code.d2,
            key.Code.d3,
            key.Code.d4,
            key.Code.d5,
            key.Code.d6,
            key.Code.d7,
            key.Code.d8,
            key.Code.d9,
            key.Code.d0,
            key.Code.minus,
            key.Code.equals,
            key.Code.backspace,
            key.Code.tab,
            // 0x10     16
            key.Code.q,
            key.Code.w,
            key.Code.e,
            key.Code.r,
            key.Code.t,
            key.Code.y,
            key.Code.u,
            key.Code.i,
            key.Code.o,
            key.Code.p,
            key.Code.leftBracket,
            key.Code.rightBracket,
            key.Code.enter,
            key.Code.leftCtrl,
            key.Code.a,
            key.Code.s,
            // 0x20     32
            key.Code.d,
            key.Code.f,
            key.Code.g,
            key.Code.h,
            key.Code.j,
            key.Code.k,
            key.Code.l,
            key.Code.semicolon,
            key.Code.quote,
            key.Code.grave,
            key.Code.leftShift,
            key.Code.uK_Hash,
            key.Code.z,
            key.Code.x,
            key.Code.c,
            key.Code.v,
            // 0x30     48
            key.Code.b,
            key.Code.n,
            key.Code.m,
            key.Code.comma,
            key.Code.period,
            key.Code.slash,
            key.Code.rightShift,
            key.Code.printScreen,
            key.Code.leftAlt,
            key.Code.space,
            key.Code.capsLock,
            key.Code.f1,
            key.Code.f2,
            key.Code.f3,
            key.Code.f4,
            key.Code.f5,
            // 0x40     64
            key.Code.f6,
            key.Code.f7,
            key.Code.f8,
            key.Code.f9,
            key.Code.f10,
            key.Code.kp_NumLock,
            key.Code.scrollLock,
            key.Code.home,
            key.Code.up,
            key.Code.pageUp,
            key.Code.kp_Subtract,
            key.Code.left,
            key.Code.kp_5,
            key.Code.right,
            key.Code.kp_Add,
            key.Code.end,
            // 0x50     80
            key.Code.down,
            key.Code.pageDown,
            key.Code.insert,
            key.Code.delete_,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.kp_Add,
            key.Code.f11,
            key.Code.f12,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0x60     96
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown, // line feed
            key.Code.unknown,
            key.Code.unknown,
            // 0x70     112
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0x80     128
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0x90     144
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0xA0     160
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0xB0     176
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0xC0     192
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0xD0     208
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0xE0     224
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            // 0xF0     240
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown
        ];

        // a little help from Qt for that one
        keysymTable = [
                                            // Dec |  Hex | Windows Virtual key
            key.Sym.unknown,                //   0   0x00
            key.Sym.unknown,                //   1   0x01   VK_LBUTTON          | Left mouse button
            key.Sym.unknown,                //   2   0x02   VK_RBUTTON          | Right mouse button
            key.Sym.cancel,                 //   3   0x03   VK_CANCEL           | Control-Break processing
            key.Sym.unknown,                //   4   0x04   VK_MBUTTON          | Middle mouse button
            key.Sym.unknown,                //   5   0x05   VK_XBUTTON1         | X1 mouse button
            key.Sym.unknown,                //   6   0x06   VK_XBUTTON2         | X2 mouse button
            key.Sym.unknown,                //   7   0x07   -- unassigned --
            key.Sym.backspace,              //   8   0x08   VK_BACK             | BackSpace key
            key.Sym.tab,                    //   9   0x09   VK_TAB              | Tab key
            key.Sym.unknown,                //  10   0x0A   -- reserved --
            key.Sym.unknown,                //  11   0x0B   -- reserved --
            key.Sym.clear,                  //  12   0x0C   VK_CLEAR            | Clear key
            key.Sym.return_,                //  13   0x0D   VK_RETURN           | Enter key
            key.Sym.unknown,                //  14   0x0E   -- unassigned --
            key.Sym.unknown,                //  15   0x0F   -- unassigned --
            key.Sym.shift,                  //  16   0x10   VK_SHIFT            | Shift key
            key.Sym.ctrl,                   //  17   0x11   VK_CONTROL          | Ctrl key
            key.Sym.alt,                    //  18   0x12   VK_MENU             | Alt key
            key.Sym.pause,                  //  19   0x13   VK_PAUSE            | Pause key
            key.Sym.capsLock,               //  20   0x14   VK_CAPITAL          | Caps-Lock
            key.Sym.unknown,                //  21   0x15   VK_KANA / VK_HANGUL | IME Kana or Hangul mode
            key.Sym.unknown,                //  22   0x16   -- unassigned --
            key.Sym.junja,                  //  23   0x17   VK_JUNJA            | IME Junja mode
            key.Sym.final_,                 //  24   0x18   VK_FINAL            | IME final mode
            key.Sym.hanja,                  //  25   0x19   VK_HANJA / VK_KANJI | IME Hanja or Kanji mode
            key.Sym.unknown,                //  26   0x1A   -- unassigned --
            key.Sym.escape,                 //  27   0x1B   VK_ESCAPE           | Esc key
            key.Sym.unknown,                //  28   0x1C   VK_CONVERT          | IME convert
            key.Sym.unknown,                //  29   0x1D   VK_NONCONVERT       | IME non-convert
            key.Sym.unknown,                //  30   0x1E   VK_ACCEPT           | IME accept
            key.Sym.modeSwitch,             //  31   0x1F   VK_MODECHANGE       | IME mode change request
            key.Sym.space,                  //  32   0x20   VK_SPACE            | Spacebar
            key.Sym.pageUp,                 //  33   0x21   VK_PRIOR            | Page Up key
            key.Sym.pageDown,               //  34   0x22   VK_NEXT             | Page Down key
            key.Sym.end,                    //  35   0x23   VK_END              | End key
            key.Sym.home,                   //  36   0x24   VK_HOME             | Home key
            key.Sym.left,                   //  37   0x25   VK_LEFT             | Left arrow key
            key.Sym.up,                     //  38   0x26   VK_UP               | Up arrow key
            key.Sym.right,                  //  39   0x27   VK_RIGHT            | Right arrow key
            key.Sym.down,                   //  40   0x28   VK_DOWN             | Down arrow key
            key.Sym.select,                 //  41   0x29   VK_SELECT           | Select key
            key.Sym.printer,                //  42   0x2A   VK_PRINT            | Print key
            key.Sym.execute,                //  43   0x2B   VK_EXECUTE          | Execute key
            key.Sym.print,                  //  44   0x2C   VK_SNAPSHOT         | Print Screen key
            key.Sym.insert,                 //  45   0x2D   VK_INSERT           | Ins key
            key.Sym.delete_,                //  46   0x2E   VK_DELETE           | Del key
            key.Sym.help,                   //  47   0x2F   VK_HELP             | Help key
            key.Sym.none,                   //  48   0x30   (VK_0)              | 0 key
            key.Sym.none,                   //  49   0x31   (VK_1)              | 1 key
            key.Sym.none,                   //  50   0x32   (VK_2)              | 2 key
            key.Sym.none,                   //  51   0x33   (VK_3)              | 3 key
            key.Sym.none,                   //  52   0x34   (VK_4)              | 4 key
            key.Sym.none,                   //  53   0x35   (VK_5)              | 5 key
            key.Sym.none,                   //  54   0x36   (VK_6)              | 6 key
            key.Sym.none,                   //  55   0x37   (VK_7)              | 7 key
            key.Sym.none,                   //  56   0x38   (VK_8)              | 8 key
            key.Sym.none,                   //  57   0x39   (VK_9)              | 9 key
            key.Sym.unknown,                //  58   0x3A   -- unassigned --
            key.Sym.unknown,                //  59   0x3B   -- unassigned --
            key.Sym.unknown,                //  60   0x3C   -- unassigned --
            key.Sym.unknown,                //  61   0x3D   -- unassigned --
            key.Sym.unknown,                //  62   0x3E   -- unassigned --
            key.Sym.unknown,                //  63   0x3F   -- unassigned --
            key.Sym.unknown,                //  64   0x40   -- unassigned --
            key.Sym.none,                   //  65   0x41   (VK_A)              | A key
            key.Sym.none,                   //  66   0x42   (VK_B)              | B key
            key.Sym.none,                   //  67   0x43   (VK_C)              | C key
            key.Sym.none,                   //  68   0x44   (VK_D)              | D key
            key.Sym.none,                   //  69   0x45   (VK_E)              | E key
            key.Sym.none,                   //  70   0x46   (VK_F)              | F key
            key.Sym.none,                   //  71   0x47   (VK_G)              | G key
            key.Sym.none,                   //  72   0x48   (VK_H)              | H key
            key.Sym.none,                   //  73   0x49   (VK_I)              | I key
            key.Sym.none,                   //  74   0x4A   (VK_J)              | J key
            key.Sym.none,                   //  75   0x4B   (VK_K)              | K key
            key.Sym.none,                   //  76   0x4C   (VK_L)              | L key
            key.Sym.none,                   //  77   0x4D   (VK_M)              | M key
            key.Sym.none,                   //  78   0x4E   (VK_N)              | N key
            key.Sym.none,                   //  79   0x4F   (VK_O)              | O key
            key.Sym.none,                   //  80   0x50   (VK_P)              | P key
            key.Sym.none,                   //  81   0x51   (VK_Q)              | Q key
            key.Sym.none,                   //  82   0x52   (VK_R)              | R key
            key.Sym.none,                   //  83   0x53   (VK_S)              | S key
            key.Sym.none,                   //  84   0x54   (VK_T)              | T key
            key.Sym.none,                   //  85   0x55   (VK_U)              | U key
            key.Sym.none,                   //  86   0x56   (VK_V)              | V key
            key.Sym.none,                   //  87   0x57   (VK_W)              | W key
            key.Sym.none,                   //  88   0x58   (VK_X)              | X key
            key.Sym.none,                   //  89   0x59   (VK_Y)              | Y key
            key.Sym.none,                   //  90   0x5A   (VK_Z)              | Z key
            key.Sym.leftSuper,              //  91   0x5B   VK_LWIN             | Left Windows  - MS Natural kbd
            key.Sym.rightSuper,             //  92   0x5C   VK_RWIN             | Right Windows - MS Natural kbd
            key.Sym.menu,                   //  93   0x5D   VK_APPS             | Application key-MS Natural kbd
            key.Sym.unknown,                //  94   0x5E   -- reserved --
            key.Sym.sleep,                  //  95   0x5F   VK_SLEEP
            key.Sym.kp_0,                   //  96   0x60   VK_NUMPAD0          | Numeric keypad 0 key
            key.Sym.kp_1,                   //  97   0x61   VK_NUMPAD1          | Numeric keypad 1 key
            key.Sym.kp_2,                   //  98   0x62   VK_NUMPAD2          | Numeric keypad 2 key
            key.Sym.kp_3,                   //  99   0x63   VK_NUMPAD3          | Numeric keypad 3 key
            key.Sym.kp_4,                   // 100   0x64   VK_NUMPAD4          | Numeric keypad 4 key
            key.Sym.kp_5,                   // 101   0x65   VK_NUMPAD5          | Numeric keypad 5 key
            key.Sym.kp_6,                   // 102   0x66   VK_NUMPAD6          | Numeric keypad 6 key
            key.Sym.kp_7,                   // 103   0x67   VK_NUMPAD7          | Numeric keypad 7 key
            key.Sym.kp_8,                   // 104   0x68   VK_NUMPAD8          | Numeric keypad 8 key
            key.Sym.kp_9,                   // 105   0x69   VK_NUMPAD9          | Numeric keypad 9 key
            key.Sym.kp_Multiply,            // 106   0x6A   VK_MULTIPLY         | Multiply key
            key.Sym.kp_Add,                 // 107   0x6B   VK_ADD              | Add key
            key.Sym.kp_Separator,           // 108   0x6C   VK_SEPARATOR        | Separator key
            key.Sym.kp_Subtract,            // 109   0x6D   VK_SUBTRACT         | Subtract key
            key.Sym.kp_Decimal,             // 110   0x6E   VK_DECIMAL          | Decimal key
            key.Sym.kp_Divide,              // 111   0x6F   VK_DIVIDE           | Divide key
            key.Sym.f1,                     // 112   0x70   VK_F1               | F1 key
            key.Sym.f2,                     // 113   0x71   VK_F2               | F2 key
            key.Sym.f3,                     // 114   0x72   VK_F3               | F3 key
            key.Sym.f4,                     // 115   0x73   VK_F4               | F4 key
            key.Sym.f5,                     // 116   0x74   VK_F5               | F5 key
            key.Sym.f6,                     // 117   0x75   VK_F6               | F6 key
            key.Sym.f7,                     // 118   0x76   VK_F7               | F7 key
            key.Sym.f8,                     // 119   0x77   VK_F8               | F8 key
            key.Sym.f9,                     // 120   0x78   VK_F9               | F9 key
            key.Sym.f10,                    // 121   0x79   VK_F10              | F10 key
            key.Sym.f11,                    // 122   0x7A   VK_F11              | F11 key
            key.Sym.f12,                    // 123   0x7B   VK_F12              | F12 key
            key.Sym.f13,                    // 124   0x7C   VK_F13              | F13 key
            key.Sym.f14,                    // 125   0x7D   VK_F14              | F14 key
            key.Sym.f15,                    // 126   0x7E   VK_F15              | F15 key
            key.Sym.f16,                    // 127   0x7F   VK_F16              | F16 key
            key.Sym.f17,                    // 128   0x80   VK_F17              | F17 key
            key.Sym.f18,                    // 129   0x81   VK_F18              | F18 key
            key.Sym.f19,                    // 130   0x82   VK_F19              | F19 key
            key.Sym.f20,                    // 131   0x83   VK_F20              | F20 key
            key.Sym.f21,                    // 132   0x84   VK_F21              | F21 key
            key.Sym.f22,                    // 133   0x85   VK_F22              | F22 key
            key.Sym.f23,                    // 134   0x86   VK_F23              | F23 key
            key.Sym.f24,                    // 135   0x87   VK_F24              | F24 key
            key.Sym.unknown,                // 136   0x88   -- unassigned --
            key.Sym.unknown,                // 137   0x89   -- unassigned --
            key.Sym.unknown,                // 138   0x8A   -- unassigned --
            key.Sym.unknown,                // 139   0x8B   -- unassigned --
            key.Sym.unknown,                // 140   0x8C   -- unassigned --
            key.Sym.unknown,                // 141   0x8D   -- unassigned --
            key.Sym.unknown,                // 142   0x8E   -- unassigned --
            key.Sym.unknown,                // 143   0x8F   -- unassigned --
            key.Sym.numLock,                // 144   0x90   VK_NUMLOCK          | Num Lock key
            key.Sym.scrollLock,             // 145   0x91   VK_SCROLL           | Scroll Lock key
                                            // Fujitsu/OASYS kbd --------------------
            key.Sym.jisho,                  // 146   0x92   VK_OEM_FJ_JISHO     | 'Dictionary' key /
                                            //              VK_OEM_NEC_EQUAL  = key on numpad on NEC PC-9800 kbd
            key.Sym.masshou,                // 147   0x93   VK_OEM_FJ_MASSHOU   | 'Unregister word' key
            key.Sym.touroku,                // 148   0x94   VK_OEM_FJ_TOUROKU   | 'Register word' key
            key.Sym.oyayubiLeft,            // 149   0x95   VK_OEM_FJ_LOYA      | 'Left OYAYUBI' key
            key.Sym.oyayubiRight,           // 150   0x96   VK_OEM_FJ_ROYA      | 'Right OYAYUBI' key
            key.Sym.unknown,                // 151   0x97   -- unassigned --
            key.Sym.unknown,                // 152   0x98   -- unassigned --
            key.Sym.unknown,                // 153   0x99   -- unassigned --
            key.Sym.unknown,                // 154   0x9A   -- unassigned --
            key.Sym.unknown,                // 155   0x9B   -- unassigned --
            key.Sym.unknown,                // 156   0x9C   -- unassigned --
            key.Sym.unknown,                // 157   0x9D   -- unassigned --
            key.Sym.unknown,                // 158   0x9E   -- unassigned --
            key.Sym.unknown,                // 159   0x9F   -- unassigned --
            key.Sym.leftShift,              // 160   0xA0   VK_LSHIFT           | Left Shift key
            key.Sym.rightShift,             // 161   0xA1   VK_RSHIFT           | Right Shift key
            key.Sym.leftCtrl,               // 162   0xA2   VK_LCONTROL         | Left Ctrl key
            key.Sym.rightCtrl,              // 163   0xA3   VK_RCONTROL         | Right Ctrl key
            key.Sym.leftAlt,                // 164   0xA4   VK_LMENU            | Left Menu key
            key.Sym.rightAlt,               // 165   0xA5   VK_RMENU            | Right Menu key
            key.Sym.browserBack,            // 166   0xA6   VK_BROWSER_BACK     | Browser Back key
            key.Sym.browserForward,         // 167   0xA7   VK_BROWSER_FORWARD  | Browser Forward key
            key.Sym.browserRefresh,         // 168   0xA8   VK_BROWSER_REFRESH  | Browser Refresh key
            key.Sym.browserStop,            // 169   0xA9   VK_BROWSER_STOP     | Browser Stop key
            key.Sym.browserSearch,          // 170   0xAA   VK_BROWSER_SEARCH   | Browser Search key
            key.Sym.browserFavorites,       // 171   0xAB   VK_BROWSER_FAVORITES| Browser Favorites key
            key.Sym.browserHome,            // 172   0xAC   VK_BROWSER_HOME     | Browser Start and Home key
            key.Sym.volumeMute,             // 173   0xAD   VK_VOLUME_MUTE      | Volume Mute key
            key.Sym.volumeDown,             // 174   0xAE   VK_VOLUME_DOWN      | Volume Down key
            key.Sym.volumeUp,               // 175   0xAF   VK_VOLUME_UP        | Volume Up key
            key.Sym.mediaNext,              // 176   0xB0   VK_MEDIA_NEXT_TRACK | Next Track key
            key.Sym.mediaPrevious,          // 177   0xB1   VK_MEDIA_PREV_TRACK | Previous Track key
            key.Sym.mediaStop,              // 178   0xB2   VK_MEDIA_STOP       | Stop Media key
            key.Sym.mediaPlay,              // 179   0xB3   VK_MEDIA_PLAY_PAUSE | Play/Pause Media key
            key.Sym.launchMail,             // 180   0xB4   VK_LAUNCH_MAIL      | Start Mail key
            key.Sym.launchMedia,            // 181   0xB5   VK_LAUNCH_MEDIA_SELECT Select Media key
            key.Sym.launch0,                // 182   0xB6   VK_LAUNCH_APP1      | Start Application 1 key
            key.Sym.launch1,                // 183   0xB7   VK_LAUNCH_APP2      | Start Application 2 key
            key.Sym.unknown,                // 184   0xB8   -- reserved --
            key.Sym.unknown,                // 185   0xB9   -- reserved --
            key.Sym.semicolon,              // 186   0xBA   VK_OEM_1            | ';:' for US
            key.Sym.plus,                   // 187   0xBB   VK_OEM_PLUS         | '+' any country
            key.Sym.comma,                  // 188   0xBC   VK_OEM_COMMA        | ',' any country
            key.Sym.minus,                  // 189   0xBD   VK_OEM_MINUS        | '-' any country
            key.Sym.period,                 // 190   0xBE   VK_OEM_PERIOD       | '.' any country
            key.Sym.slash,                  // 191   0xBF   VK_OEM_2            | '/?' for US
            key.Sym.asciiTilde,             // 192   0xC0   VK_OEM_3            | '`~' for US
            key.Sym.unknown,                // 193   0xC1   -- reserved --
            key.Sym.unknown,                // 194   0xC2   -- reserved --
            key.Sym.unknown,                // 195   0xC3   -- reserved --
            key.Sym.unknown,                // 196   0xC4   -- reserved --
            key.Sym.unknown,                // 197   0xC5   -- reserved --
            key.Sym.unknown,                // 198   0xC6   -- reserved --
            key.Sym.unknown,                // 199   0xC7   -- reserved --
            key.Sym.unknown,                // 200   0xC8   -- reserved --
            key.Sym.unknown,                // 201   0xC9   -- reserved --
            key.Sym.unknown,                // 202   0xCA   -- reserved --
            key.Sym.unknown,                // 203   0xCB   -- reserved --
            key.Sym.unknown,                // 204   0xCC   -- reserved --
            key.Sym.unknown,                // 205   0xCD   -- reserved --
            key.Sym.unknown,                // 206   0xCE   -- reserved --
            key.Sym.unknown,                // 207   0xCF   -- reserved --
            key.Sym.unknown,                // 208   0xD0   -- reserved --
            key.Sym.unknown,                // 209   0xD1   -- reserved --
            key.Sym.unknown,                // 210   0xD2   -- reserved --
            key.Sym.unknown,                // 211   0xD3   -- reserved --
            key.Sym.unknown,                // 212   0xD4   -- reserved --
            key.Sym.unknown,                // 213   0xD5   -- reserved --
            key.Sym.unknown,                // 214   0xD6   -- reserved --
            key.Sym.unknown,                // 215   0xD7   -- reserved --
            key.Sym.unknown,                // 216   0xD8   -- unassigned --
            key.Sym.unknown,                // 217   0xD9   -- unassigned --
            key.Sym.unknown,                // 218   0xDA   -- unassigned --
            key.Sym.bracketLeft,            // 219   0xDB   VK_OEM_4            | '[{' for US
            key.Sym.bar,                    // 220   0xDC   VK_OEM_5            | '\|' for US
            key.Sym.bracketRight,           // 221   0xDD   VK_OEM_6            | ']}' for US
            key.Sym.quoteDbl,               // 222   0xDE   VK_OEM_7            | ''"' for US
            key.Sym.unknown,                // 223   0xDF   VK_OEM_8
            key.Sym.unknown,                // 224   0xE0   -- reserved --
            key.Sym.unknown,                // 225   0xE1   VK_OEM_AX           | 'AX' key on Japanese AX kbd
            key.Sym.unknown,                // 226   0xE2   VK_OEM_102          | "<>" or "\|" on RT 102-key kbd
            key.Sym.unknown,                // 227   0xE3   VK_ICO_HELP         | Help key on ICO
            key.Sym.unknown,                // 228   0xE4   VK_ICO_00           | 00 key on ICO
            key.Sym.unknown,                // 229   0xE5   VK_PROCESSKEY       | IME Process key
            key.Sym.unknown,                // 230   0xE6   VK_ICO_CLEAR        |
            key.Sym.unknown,                // 231   0xE7   VK_PACKET           | Unicode char as keystrokes
            key.Sym.unknown,                // 232   0xE8   -- unassigned --
                                            // Nokia/Ericsson definitions ---------------
            key.Sym.unknown,                // 233   0xE9   VK_OEM_RESET
            key.Sym.unknown,                // 234   0xEA   VK_OEM_JUMP
            key.Sym.unknown,                // 235   0xEB   VK_OEM_PA1
            key.Sym.unknown,                // 236   0xEC   VK_OEM_PA2
            key.Sym.unknown,                // 237   0xED   VK_OEM_PA3
            key.Sym.unknown,                // 238   0xEE   VK_OEM_WSCTRL
            key.Sym.unknown,                // 239   0xEF   VK_OEM_CUSEL
            key.Sym.unknown,                // 240   0xF0   VK_OEM_ATTN
            key.Sym.unknown,                // 241   0xF1   VK_OEM_FINISH
            key.Sym.unknown,                // 242   0xF2   VK_OEM_COPY
            key.Sym.unknown,                // 243   0xF3   VK_OEM_AUTO
            key.Sym.unknown,                // 244   0xF4   VK_OEM_ENLW
            key.Sym.unknown,                // 245   0xF5   VK_OEM_BACKTAB
            key.Sym.unknown,                // 246   0xF6   VK_ATTN             | Attn key
            key.Sym.unknown,                // 247   0xF7   VK_CRSEL            | CrSel key
            key.Sym.unknown,                // 248   0xF8   VK_EXSEL            | ExSel key
            key.Sym.unknown,                // 249   0xF9   VK_EREOF            | Erase EOF key
            key.Sym.play,                   // 250   0xFA   VK_PLAY             | Play key
            key.Sym.zoom,                   // 251   0xFB   VK_ZOOM             | Zoom key
            key.Sym.unknown,                // 252   0xFC   VK_NONAME           | Reserved
            key.Sym.unknown,                // 253   0xFD   VK_PA1              | PA1 key
            key.Sym.clear,                  // 254   0xFE   VK_OEM_CLEAR        | Clear key
            key.Sym.unknown,
        ];

    }

}
