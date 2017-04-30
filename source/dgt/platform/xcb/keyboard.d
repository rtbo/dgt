module dgt.platform.xcb.keyboard;

version(linux):

import dgt.platform.xcb : xcbEventType;
import dgt.keys;
import dgt.event;
import dgt.window;

import xkbcommon.xkbcommon;
import xkbcommon.keysyms;
import xkbcommon.x11;
import xcb.xcb;
import xcb.xkb;

import std.experimental.logger;
import std.exception : assumeUnique;


class XcbKeyboard
{
    private
    {
        xkb_context *_context;
        uint _device;
        xkb_keymap *_keymap;
        xkb_state *_state;
        KeyMods _mods;
    }

    this(xcb_connection_t *connection, out uint xkbFirstEv)
    {
        import core.stdc.stdlib : free;

        xcb_prefetch_extension_data(connection, &xcb_xkb_id);

        auto reply = xcb_get_extension_data(connection, &xcb_xkb_id);
        if (!reply || !reply.present) {
            throw new Exception("XKB extension not supported by X server");
        }
        xkbFirstEv = reply.first_event;

        auto cookie = xcb_xkb_use_extension(connection,
                XKB_X11_MIN_MAJOR_XKB_VERSION,
                XKB_X11_MIN_MINOR_XKB_VERSION);
        auto xkbReply = xcb_xkb_use_extension_reply(connection, cookie, null);
        if (!xkbReply) {
            throw new Exception("could not get xkb extension");
        }
        else if(!xkbReply.supported) {
            free(xkbReply);
            throw new Exception("xkb required version not supported");
        }
        free(xkbReply);

        ushort mapParts =
            XCB_XKB_MAP_PART_KEY_TYPES |
            XCB_XKB_MAP_PART_KEY_SYMS |
            XCB_XKB_MAP_PART_MODIFIER_MAP |
            XCB_XKB_MAP_PART_EXPLICIT_COMPONENTS |
            XCB_XKB_MAP_PART_KEY_ACTIONS |
            XCB_XKB_MAP_PART_KEY_BEHAVIORS |
            XCB_XKB_MAP_PART_VIRTUAL_MODS |
            XCB_XKB_MAP_PART_VIRTUAL_MOD_MAP;

        ushort events =
            XCB_XKB_EVENT_TYPE_NEW_KEYBOARD_NOTIFY |
            XCB_XKB_EVENT_TYPE_MAP_NOTIFY |
            XCB_XKB_EVENT_TYPE_STATE_NOTIFY;

        auto cookie2 = xcb_xkb_select_events_checked(
                connection, XCB_XKB_ID_USE_CORE_KBD,
                events, 0, events, mapParts, mapParts, null);
        auto err = xcb_request_check(connection, cookie2);
        if (err) {
            throw new Exception("failed to select notify events from xcb xkb");
        }

        _context = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
        if (!_context) throw new Exception("could not alloc xkb context");
        scope(failure) xkb_context_unref(_context);

        _device = xkb_x11_get_core_keyboard_device_id(connection);
        if (_device == -1) throw new Exception("could not get X11 keyboard device id");

        _keymap = xkb_x11_keymap_new_from_device(_context, connection, _device,
                    XKB_KEYMAP_COMPILE_NO_FLAGS);
        if (!_keymap) throw new Exception("could not get keymap");
        scope(failure) xkb_keymap_unref(_keymap);

        _state = xkb_x11_state_new_from_device(_keymap, connection, _device);
        if (!_state) throw new Exception("could not alloc xkb state");
    }

    @property uint device() const
    {
        return _device;
    }

    void updateState(xcb_xkb_state_notify_event_t *e)
    {
        if (!_state) return;
        xkb_state_update_mask(_state,
                e.baseMods, e.latchedMods, e.lockedMods,
                e.baseGroup, e.latchedGroup, e.lockedGroup);
    }

    void shutdown()
    {
        xkb_state_unref(_state);
        xkb_keymap_unref(_keymap);
        xkb_context_unref(_context);
    }

    void processEvent(xcb_key_press_event_t *xcbEv, Window w, void delegate(Event) collector)
    {
        immutable keycode = xcbEv.detail;
        immutable keysym = xkb_state_key_get_one_sym(_state, keycode);

        immutable code = codeForKeycode(keycode);
        immutable sym = symForKeysym(keysym);
        immutable mods = modsForCode(code);
        string text;
        EventType et;

        if (xcbEventType(xcbEv) == XCB_KEY_PRESS)
        {
            et = EventType.keyDown;
            _mods |= mods;
            auto size = xkb_state_key_get_utf8(_state, keycode, null, 0);
            if (size > 0) {
                char[] buf = new char[size+1];
                xkb_state_key_get_utf8(_state, keycode, buf.ptr, size+1);
                buf = buf[0 .. size];
                text = assumeUnique(buf);
            }
        }
        else
        {
            assert(xcbEventType(xcbEv) == XCB_KEY_RELEASE);
            et = EventType.keyUp;
            _mods &= ~mods;
        }

        auto ev = new KeyEvent(et, w, sym, code, _mods, text, keycode, keysym);
        collector(ev);
    }

}

KeyMods modsForCode(in KeyCode code)
{
    switch(code)
    {
        case KeyCode.leftCtrl: return KeyMods.leftCtrl;
        case KeyCode.leftShift: return KeyMods.leftShift;
        case KeyCode.leftAlt: return KeyMods.leftAlt;
        case KeyCode.leftSuper: return KeyMods.leftSuper;
        case KeyCode.rightCtrl: return KeyMods.rightCtrl;
        case KeyCode.rightShift: return KeyMods.rightShift;
        case KeyCode.rightAlt: return KeyMods.rightAlt;
        case KeyCode.rightSuper: return KeyMods.rightSuper;
        default: return KeyMods.none;
    }
}


KeySym symForKeysym(uint keysym)
{
    if (keysym >= 0x20 && keysym < 0x80) {
        if (keysym >= 0x61 && keysym <= 0x7a) {
            keysym &= ~KeySym.latin1SmallMask;
        }
        return cast(KeySym)keysym;
    }
    if (keysym >= XKB_KEY_F1 && keysym <= XKB_KEY_F24) {
        return cast(KeySym)(KeySym.f1 + (keysym - XKB_KEY_F1));
    }
    auto k = (keysym in keysymMap);
    if (k) {
        return *k;
    }
    return KeySym.unknown;
}


KeyCode codeForKeycode(xkb_keycode_t keycode)
{
    if (keycode >= keycodeTable.length)
    {
        warningf("DGT-XCB: keycode 0x%x is out of bounds", keycode);
        return KeyCode.unknown;
    }
    return keycodeTable[keycode];
}


private
{
    immutable KeySym[uint] keysymMap;
    immutable KeyCode[256] keycodeTable;

    shared static this() {

        keycodeTable = [
            // 0x00     0
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.escape,
            KeyCode.d1,
            KeyCode.d2,
            KeyCode.d3,
            KeyCode.d4,
            KeyCode.d5,
            KeyCode.d6,
            // 0x10     16
            KeyCode.d7,
            KeyCode.d8,
            KeyCode.d9,
            KeyCode.d0,
            KeyCode.minus,
            KeyCode.equals,
            KeyCode.backspace,
            KeyCode.tab,
            KeyCode.q,
            KeyCode.w,
            KeyCode.e,
            KeyCode.r,
            KeyCode.t,
            KeyCode.y,
            KeyCode.u,
            KeyCode.i,
            // 0x20     32
            KeyCode.o,
            KeyCode.p,
            KeyCode.leftBracket,
            KeyCode.rightBracket,
            KeyCode.enter,
            KeyCode.leftCtrl,
            KeyCode.a,
            KeyCode.s,
            KeyCode.d,
            KeyCode.f,
            KeyCode.g,
            KeyCode.h,
            KeyCode.j,
            KeyCode.k,
            KeyCode.l,
            KeyCode.semicolon,
            // 0x30     48
            KeyCode.quote,
            KeyCode.grave,
            KeyCode.uK_Hash,
            KeyCode.leftShift,
            KeyCode.z,
            KeyCode.x,
            KeyCode.c,
            KeyCode.v,
            KeyCode.b,
            KeyCode.n,
            KeyCode.m,
            KeyCode.comma,
            KeyCode.period,
            KeyCode.slash,
            KeyCode.rightShift,
            KeyCode.kp_Multiply,
            // 0x40     64
            KeyCode.leftAlt,
            KeyCode.space,
            KeyCode.capsLock,
            KeyCode.f1,
            KeyCode.f2,
            KeyCode.f3,
            KeyCode.f4,
            KeyCode.f5,
            KeyCode.f6,
            KeyCode.f7,
            KeyCode.f8,
            KeyCode.f9,
            KeyCode.f10,
            KeyCode.kp_NumLock,
            KeyCode.scrollLock,
            KeyCode.kp_7,
            // 0x50     80
            KeyCode.kp_8,
            KeyCode.kp_9,
            KeyCode.kp_Subtract,
            KeyCode.kp_4,
            KeyCode.kp_5,
            KeyCode.kp_6,
            KeyCode.kp_Add,
            KeyCode.kp_1,
            KeyCode.kp_2,
            KeyCode.kp_3,
            KeyCode.kp_0,
            KeyCode.kp_Period,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.uK_Backslash,
            KeyCode.f11,
            // 0x60     96
            KeyCode.f12,
            KeyCode.unknown,
            KeyCode.lang3,     // Katakana
            KeyCode.lang4,     // Hiragana
            KeyCode.unknown,   // Henkan
            KeyCode.unknown,   // Hiragana_Katakana
            KeyCode.unknown,   // Muhenkan
            KeyCode.unknown,
            KeyCode.kp_Enter,
            KeyCode.rightCtrl,
            KeyCode.kp_Divide,
            KeyCode.printScreen,
            KeyCode.rightAlt,
            KeyCode.unknown,  // line feed
            KeyCode.home,
            KeyCode.up,
            // 0x70     112
            KeyCode.pageUp,
            KeyCode.left,
            KeyCode.right,
            KeyCode.end,
            KeyCode.down,
            KeyCode.pageDown,
            KeyCode.insert,
            KeyCode.delete_,
            KeyCode.unknown,
            KeyCode.mute,
            KeyCode.volumeDown,
            KeyCode.volumeUp,
            KeyCode.unknown,  // power off
            KeyCode.kp_Equal,
            KeyCode.kp_PlusMinus,
            KeyCode.pause,
            // 0x80     128
            KeyCode.unknown, // launch A
            KeyCode.kp_Decimal,
            KeyCode.lang1,     // hangul
            KeyCode.lang2,     // hangul/hanja toggle
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.menu,
            KeyCode.cancel,
            KeyCode.again,
            KeyCode.unknown,  // SunProps
            KeyCode.undo,
            KeyCode.unknown,  // SunFront
            KeyCode.copy,
            KeyCode.unknown,  // Open
            KeyCode.paste,
            // 0x90     144
            KeyCode.find,
            KeyCode.cut,
            KeyCode.help,
            KeyCode.unknown,  // XF86MenuKB
            KeyCode.unknown,  // XF86Calculator
            KeyCode.unknown,
            KeyCode.unknown,  //XF86Sleep
            KeyCode.unknown,  //XF86Wakeup
            KeyCode.unknown,  //XF86Explorer
            KeyCode.unknown,  //XF86Send
            KeyCode.unknown,
            KeyCode.unknown,  //Xfer
            KeyCode.unknown,  //launch1
            KeyCode.unknown,  //launch2
            KeyCode.unknown,  //WWW
            KeyCode.unknown,  //DOS
            // 0xA0     160
            KeyCode.unknown,  // Screensaver
            KeyCode.unknown,
            KeyCode.unknown,   // RotateWindows
            KeyCode.unknown,   // Mail
            KeyCode.unknown,   // Favorites
            KeyCode.unknown,   // MyComputer
            KeyCode.unknown,   // Back
            KeyCode.unknown,   // Forward
            KeyCode.unknown,
            KeyCode.unknown,   // Eject
            KeyCode.unknown,   // Eject
            KeyCode.unknown,   // AudioNext
            KeyCode.unknown,   // AudioPlay
            KeyCode.unknown,   // AudioPrev
            KeyCode.unknown,   // AudioStop
            KeyCode.unknown,   // AudioRecord
            // 0xB0     176
            KeyCode.unknown,   // AudioRewind
            KeyCode.unknown,   // Phone
            KeyCode.unknown,
            KeyCode.unknown,   // Tools
            KeyCode.unknown,   // HomePage
            KeyCode.unknown,   // Reload
            KeyCode.unknown,   // Close
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,   // ScrollUp
            KeyCode.unknown,   // ScrollDown
            KeyCode.unknown,   // parentleft
            KeyCode.unknown,   // parentright
            KeyCode.unknown,   // New
            KeyCode.unknown,   // Redo
            KeyCode.unknown,   // Tools
            // 0xC0     192
            KeyCode.unknown,   // Launch5
            KeyCode.unknown,   // Launch6
            KeyCode.unknown,   // Launch7
            KeyCode.unknown,   // Launch8
            KeyCode.unknown,   // Launch9
            KeyCode.unknown,
            KeyCode.unknown,   // AudioMicMute
            KeyCode.unknown,   // TouchpadToggle
            KeyCode.unknown,   // TouchpadPadOn
            KeyCode.unknown,   // TouchpadOff
            KeyCode.unknown,
            KeyCode.unknown,   // Mode_switch
            KeyCode.unknown,   // Alt_L
            KeyCode.unknown,   // Meta_L
            KeyCode.unknown,   // Super_L
            KeyCode.unknown,   // Hyper_L
            // 0xD0     208
            KeyCode.unknown,   // AudioPlay
            KeyCode.unknown,   // AudioPause
            KeyCode.unknown,   // Launch3
            KeyCode.unknown,   // Launch4
            KeyCode.unknown,   // LaunchB
            KeyCode.unknown,   // Suspend
            KeyCode.unknown,   // Close
            KeyCode.unknown,   // AudioPlay
            KeyCode.unknown,   // AudioForward
            KeyCode.unknown,
            KeyCode.unknown,   // Print
            KeyCode.unknown,
            KeyCode.unknown,   // WebCam
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,   // Mail
            // 0xE0     224
            KeyCode.unknown,   // Messenger
            KeyCode.unknown,   // Seach
            KeyCode.unknown,   // GO
            KeyCode.unknown,   // Finance
            KeyCode.unknown,   // Game
            KeyCode.unknown,   // Shop
            KeyCode.unknown,
            KeyCode.unknown,   // Cancel
            KeyCode.unknown,   // MonBrightnessDown
            KeyCode.unknown,   // MonBrightnessUp
            KeyCode.unknown,   // AudioMedia
            KeyCode.unknown,   // Display
            KeyCode.unknown,   // KbdLightOnOff
            KeyCode.unknown,   // KbdBrightnessDown
            KeyCode.unknown,   // KbdBrightnessUp
            KeyCode.unknown,   // Send
            // 0xF0     240
            KeyCode.unknown,   // Reply
            KeyCode.unknown,   // MailForward
            KeyCode.unknown,   // Save
            KeyCode.unknown,   // Documents
            KeyCode.unknown,   // Battery
            KeyCode.unknown,   // Bluetooth
            KeyCode.unknown,   // WLan
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown,
            KeyCode.unknown
        ];



        KeySym[uint] map;

        map[XKB_KEY_Escape] =                   KeySym.escape;
        map[XKB_KEY_Tab] =                      KeySym.tab;
        map[XKB_KEY_ISO_Left_Tab] =             KeySym.leftTab;
        map[XKB_KEY_BackSpace] =                KeySym.backspace;
        map[XKB_KEY_Return] =                   KeySym.return_;
        map[XKB_KEY_Insert] =                   KeySym.insert;
        map[XKB_KEY_Delete] =                   KeySym.delete_;
        map[XKB_KEY_Clear] =                    KeySym.delete_;
        map[XKB_KEY_Pause] =                    KeySym.pause;
        map[XKB_KEY_Print] =                    KeySym.print;
        map[0x1005FF60] =                       KeySym.sysRq;         // hardcoded Sun SysReq
        map[0x1007ff00] =                       KeySym.sysRq;         // hardcoded X386 SysReq

        // cursor movement

        map[XKB_KEY_Home] =                     KeySym.home;
        map[XKB_KEY_End] =                      KeySym.end;
        map[XKB_KEY_Left] =                     KeySym.left;
        map[XKB_KEY_Up] =                       KeySym.up;
        map[XKB_KEY_Right] =                    KeySym.right;
        map[XKB_KEY_Down] =                     KeySym.down;
        map[XKB_KEY_Page_Up] =                  KeySym.pageUp;
        map[XKB_KEY_Page_Down] =                KeySym.pageDown;
        map[XKB_KEY_Prior] =                    KeySym.pageUp;
        map[XKB_KEY_Next] =                     KeySym.pageDown;

        // modifiers

        map[XKB_KEY_Shift_L] =                  KeySym.leftShift;
        map[XKB_KEY_Shift_R] =                  KeySym.rightShift;
        map[XKB_KEY_Shift_Lock] =               KeySym.shift;
        map[XKB_KEY_Control_L] =                KeySym.leftCtrl;
        map[XKB_KEY_Control_R] =                KeySym.rightCtrl;
        //map[XKB_KEY_Meta_L] =                   KeySym.leftMeta;
        //map[XKB_KEY_Meta_R] =                   KeySym.rightMeta;
        map[XKB_KEY_Alt_L] =                    KeySym.leftAlt;
        map[XKB_KEY_Alt_R] =                    KeySym.rightAlt;
        map[XKB_KEY_Caps_Lock] =                KeySym.capsLock;
        map[XKB_KEY_Num_Lock] =                 KeySym.numLock;
        map[XKB_KEY_Scroll_Lock] =              KeySym.scrollLock;
        map[XKB_KEY_Super_L] =                  KeySym.leftSuper;
        map[XKB_KEY_Super_R] =                  KeySym.rightSuper;
        map[XKB_KEY_Menu] =                     KeySym.menu;
        map[XKB_KEY_Help] =                     KeySym.help;
        map[0x1000FF74] =                       KeySym.leftTab; // hardcoded HP backtab
        map[0x1005FF10] =                       KeySym.f11;     // hardcoded Sun F36 (labeled F11)
        map[0x1005FF11] =                       KeySym.f12;     // hardcoded Sun F37 (labeled F12)

        // numeric and function keypad keys

        map[XKB_KEY_KP_Enter] =                 KeySym.kp_Enter;
        map[XKB_KEY_KP_Delete] =                KeySym.kp_Delete;
        map[XKB_KEY_KP_Home] =                  KeySym.kp_Home;
        map[XKB_KEY_KP_Begin] =                 KeySym.kp_Begin;
        map[XKB_KEY_KP_End] =                   KeySym.kp_End;
        map[XKB_KEY_KP_Page_Up] =               KeySym.kp_PageUp;
        map[XKB_KEY_KP_Page_Down] =             KeySym.kp_PageDown;
        map[XKB_KEY_KP_Up] =                    KeySym.kp_Up;
        map[XKB_KEY_KP_Down] =                  KeySym.kp_Down;
        map[XKB_KEY_KP_Left] =                  KeySym.kp_Left;
        map[XKB_KEY_KP_Right] =                 KeySym.kp_Right;
        map[XKB_KEY_KP_Equal] =                 KeySym.kp_Equal;
        map[XKB_KEY_KP_Multiply] =              KeySym.kp_Multiply;
        map[XKB_KEY_KP_Add] =                   KeySym.kp_Add;
        map[XKB_KEY_KP_Divide] =                KeySym.kp_Divide;
        map[XKB_KEY_KP_Subtract] =              KeySym.kp_Subtract;
        map[XKB_KEY_KP_Decimal] =               KeySym.kp_Decimal;
        map[XKB_KEY_KP_Separator] =             KeySym.kp_Separator;

        map[XKB_KEY_KP_0] =                     KeySym.kp_0;
        map[XKB_KEY_KP_1] =                     KeySym.kp_1;
        map[XKB_KEY_KP_2] =                     KeySym.kp_2;
        map[XKB_KEY_KP_3] =                     KeySym.kp_3;
        map[XKB_KEY_KP_4] =                     KeySym.kp_4;
        map[XKB_KEY_KP_6] =                     KeySym.kp_6;
        map[XKB_KEY_KP_7] =                     KeySym.kp_7;
        map[XKB_KEY_KP_8] =                     KeySym.kp_8;
        map[XKB_KEY_KP_9] =                     KeySym.kp_9;

        // International input method support keys

        // International & multi-key character composition
        map[XKB_KEY_ISO_Level3_Shift] =         KeySym.altGr;
        //map[XKB_KEY_Multi_key] =                KeySym.multi_key;
        //map[XKB_KEY_Codeinput] =                KeySym.codeinput;
        //map[XKB_KEY_SingleCandidate] =          KeySym.singleCandidate;
        //map[XKB_KEY_MultipleCandidate] =        KeySym.multipleCandidate;
        //map[XKB_KEY_PreviousCandidate] =        KeySym.previousCandidate;

        // Misc Functions
        map[XKB_KEY_Mode_switch] =              KeySym.modeSwitch;

        //// Japanese keyboard support
        //map[XKB_KEY_Kanji] =                    KeySym.kanji;
        //map[XKB_KEY_Muhenkan] =                 KeySym.muhenkan;
        //map[XKB_KEY_Henkan_Mode] =            KeySym.henkan_Mode;
        //map[XKB_KEY_Henkan_Mode] =              KeySym.henkan;
        //map[XKB_KEY_Henkan] =                   KeySym.henkan;
        //map[XKB_KEY_Romaji] =                   KeySym.romaji;
        //map[XKB_KEY_Hiragana] =                 KeySym.hiragana;
        //map[XKB_KEY_Katakana] =                 KeySym.katakana;
        //map[XKB_KEY_Hiragana_Katakana] =        KeySym.hiragana_Katakana;
        //map[XKB_KEY_Zenkaku] =                  KeySym.zenkaku;
        //map[XKB_KEY_Hankaku] =                  KeySym.hankaku;
        //map[XKB_KEY_Zenkaku_Hankaku] =          KeySym.zenkaku_Hankaku;
        //map[XKB_KEY_Touroku] =                  KeySym.touroku;
        //map[XKB_KEY_Massyo] =                   KeySym.massyo;
        //map[XKB_KEY_Kana_Lock] =                KeySym.kana_Lock;
        //map[XKB_KEY_Kana_Shift] =               KeySym.kana_Shift;
        //map[XKB_KEY_Eisu_Shift] =               KeySym.eisu_Shift;
        //map[XKB_KEY_Eisu_toggle] =              KeySym.eisu_toggle;
        //map[XKB_KEY_Kanji_Bangou] =           KeySym.kanji_Bangou;
        //map[XKB_KEY_Zen_Koho] =               KeySym.zen_Koho;
        //map[XKB_KEY_Mae_Koho] =               KeySym.mae_Koho;
        //map[XKB_KEY_Kanji_Bangou] =             KeySym.codeinput;
        //map[XKB_KEY_Zen_Koho] =                 KeySym.multipleCandidate;
        //map[XKB_KEY_Mae_Koho] =                 KeySym.previousCandidate;

        //// Korean keyboard support
        //map[XKB_KEY_HANGul] =                   KeySym.hangul;
        //map[XKB_KEY_HANGul_Start] =             KeySym.hangul_Start;
        //map[XKB_KEY_HANGul_End] =               KeySym.hangul_End;
        //map[XKB_KEY_HANGul_Hanja] =             KeySym.hangul_Hanja;
        //map[XKB_KEY_HANGul_Jamo] =              KeySym.hangul_Jamo;
        //map[XKB_KEY_HANGul_Romaja] =            KeySym.hangul_Romaja;
        //map[XKB_KEY_HANGul_Codeinput] =       KeySym.hangul_Codeinput;
        //map[XKB_KEY_HANGul_Codeinput] =         KeySym.codeinput;
        //map[XKB_KEY_HANGul_Jeonja] =            KeySym.hangul_Jeonja;
        //map[XKB_KEY_HANGul_Banja] =             KeySym.hangul_Banja;
        //map[XKB_KEY_HANGul_PreHanja] =          KeySym.hangul_PreHanja;
        //map[XKB_KEY_HANGul_PostHanja] =         KeySym.hangul_PostHanja;
        //map[XKB_KEY_HANGul_SingleCandidate] =   KeySym.hangul_SingleCandidate;
        //map[XKB_KEY_HANGul_MultipleCandidate] = KeySym.hangul_MultipleCandidate;
        //map[XKB_KEY_HANGul_PreviousCandidate] = KeySym.hangul_PreviousCandidate;
        //map[XKB_KEY_HANGul_SingleCandidate] =   KeySym.singleCandidate;
        //map[XKB_KEY_HANGul_MultipleCandidate] = KeySym.multipleCandidate;
        //map[XKB_KEY_HANGul_PreviousCandidate] = KeySym.previousCandidate;
        //map[XKB_KEY_HANGul_Special] =           KeySym.hangul_Special;
        //map[XKB_KEY_HANGul_switch] =          KeySym.hangul_switch;
        //map[XKB_KEY_HANGul_switch] =            KeySym.Mode_switch;


        // Special keys from X.org - This include multimedia keys,
            // wireless/bluetooth/uwb keys, special launcher keys, etc.
        map[XKB_KEY_XF86Back] =                 KeySym.browserBack;
        map[XKB_KEY_XF86Forward] =              KeySym.browserForward;
        map[XKB_KEY_XF86Stop] =                 KeySym.browserStop;
        map[XKB_KEY_XF86Refresh] =              KeySym.browserRefresh;
        map[XKB_KEY_XF86Favorites] =            KeySym.browserFavorites;
        map[XKB_KEY_XF86AudioMedia] =           KeySym.launchMedia;
        map[XKB_KEY_XF86OpenURL] =              KeySym.openUrl;
        map[XKB_KEY_XF86HomePage] =             KeySym.browserHome;
        map[XKB_KEY_XF86Search] =               KeySym.browserSearch;
        map[XKB_KEY_XF86AudioLowerVolume] =     KeySym.volumeDown;
        map[XKB_KEY_XF86AudioMute] =            KeySym.volumeMute;
        map[XKB_KEY_XF86AudioRaiseVolume] =     KeySym.volumeUp;
        map[XKB_KEY_XF86AudioPlay] =            KeySym.mediaPlay;
        map[XKB_KEY_XF86AudioStop] =            KeySym.mediaStop;
        map[XKB_KEY_XF86AudioPrev] =            KeySym.mediaPrevious;
        map[XKB_KEY_XF86AudioNext] =            KeySym.mediaNext;
        map[XKB_KEY_XF86AudioRecord] =          KeySym.mediaRecord;
        map[XKB_KEY_XF86AudioPause] =           KeySym.mediaPause;
        map[XKB_KEY_XF86Mail] =                 KeySym.launchMail;
        map[XKB_KEY_XF86MyComputer] =           KeySym.myComputer;
        map[XKB_KEY_XF86Calculator] =           KeySym.calculator;
        map[XKB_KEY_XF86Memo] =                 KeySym.memo;
        map[XKB_KEY_XF86ToDoList] =             KeySym.todoList;
        map[XKB_KEY_XF86Calendar] =             KeySym.calendar;
        map[XKB_KEY_XF86PowerDown] =            KeySym.powerDown;
        map[XKB_KEY_XF86ContrastAdjust] =       KeySym.contrastAdjust;
        map[XKB_KEY_XF86Standby] =              KeySym.standby;
        map[XKB_KEY_XF86MonBrightnessUp] =      KeySym.monBrightnessUp;
        map[XKB_KEY_XF86MonBrightnessDown] =    KeySym.monBrightnessDown;
        map[XKB_KEY_XF86KbdLightOnOff] =        KeySym.keyboardLightOnOff;
        map[XKB_KEY_XF86KbdBrightnessUp] =      KeySym.keyboardBrightnessUp;
        map[XKB_KEY_XF86KbdBrightnessDown] =    KeySym.keyboardBrightnessDown;
        map[XKB_KEY_XF86PowerOff] =             KeySym.powerOff;
        map[XKB_KEY_XF86WakeUp] =               KeySym.wakeUp;
        map[XKB_KEY_XF86Eject] =                KeySym.eject;
        map[XKB_KEY_XF86ScreenSaver] =          KeySym.screenSaver;
        map[XKB_KEY_XF86WWW] =                  KeySym.www;
        map[XKB_KEY_XF86Sleep] =                KeySym.sleep;
        map[XKB_KEY_XF86LightBulb] =            KeySym.lightBulb;
        map[XKB_KEY_XF86Shop] =                 KeySym.shop;
        map[XKB_KEY_XF86History] =              KeySym.history;
        map[XKB_KEY_XF86AddFavorite] =          KeySym.addFavorite;
        map[XKB_KEY_XF86HotLinks] =             KeySym.hotLinks;
        map[XKB_KEY_XF86BrightnessAdjust] =     KeySym.brightnessAdjust;
        map[XKB_KEY_XF86Finance] =              KeySym.finance;
        map[XKB_KEY_XF86Community] =            KeySym.community;
        map[XKB_KEY_XF86AudioRewind] =          KeySym.audioRewind;
        map[XKB_KEY_XF86BackForward] =          KeySym.backForward;
        map[XKB_KEY_XF86ApplicationLeft] =      KeySym.applicationLeft;
        map[XKB_KEY_XF86ApplicationRight] =     KeySym.applicationRight;
        map[XKB_KEY_XF86Book] =                 KeySym.book;
        map[XKB_KEY_XF86CD] =                   KeySym.cd;
        map[XKB_KEY_XF86Calculater] =           KeySym.calculator;
        map[XKB_KEY_XF86Clear] =                KeySym.clear;
        map[XKB_KEY_XF86ClearGrab] =            KeySym.clearGrab;
        map[XKB_KEY_XF86Close] =                KeySym.close;
        map[XKB_KEY_XF86Copy] =                 KeySym.copy;
        map[XKB_KEY_XF86Cut] =                  KeySym.cut;
        map[XKB_KEY_XF86Display] =              KeySym.display;
        map[XKB_KEY_XF86DOS] =                  KeySym.dos;
        map[XKB_KEY_XF86Documents] =            KeySym.documents;
        map[XKB_KEY_XF86Excel] =                KeySym.excel;
        map[XKB_KEY_XF86Explorer] =             KeySym.explorer;
        map[XKB_KEY_XF86Game] =                 KeySym.game;
        map[XKB_KEY_XF86Go] =                   KeySym.go;
        map[XKB_KEY_XF86iTouch] =               KeySym.iTouch;
        map[XKB_KEY_XF86LogOff] =               KeySym.logOff;
        map[XKB_KEY_XF86Market] =               KeySym.market;
        map[XKB_KEY_XF86Meeting] =              KeySym.meeting;
        map[XKB_KEY_XF86MenuKB] =               KeySym.menuKB;
        map[XKB_KEY_XF86MenuPB] =               KeySym.menuPB;
        map[XKB_KEY_XF86MySites] =              KeySym.mySites;
        map[XKB_KEY_XF86New] =                  KeySym.new_;
        map[XKB_KEY_XF86News] =                 KeySym.news;
        map[XKB_KEY_XF86OfficeHome] =           KeySym.officeHome;
        map[XKB_KEY_XF86Open] =                 KeySym.open;
        map[XKB_KEY_XF86Option] =               KeySym.option;
        map[XKB_KEY_XF86Paste] =                KeySym.paste;
        map[XKB_KEY_XF86Phone] =                KeySym.phone;
        map[XKB_KEY_XF86Reply] =                KeySym.reply;
        map[XKB_KEY_XF86Reload] =               KeySym.reload;
        map[XKB_KEY_XF86RotateWindows] =        KeySym.rotateWindows;
        map[XKB_KEY_XF86RotationPB] =           KeySym.rotationPB;
        map[XKB_KEY_XF86RotationKB] =           KeySym.rotationKB;
        map[XKB_KEY_XF86Save] =                 KeySym.save;
        map[XKB_KEY_XF86Send] =                 KeySym.send;
        map[XKB_KEY_XF86Spell] =                KeySym.spell;
        map[XKB_KEY_XF86SplitScreen] =          KeySym.splitScreen;
        map[XKB_KEY_XF86Support] =              KeySym.support;
        map[XKB_KEY_XF86TaskPane] =             KeySym.taskPane;
        map[XKB_KEY_XF86Terminal] =             KeySym.terminal;
        map[XKB_KEY_XF86Tools] =                KeySym.tools;
        map[XKB_KEY_XF86Travel] =               KeySym.travel;
        map[XKB_KEY_XF86Video] =                KeySym.video;
        map[XKB_KEY_XF86Word] =                 KeySym.word;
        map[XKB_KEY_XF86Xfer] =                 KeySym.xfer;
        map[XKB_KEY_XF86ZoomIn] =               KeySym.zoomIn;
        map[XKB_KEY_XF86ZoomOut] =              KeySym.zoomOut;
        map[XKB_KEY_XF86Away] =                 KeySym.away;
        map[XKB_KEY_XF86Messenger] =            KeySym.messenger;
        map[XKB_KEY_XF86WebCam] =               KeySym.webCam;
        map[XKB_KEY_XF86MailForward] =          KeySym.mailForward;
        map[XKB_KEY_XF86Pictures] =             KeySym.pictures;
        map[XKB_KEY_XF86Music] =                KeySym.music;
        map[XKB_KEY_XF86Battery] =              KeySym.battery;
        map[XKB_KEY_XF86Bluetooth] =            KeySym.bluetooth;
        map[XKB_KEY_XF86WLAN] =                 KeySym.wlan;
        map[XKB_KEY_XF86UWB] =                  KeySym.uwb;
        map[XKB_KEY_XF86AudioForward] =         KeySym.audioForward;
        map[XKB_KEY_XF86AudioRepeat] =          KeySym.audioRepeat;
        map[XKB_KEY_XF86AudioRandomPlay] =      KeySym.audioRandomPlay;
        map[XKB_KEY_XF86Subtitle] =             KeySym.subtitle;
        map[XKB_KEY_XF86AudioCycleTrack] =      KeySym.audioCycleTrack;
        map[XKB_KEY_XF86Time] =                 KeySym.time;
        map[XKB_KEY_XF86Select] =               KeySym.select;
        map[XKB_KEY_XF86View] =                 KeySym.view;
        map[XKB_KEY_XF86TopMenu] =              KeySym.topMenu;
        map[XKB_KEY_XF86Red] =                  KeySym.red;
        map[XKB_KEY_XF86Green] =                KeySym.green;
        map[XKB_KEY_XF86Yellow] =               KeySym.yellow;
        map[XKB_KEY_XF86Blue] =                 KeySym.blue;
        map[XKB_KEY_XF86Bluetooth] =            KeySym.bluetooth;
        map[XKB_KEY_XF86Suspend] =              KeySym.suspend;
        map[XKB_KEY_XF86Hibernate] =            KeySym.hibernate;
        map[XKB_KEY_XF86TouchpadToggle] =       KeySym.touchpadToggle;
        map[XKB_KEY_XF86TouchpadOn] =           KeySym.touchpadOn;
        map[XKB_KEY_XF86TouchpadOff] =          KeySym.touchpadOff;
        map[XKB_KEY_XF86AudioMicMute] =         KeySym.micMute;
        map[XKB_KEY_XF86Launch0] =              KeySym.launch0;
        map[XKB_KEY_XF86Launch1] =              KeySym.launch1;
        map[XKB_KEY_XF86Launch2] =              KeySym.launch2;
        map[XKB_KEY_XF86Launch3] =              KeySym.launch3;
        map[XKB_KEY_XF86Launch4] =              KeySym.launch4;
        map[XKB_KEY_XF86Launch5] =              KeySym.launch5;
        map[XKB_KEY_XF86Launch6] =              KeySym.launch6;
        map[XKB_KEY_XF86Launch7] =              KeySym.launch7;
        map[XKB_KEY_XF86Launch8] =              KeySym.launch8;
        map[XKB_KEY_XF86Launch9] =              KeySym.launch9;
        map[XKB_KEY_XF86LaunchA] =              KeySym.launchA;
        map[XKB_KEY_XF86LaunchB] =              KeySym.launchB;
        map[XKB_KEY_XF86LaunchC] =              KeySym.launchC;
        map[XKB_KEY_XF86LaunchD] =              KeySym.launchD;
        map[XKB_KEY_XF86LaunchE] =              KeySym.launchE;
        map[XKB_KEY_XF86LaunchF] =              KeySym.launchF;

        map.rehash();


        import std.exception : assumeUnique;

        keysymMap = assumeUnique(map);
    }

}

// extract of linux/input.h
// /*
//  * Keys and buttons
//  *
//  * Most of the keys/buttons are modeled after USB HUT 1.12
//  * (see http://www.usb.org/developers/hidpage).
//  * Abbreviations in the comments:
//  * AC - Application Control
//  * AL - Application Launch Button
//  * SC - System Control
//  */
//
// #define KEY_RESERVED		0
// #define KEY_ESC			1
// #define KEY_1			2
// #define KEY_2			3
// #define KEY_3			4
// #define KEY_4			5
// #define KEY_5			6
// #define KEY_6			7
// #define KEY_7			8
// #define KEY_8			9
// #define KEY_9			10
// #define KEY_0			11
// #define KEY_MINUS		12
// #define KEY_EQUAL		13
// #define KEY_BACKSPACE		14
// #define KEY_TAB			15
// #define KEY_Q			16
// #define KEY_W			17
// #define KEY_E			18
// #define KEY_R			19
// #define KEY_T			20
// #define KEY_Y			21
// #define KEY_U			22
// #define KEY_I			23
// #define KEY_O			24
// #define KEY_P			25
// #define KEY_LEFTBRACE		26
// #define KEY_RIGHTBRACE		27
// #define KEY_ENTER		28
// #define KEY_LEFTCTRL		29
// #define KEY_A			30
// #define KEY_S			31
// #define KEY_D			32
// #define KEY_F			33
// #define KEY_G			34
// #define KEY_H			35
// #define KEY_J			36
// #define KEY_K			37
// #define KEY_L			38
// #define KEY_SEMICOLON		39
// #define KEY_APOSTROPHE		40
// #define KEY_GRAVE		41
// #define KEY_LEFTSHIFT		42
// #define KEY_BACKSLASH		43
// #define KEY_Z			44
// #define KEY_X			45
// #define KEY_C			46
// #define KEY_V			47
// #define KEY_B			48
// #define KEY_N			49
// #define KEY_M			50
// #define KEY_COMMA		51
// #define KEY_DOT			52
// #define KEY_SLASH		53
// #define KEY_RIGHTSHIFT		54
// #define KEY_KPASTERISK		55
// #define KEY_LEFTALT		56
// #define KEY_SPACE		57
// #define KEY_CAPSLOCK		58
// #define KEY_F1			59
// #define KEY_F2			60
// #define KEY_F3			61
// #define KEY_F4			62
// #define KEY_F5			63
// #define KEY_F6			64
// #define KEY_F7			65
// #define KEY_F8			66
// #define KEY_F9			67
// #define KEY_F10			68
// #define KEY_NUMLOCK		69
// #define KEY_SCROLLLOCK		70
// #define KEY_KP7			71
// #define KEY_KP8			72
// #define KEY_KP9			73
// #define KEY_KPMINUS		74
// #define KEY_KP4			75
// #define KEY_KP5			76
// #define KEY_KP6			77
// #define KEY_KPPLUS		78
// #define KEY_KP1			79
// #define KEY_KP2			80
// #define KEY_KP3			81
// #define KEY_KP0			82
// #define KEY_KPDOT		83
//
// #define KEY_ZENKAKUHANKAKU	85
// #define KEY_102ND		86
// #define KEY_F11			87
// #define KEY_F12			88
// #define KEY_RO			89
// #define KEY_KATAKANA		90
// #define KEY_HIRAGANA		91
// #define KEY_HENKAN		92
// #define KEY_KATAKANAHIRAGANA	93
// #define KEY_MUHENKAN		94
// #define KEY_KPJPCOMMA		95
// #define KEY_KPENTER		96
// #define KEY_RIGHTCTRL		97
// #define KEY_KPSLASH		98
// #define KEY_SYSRQ		99
// #define KEY_RIGHTALT		100
// #define KEY_LINEFEED		101
// #define KEY_HOME		102
// #define KEY_UP			103
// #define KEY_PAGEUP		104
// #define KEY_LEFT		105
// #define KEY_RIGHT		106
// #define KEY_END			107
// #define KEY_DOWN		108
// #define KEY_PAGEDOWN		109
// #define KEY_INSERT		110
// #define KEY_DELETE		111
// #define KEY_MACRO		112
// #define KEY_MUTE		113
// #define KEY_VOLUMEDOWN		114
// #define KEY_VOLUMEUP		115
// #define KEY_POWER		116	/* SC System Power Down */
// #define KEY_KPEQUAL		117
// #define KEY_KPPLUSMINUS		118
// #define KEY_PAUSE		119
// #define KEY_SCALE		120	/* AL Compiz Scale (Expose) */
//
// #define KEY_KPCOMMA		121
// #define KEY_HANGEUL		122
// #define KEY_HANGUEL		KEY_HANGEUL
// #define KEY_HANJA		123
// #define KEY_YEN			124
// #define KEY_LEFTMETA		125
// #define KEY_RIGHTMETA		126
// #define KEY_COMPOSE		127
//
// #define KEY_STOP		128	/* AC Stop */
// #define KEY_AGAIN		129
// #define KEY_PROPS		130	/* AC Properties */
// #define KEY_UNDO		131	/* AC Undo */
// #define KEY_FRONT		132
// #define KEY_COPY		133	/* AC Copy */
// #define KEY_OPEN		134	/* AC Open */
// #define KEY_PASTE		135	/* AC Paste */
// #define KEY_FIND		136	/* AC Search */
// #define KEY_CUT			137	/* AC Cut */
// #define KEY_HELP		138	/* AL Integrated Help Center */
// #define KEY_MENU		139	/* Menu (show menu) */
// #define KEY_CALC		140	/* AL Calculator */
// #define KEY_SETUP		141
// #define KEY_SLEEP		142	/* SC System Sleep */
// #define KEY_WAKEUP		143	/* System Wake Up */
// #define KEY_FILE		144	/* AL Local Machine Browser */
// #define KEY_SENDFILE		145
// #define KEY_DELETEFILE		146
// #define KEY_XFER		147
// #define KEY_PROG1		148
// #define KEY_PROG2		149
// #define KEY_WWW			150	/* AL Internet Browser */
// #define KEY_MSDOS		151
// #define KEY_COFFEE		152	/* AL Terminal Lock/Screensaver */
// #define KEY_SCREENLOCK		KEY_COFFEE
// #define KEY_DIRECTION		153
// #define KEY_CYCLEWINDOWS	154
// #define KEY_MAIL		155
// #define KEY_BOOKMARKS		156	/* AC Bookmarks */
// #define KEY_COMPUTER		157
// #define KEY_BACK		158	/* AC Back */
// #define KEY_FORWARD		159	/* AC Forward */
// #define KEY_CLOSECD		160
// #define KEY_EJECTCD		161
// #define KEY_EJECTCLOSECD	162
// #define KEY_NEXTSONG		163
// #define KEY_PLAYPAUSE		164
// #define KEY_PREVIOUSSONG	165
// #define KEY_STOPCD		166
// #define KEY_RECORD		167
// #define KEY_REWIND		168
// #define KEY_PHONE		169	/* Media Select Telephone */
// #define KEY_ISO			170
// #define KEY_CONFIG		171	/* AL Consumer Control Configuration */
// #define KEY_HOMEPAGE		172	/* AC Home */
// #define KEY_REFRESH		173	/* AC Refresh */
// #define KEY_EXIT		174	/* AC Exit */
// #define KEY_MOVE		175
// #define KEY_EDIT		176
// #define KEY_SCROLLUP		177
// #define KEY_SCROLLDOWN		178
// #define KEY_KPLEFTPAREN		179
// #define KEY_KPRIGHTPAREN	180
// #define KEY_NEW			181	/* AC New */
// #define KEY_REDO		182	/* AC Redo/Repeat */
//
// #define KEY_F13			183
// #define KEY_F14			184
// #define KEY_F15			185
// #define KEY_F16			186
// #define KEY_F17			187
// #define KEY_F18			188
// #define KEY_F19			189
// #define KEY_F20			190
// #define KEY_F21			191
// #define KEY_F22			192
// #define KEY_F23			193
// #define KEY_F24			194
//
// #define KEY_PLAYCD		200
// #define KEY_PAUSECD		201
// #define KEY_PROG3		202
// #define KEY_PROG4		203
// #define KEY_DASHBOARD		204	/* AL Dashboard */
// #define KEY_SUSPEND		205
// #define KEY_CLOSE		206	/* AC Close */
// #define KEY_PLAY		207
// #define KEY_FASTFORWARD		208
// #define KEY_BASSBOOST		209
// #define KEY_PRINT		210	/* AC Print */
// #define KEY_HP			211
// #define KEY_CAMERA		212
// #define KEY_SOUND		213
// #define KEY_QUESTION		214
// #define KEY_EMAIL		215
// #define KEY_CHAT		216
// #define KEY_SEARCH		217
// #define KEY_CONNECT		218
// #define KEY_FINANCE		219	/* AL Checkbook/Finance */
// #define KEY_SPORT		220
// #define KEY_SHOP		221
// #define KEY_ALTERASE		222
// #define KEY_CANCEL		223	/* AC Cancel */
// #define KEY_BRIGHTNESSDOWN	224
// #define KEY_BRIGHTNESSUP	225
// #define KEY_MEDIA		226
//
// #define KEY_SWITCHVIDEOMODE	227	/* Cycle between available video
// 					   outputs (Monitor/LCD/TV-out/etc) */
// #define KEY_KBDILLUMTOGGLE	228
// #define KEY_KBDILLUMDOWN	229
// #define KEY_KBDILLUMUP		230
//
// #define KEY_SEND		231	/* AC Send */
// #define KEY_REPLY		232	/* AC Reply */
// #define KEY_FORWARDMAIL		233	/* AC Forward Msg */
// #define KEY_SAVE		234	/* AC Save */
// #define KEY_DOCUMENTS		235
//
// #define KEY_BATTERY		236
//
// #define KEY_BLUETOOTH		237
// #define KEY_WLAN		238
// #define KEY_UWB			239
//
// #define KEY_UNKNOWN		240
//
// #define KEY_VIDEO_NEXT		241	/* drive next video source */
// #define KEY_VIDEO_PREV		242	/* drive previous video source */
// #define KEY_BRIGHTNESS_CYCLE	243	/* brightness up, after max is min */
// #define KEY_BRIGHTNESS_ZERO	244	/* brightness off, use ambient */
// #define KEY_DISPLAY_OFF		245	/* display device to off state */
//
// #define KEY_WWAN		246	/* Wireless WAN (LTE, UMTS, GSM, etc.) */
// #define KEY_WIMAX		KEY_WWAN
// #define KEY_RFKILL		247	/* KeySym that controls all radios */
//
// #define KEY_MICMUTE		248	/* Mute / unmute the microphone */
