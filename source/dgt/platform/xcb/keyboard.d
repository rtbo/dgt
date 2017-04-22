module dgt.platform.xcb.keyboard;

version(linux):

import dgt.platform.xcb : xcbEventType;
import key = dgt.keys;
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
        key.Mods _mods;
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

    void processEvent(xcb_key_press_event_t *xcbEv, Window w)
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

        import std.typecons : scoped;
        auto ev = scoped!WindowKeyEvent(et, w, sym, code, _mods, text, keycode, keysym);
        w.handleEvent(ev);
    }

}

key.Mods modsForCode(in key.Code code)
{
    switch(code)
    {
        case key.Code.leftCtrl: return key.Mods.leftCtrl;
        case key.Code.leftShift: return key.Mods.leftShift;
        case key.Code.leftAlt: return key.Mods.leftAlt;
        case key.Code.leftSuper: return key.Mods.leftSuper;
        case key.Code.rightCtrl: return key.Mods.rightCtrl;
        case key.Code.rightShift: return key.Mods.rightShift;
        case key.Code.rightAlt: return key.Mods.rightAlt;
        case key.Code.rightSuper: return key.Mods.rightSuper;
        default: return key.Mods.none;
    }
}


key.Sym symForKeysym(uint keysym)
{
    if (keysym >= 0x20 && keysym < 0x80) {
        if (keysym >= 0x61 && keysym <= 0x7a) {
            keysym &= ~key.Sym.latin1SmallMask;
        }
        return cast(key.Sym)keysym;
    }
    if (keysym >= XKB_KEY_F1 && keysym <= XKB_KEY_F24) {
        return cast(key.Sym)(key.Sym.f1 + (keysym - XKB_KEY_F1));
    }
    auto k = (keysym in keysymMap);
    if (k) {
        return *k;
    }
    return key.Sym.unknown;
}


key.Code codeForKeycode(xkb_keycode_t keycode)
{
    if (keycode >= keycodeTable.length)
    {
        warningf("DGT-XCB: keycode 0x%x is out of bounds", keycode);
        return key.Code.unknown;
    }
    return keycodeTable[keycode];
}


private
{
    immutable key.Sym[uint] keysymMap;
    immutable key.Code[256] keycodeTable;

    shared static this() {

        keycodeTable = [
            // 0x00     0
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.escape,
            key.Code.d1,
            key.Code.d2,
            key.Code.d3,
            key.Code.d4,
            key.Code.d5,
            key.Code.d6,
            // 0x10     16
            key.Code.d7,
            key.Code.d8,
            key.Code.d9,
            key.Code.d0,
            key.Code.minus,
            key.Code.equals,
            key.Code.backspace,
            key.Code.tab,
            key.Code.q,
            key.Code.w,
            key.Code.e,
            key.Code.r,
            key.Code.t,
            key.Code.y,
            key.Code.u,
            key.Code.i,
            // 0x20     32
            key.Code.o,
            key.Code.p,
            key.Code.leftBracket,
            key.Code.rightBracket,
            key.Code.enter,
            key.Code.leftCtrl,
            key.Code.a,
            key.Code.s,
            key.Code.d,
            key.Code.f,
            key.Code.g,
            key.Code.h,
            key.Code.j,
            key.Code.k,
            key.Code.l,
            key.Code.semicolon,
            // 0x30     48
            key.Code.quote,
            key.Code.grave,
            key.Code.uK_Hash,
            key.Code.leftShift,
            key.Code.z,
            key.Code.x,
            key.Code.c,
            key.Code.v,
            key.Code.b,
            key.Code.n,
            key.Code.m,
            key.Code.comma,
            key.Code.period,
            key.Code.slash,
            key.Code.rightShift,
            key.Code.kp_Multiply,
            // 0x40     64
            key.Code.leftAlt,
            key.Code.space,
            key.Code.capsLock,
            key.Code.f1,
            key.Code.f2,
            key.Code.f3,
            key.Code.f4,
            key.Code.f5,
            key.Code.f6,
            key.Code.f7,
            key.Code.f8,
            key.Code.f9,
            key.Code.f10,
            key.Code.kp_NumLock,
            key.Code.scrollLock,
            key.Code.kp_7,
            // 0x50     80
            key.Code.kp_8,
            key.Code.kp_9,
            key.Code.kp_Subtract,
            key.Code.kp_4,
            key.Code.kp_5,
            key.Code.kp_6,
            key.Code.kp_Add,
            key.Code.kp_1,
            key.Code.kp_2,
            key.Code.kp_3,
            key.Code.kp_0,
            key.Code.kp_Period,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.uK_Backslash,
            key.Code.f11,
            // 0x60     96
            key.Code.f12,
            key.Code.unknown,
            key.Code.lang3,     // Katakana
            key.Code.lang4,     // Hiragana
            key.Code.unknown,   // Henkan
            key.Code.unknown,   // Hiragana_Katakana
            key.Code.unknown,   // Muhenkan
            key.Code.unknown,
            key.Code.kp_Enter,
            key.Code.rightCtrl,
            key.Code.kp_Divide,
            key.Code.printScreen,
            key.Code.rightAlt,
            key.Code.unknown,  // line feed
            key.Code.home,
            key.Code.up,
            // 0x70     112
            key.Code.pageUp,
            key.Code.left,
            key.Code.right,
            key.Code.end,
            key.Code.down,
            key.Code.pageDown,
            key.Code.insert,
            key.Code.delete_,
            key.Code.unknown,
            key.Code.mute,
            key.Code.volumeDown,
            key.Code.volumeUp,
            key.Code.unknown,  // power off
            key.Code.kp_Equal,
            key.Code.kp_PlusMinus,
            key.Code.pause,
            // 0x80     128
            key.Code.unknown, // launch A
            key.Code.kp_Decimal,
            key.Code.lang1,     // hangul
            key.Code.lang2,     // hangul/hanja toggle
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,
            key.Code.menu,
            key.Code.cancel,
            key.Code.again,
            key.Code.unknown,  // SunProps
            key.Code.undo,
            key.Code.unknown,  // SunFront
            key.Code.copy,
            key.Code.unknown,  // Open
            key.Code.paste,
            // 0x90     144
            key.Code.find,
            key.Code.cut,
            key.Code.help,
            key.Code.unknown,  // XF86MenuKB
            key.Code.unknown,  // XF86Calculator
            key.Code.unknown,
            key.Code.unknown,  //XF86Sleep
            key.Code.unknown,  //XF86Wakeup
            key.Code.unknown,  //XF86Explorer
            key.Code.unknown,  //XF86Send
            key.Code.unknown,
            key.Code.unknown,  //Xfer
            key.Code.unknown,  //launch1
            key.Code.unknown,  //launch2
            key.Code.unknown,  //WWW
            key.Code.unknown,  //DOS
            // 0xA0     160
            key.Code.unknown,  // Screensaver
            key.Code.unknown,
            key.Code.unknown,   // RotateWindows
            key.Code.unknown,   // Mail
            key.Code.unknown,   // Favorites
            key.Code.unknown,   // MyComputer
            key.Code.unknown,   // Back
            key.Code.unknown,   // Forward
            key.Code.unknown,
            key.Code.unknown,   // Eject
            key.Code.unknown,   // Eject
            key.Code.unknown,   // AudioNext
            key.Code.unknown,   // AudioPlay
            key.Code.unknown,   // AudioPrev
            key.Code.unknown,   // AudioStop
            key.Code.unknown,   // AudioRecord
            // 0xB0     176
            key.Code.unknown,   // AudioRewind
            key.Code.unknown,   // Phone
            key.Code.unknown,
            key.Code.unknown,   // Tools
            key.Code.unknown,   // HomePage
            key.Code.unknown,   // Reload
            key.Code.unknown,   // Close
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,   // ScrollUp
            key.Code.unknown,   // ScrollDown
            key.Code.unknown,   // parentleft
            key.Code.unknown,   // parentright
            key.Code.unknown,   // New
            key.Code.unknown,   // Redo
            key.Code.unknown,   // Tools
            // 0xC0     192
            key.Code.unknown,   // Launch5
            key.Code.unknown,   // Launch6
            key.Code.unknown,   // Launch7
            key.Code.unknown,   // Launch8
            key.Code.unknown,   // Launch9
            key.Code.unknown,
            key.Code.unknown,   // AudioMicMute
            key.Code.unknown,   // TouchpadToggle
            key.Code.unknown,   // TouchpadPadOn
            key.Code.unknown,   // TouchpadOff
            key.Code.unknown,
            key.Code.unknown,   // Mode_switch
            key.Code.unknown,   // Alt_L
            key.Code.unknown,   // Meta_L
            key.Code.unknown,   // Super_L
            key.Code.unknown,   // Hyper_L
            // 0xD0     208
            key.Code.unknown,   // AudioPlay
            key.Code.unknown,   // AudioPause
            key.Code.unknown,   // Launch3
            key.Code.unknown,   // Launch4
            key.Code.unknown,   // LaunchB
            key.Code.unknown,   // Suspend
            key.Code.unknown,   // Close
            key.Code.unknown,   // AudioPlay
            key.Code.unknown,   // AudioForward
            key.Code.unknown,
            key.Code.unknown,   // Print
            key.Code.unknown,
            key.Code.unknown,   // WebCam
            key.Code.unknown,
            key.Code.unknown,
            key.Code.unknown,   // Mail
            // 0xE0     224
            key.Code.unknown,   // Messenger
            key.Code.unknown,   // Seach
            key.Code.unknown,   // GO
            key.Code.unknown,   // Finance
            key.Code.unknown,   // Game
            key.Code.unknown,   // Shop
            key.Code.unknown,
            key.Code.unknown,   // Cancel
            key.Code.unknown,   // MonBrightnessDown
            key.Code.unknown,   // MonBrightnessUp
            key.Code.unknown,   // AudioMedia
            key.Code.unknown,   // Display
            key.Code.unknown,   // KbdLightOnOff
            key.Code.unknown,   // KbdBrightnessDown
            key.Code.unknown,   // KbdBrightnessUp
            key.Code.unknown,   // Send
            // 0xF0     240
            key.Code.unknown,   // Reply
            key.Code.unknown,   // MailForward
            key.Code.unknown,   // Save
            key.Code.unknown,   // Documents
            key.Code.unknown,   // Battery
            key.Code.unknown,   // Bluetooth
            key.Code.unknown,   // WLan
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



        key.Sym[uint] map;

        map[XKB_KEY_Escape] =                   key.Sym.escape;
        map[XKB_KEY_Tab] =                      key.Sym.tab;
        map[XKB_KEY_ISO_Left_Tab] =             key.Sym.leftTab;
        map[XKB_KEY_BackSpace] =                key.Sym.backspace;
        map[XKB_KEY_Return] =                   key.Sym.return_;
        map[XKB_KEY_Insert] =                   key.Sym.insert;
        map[XKB_KEY_Delete] =                   key.Sym.delete_;
        map[XKB_KEY_Clear] =                    key.Sym.delete_;
        map[XKB_KEY_Pause] =                    key.Sym.pause;
        map[XKB_KEY_Print] =                    key.Sym.print;
        map[0x1005FF60] =                       key.Sym.sysRq;         // hardcoded Sun SysReq
        map[0x1007ff00] =                       key.Sym.sysRq;         // hardcoded X386 SysReq

        // cursor movement

        map[XKB_KEY_Home] =                     key.Sym.home;
        map[XKB_KEY_End] =                      key.Sym.end;
        map[XKB_KEY_Left] =                     key.Sym.left;
        map[XKB_KEY_Up] =                       key.Sym.up;
        map[XKB_KEY_Right] =                    key.Sym.right;
        map[XKB_KEY_Down] =                     key.Sym.down;
        map[XKB_KEY_Page_Up] =                  key.Sym.pageUp;
        map[XKB_KEY_Page_Down] =                key.Sym.pageDown;
        map[XKB_KEY_Prior] =                    key.Sym.pageUp;
        map[XKB_KEY_Next] =                     key.Sym.pageDown;

        // modifiers

        map[XKB_KEY_Shift_L] =                  key.Sym.leftShift;
        map[XKB_KEY_Shift_R] =                  key.Sym.rightShift;
        map[XKB_KEY_Shift_Lock] =               key.Sym.shift;
        map[XKB_KEY_Control_L] =                key.Sym.leftCtrl;
        map[XKB_KEY_Control_R] =                key.Sym.rightCtrl;
        //map[XKB_KEY_Meta_L] =                   key.Sym.leftMeta;
        //map[XKB_KEY_Meta_R] =                   key.Sym.rightMeta;
        map[XKB_KEY_Alt_L] =                    key.Sym.leftAlt;
        map[XKB_KEY_Alt_R] =                    key.Sym.rightAlt;
        map[XKB_KEY_Caps_Lock] =                key.Sym.capsLock;
        map[XKB_KEY_Num_Lock] =                 key.Sym.numLock;
        map[XKB_KEY_Scroll_Lock] =              key.Sym.scrollLock;
        map[XKB_KEY_Super_L] =                  key.Sym.leftSuper;
        map[XKB_KEY_Super_R] =                  key.Sym.rightSuper;
        map[XKB_KEY_Menu] =                     key.Sym.menu;
        map[XKB_KEY_Help] =                     key.Sym.help;
        map[0x1000FF74] =                       key.Sym.leftTab; // hardcoded HP backtab
        map[0x1005FF10] =                       key.Sym.f11;     // hardcoded Sun F36 (labeled F11)
        map[0x1005FF11] =                       key.Sym.f12;     // hardcoded Sun F37 (labeled F12)

        // numeric and function keypad keys

        map[XKB_KEY_KP_Enter] =                 key.Sym.kp_Enter;
        map[XKB_KEY_KP_Delete] =                key.Sym.kp_Delete;
        map[XKB_KEY_KP_Home] =                  key.Sym.kp_Home;
        map[XKB_KEY_KP_Begin] =                 key.Sym.kp_Begin;
        map[XKB_KEY_KP_End] =                   key.Sym.kp_End;
        map[XKB_KEY_KP_Page_Up] =               key.Sym.kp_PageUp;
        map[XKB_KEY_KP_Page_Down] =             key.Sym.kp_PageDown;
        map[XKB_KEY_KP_Up] =                    key.Sym.kp_Up;
        map[XKB_KEY_KP_Down] =                  key.Sym.kp_Down;
        map[XKB_KEY_KP_Left] =                  key.Sym.kp_Left;
        map[XKB_KEY_KP_Right] =                 key.Sym.kp_Right;
        map[XKB_KEY_KP_Equal] =                 key.Sym.kp_Equal;
        map[XKB_KEY_KP_Multiply] =              key.Sym.kp_Multiply;
        map[XKB_KEY_KP_Add] =                   key.Sym.kp_Add;
        map[XKB_KEY_KP_Divide] =                key.Sym.kp_Divide;
        map[XKB_KEY_KP_Subtract] =              key.Sym.kp_Subtract;
        map[XKB_KEY_KP_Decimal] =               key.Sym.kp_Decimal;
        map[XKB_KEY_KP_Separator] =             key.Sym.kp_Separator;

        map[XKB_KEY_KP_0] =                     key.Sym.kp_0;
        map[XKB_KEY_KP_1] =                     key.Sym.kp_1;
        map[XKB_KEY_KP_2] =                     key.Sym.kp_2;
        map[XKB_KEY_KP_3] =                     key.Sym.kp_3;
        map[XKB_KEY_KP_4] =                     key.Sym.kp_4;
        map[XKB_KEY_KP_6] =                     key.Sym.kp_6;
        map[XKB_KEY_KP_7] =                     key.Sym.kp_7;
        map[XKB_KEY_KP_8] =                     key.Sym.kp_8;
        map[XKB_KEY_KP_9] =                     key.Sym.kp_9;

        // International input method support keys

        // International & multi-key character composition
        map[XKB_KEY_ISO_Level3_Shift] =         key.Sym.altGr;
        //map[XKB_KEY_Multi_key] =                key.Sym.multi_key;
        //map[XKB_KEY_Codeinput] =                key.Sym.codeinput;
        //map[XKB_KEY_SingleCandidate] =          key.Sym.singleCandidate;
        //map[XKB_KEY_MultipleCandidate] =        key.Sym.multipleCandidate;
        //map[XKB_KEY_PreviousCandidate] =        key.Sym.previousCandidate;

        // Misc Functions
        map[XKB_KEY_Mode_switch] =              key.Sym.modeSwitch;

        //// Japanese keyboard support
        //map[XKB_KEY_Kanji] =                    key.Sym.kanji;
        //map[XKB_KEY_Muhenkan] =                 key.Sym.muhenkan;
        //map[XKB_KEY_Henkan_Mode] =            key.Sym.henkan_Mode;
        //map[XKB_KEY_Henkan_Mode] =              key.Sym.henkan;
        //map[XKB_KEY_Henkan] =                   key.Sym.henkan;
        //map[XKB_KEY_Romaji] =                   key.Sym.romaji;
        //map[XKB_KEY_Hiragana] =                 key.Sym.hiragana;
        //map[XKB_KEY_Katakana] =                 key.Sym.katakana;
        //map[XKB_KEY_Hiragana_Katakana] =        key.Sym.hiragana_Katakana;
        //map[XKB_KEY_Zenkaku] =                  key.Sym.zenkaku;
        //map[XKB_KEY_Hankaku] =                  key.Sym.hankaku;
        //map[XKB_KEY_Zenkaku_Hankaku] =          key.Sym.zenkaku_Hankaku;
        //map[XKB_KEY_Touroku] =                  key.Sym.touroku;
        //map[XKB_KEY_Massyo] =                   key.Sym.massyo;
        //map[XKB_KEY_Kana_Lock] =                key.Sym.kana_Lock;
        //map[XKB_KEY_Kana_Shift] =               key.Sym.kana_Shift;
        //map[XKB_KEY_Eisu_Shift] =               key.Sym.eisu_Shift;
        //map[XKB_KEY_Eisu_toggle] =              key.Sym.eisu_toggle;
        //map[XKB_KEY_Kanji_Bangou] =           key.Sym.kanji_Bangou;
        //map[XKB_KEY_Zen_Koho] =               key.Sym.zen_Koho;
        //map[XKB_KEY_Mae_Koho] =               key.Sym.mae_Koho;
        //map[XKB_KEY_Kanji_Bangou] =             key.Sym.codeinput;
        //map[XKB_KEY_Zen_Koho] =                 key.Sym.multipleCandidate;
        //map[XKB_KEY_Mae_Koho] =                 key.Sym.previousCandidate;

        //// Korean keyboard support
        //map[XKB_KEY_HANGul] =                   key.Sym.hangul;
        //map[XKB_KEY_HANGul_Start] =             key.Sym.hangul_Start;
        //map[XKB_KEY_HANGul_End] =               key.Sym.hangul_End;
        //map[XKB_KEY_HANGul_Hanja] =             key.Sym.hangul_Hanja;
        //map[XKB_KEY_HANGul_Jamo] =              key.Sym.hangul_Jamo;
        //map[XKB_KEY_HANGul_Romaja] =            key.Sym.hangul_Romaja;
        //map[XKB_KEY_HANGul_Codeinput] =       key.Sym.hangul_Codeinput;
        //map[XKB_KEY_HANGul_Codeinput] =         key.Sym.codeinput;
        //map[XKB_KEY_HANGul_Jeonja] =            key.Sym.hangul_Jeonja;
        //map[XKB_KEY_HANGul_Banja] =             key.Sym.hangul_Banja;
        //map[XKB_KEY_HANGul_PreHanja] =          key.Sym.hangul_PreHanja;
        //map[XKB_KEY_HANGul_PostHanja] =         key.Sym.hangul_PostHanja;
        //map[XKB_KEY_HANGul_SingleCandidate] =   key.Sym.hangul_SingleCandidate;
        //map[XKB_KEY_HANGul_MultipleCandidate] = key.Sym.hangul_MultipleCandidate;
        //map[XKB_KEY_HANGul_PreviousCandidate] = key.Sym.hangul_PreviousCandidate;
        //map[XKB_KEY_HANGul_SingleCandidate] =   key.Sym.singleCandidate;
        //map[XKB_KEY_HANGul_MultipleCandidate] = key.Sym.multipleCandidate;
        //map[XKB_KEY_HANGul_PreviousCandidate] = key.Sym.previousCandidate;
        //map[XKB_KEY_HANGul_Special] =           key.Sym.hangul_Special;
        //map[XKB_KEY_HANGul_switch] =          key.Sym.hangul_switch;
        //map[XKB_KEY_HANGul_switch] =            key.Sym.Mode_switch;


        // Special keys from X.org - This include multimedia keys,
            // wireless/bluetooth/uwb keys, special launcher keys, etc.
        map[XKB_KEY_XF86Back] =                 key.Sym.browserBack;
        map[XKB_KEY_XF86Forward] =              key.Sym.browserForward;
        map[XKB_KEY_XF86Stop] =                 key.Sym.browserStop;
        map[XKB_KEY_XF86Refresh] =              key.Sym.browserRefresh;
        map[XKB_KEY_XF86Favorites] =            key.Sym.browserFavorites;
        map[XKB_KEY_XF86AudioMedia] =           key.Sym.launchMedia;
        map[XKB_KEY_XF86OpenURL] =              key.Sym.openUrl;
        map[XKB_KEY_XF86HomePage] =             key.Sym.browserHome;
        map[XKB_KEY_XF86Search] =               key.Sym.browserSearch;
        map[XKB_KEY_XF86AudioLowerVolume] =     key.Sym.volumeDown;
        map[XKB_KEY_XF86AudioMute] =            key.Sym.volumeMute;
        map[XKB_KEY_XF86AudioRaiseVolume] =     key.Sym.volumeUp;
        map[XKB_KEY_XF86AudioPlay] =            key.Sym.mediaPlay;
        map[XKB_KEY_XF86AudioStop] =            key.Sym.mediaStop;
        map[XKB_KEY_XF86AudioPrev] =            key.Sym.mediaPrevious;
        map[XKB_KEY_XF86AudioNext] =            key.Sym.mediaNext;
        map[XKB_KEY_XF86AudioRecord] =          key.Sym.mediaRecord;
        map[XKB_KEY_XF86AudioPause] =           key.Sym.mediaPause;
        map[XKB_KEY_XF86Mail] =                 key.Sym.launchMail;
        map[XKB_KEY_XF86MyComputer] =           key.Sym.myComputer;
        map[XKB_KEY_XF86Calculator] =           key.Sym.calculator;
        map[XKB_KEY_XF86Memo] =                 key.Sym.memo;
        map[XKB_KEY_XF86ToDoList] =             key.Sym.todoList;
        map[XKB_KEY_XF86Calendar] =             key.Sym.calendar;
        map[XKB_KEY_XF86PowerDown] =            key.Sym.powerDown;
        map[XKB_KEY_XF86ContrastAdjust] =       key.Sym.contrastAdjust;
        map[XKB_KEY_XF86Standby] =              key.Sym.standby;
        map[XKB_KEY_XF86MonBrightnessUp] =      key.Sym.monBrightnessUp;
        map[XKB_KEY_XF86MonBrightnessDown] =    key.Sym.monBrightnessDown;
        map[XKB_KEY_XF86KbdLightOnOff] =        key.Sym.keyboardLightOnOff;
        map[XKB_KEY_XF86KbdBrightnessUp] =      key.Sym.keyboardBrightnessUp;
        map[XKB_KEY_XF86KbdBrightnessDown] =    key.Sym.keyboardBrightnessDown;
        map[XKB_KEY_XF86PowerOff] =             key.Sym.powerOff;
        map[XKB_KEY_XF86WakeUp] =               key.Sym.wakeUp;
        map[XKB_KEY_XF86Eject] =                key.Sym.eject;
        map[XKB_KEY_XF86ScreenSaver] =          key.Sym.screenSaver;
        map[XKB_KEY_XF86WWW] =                  key.Sym.www;
        map[XKB_KEY_XF86Sleep] =                key.Sym.sleep;
        map[XKB_KEY_XF86LightBulb] =            key.Sym.lightBulb;
        map[XKB_KEY_XF86Shop] =                 key.Sym.shop;
        map[XKB_KEY_XF86History] =              key.Sym.history;
        map[XKB_KEY_XF86AddFavorite] =          key.Sym.addFavorite;
        map[XKB_KEY_XF86HotLinks] =             key.Sym.hotLinks;
        map[XKB_KEY_XF86BrightnessAdjust] =     key.Sym.brightnessAdjust;
        map[XKB_KEY_XF86Finance] =              key.Sym.finance;
        map[XKB_KEY_XF86Community] =            key.Sym.community;
        map[XKB_KEY_XF86AudioRewind] =          key.Sym.audioRewind;
        map[XKB_KEY_XF86BackForward] =          key.Sym.backForward;
        map[XKB_KEY_XF86ApplicationLeft] =      key.Sym.applicationLeft;
        map[XKB_KEY_XF86ApplicationRight] =     key.Sym.applicationRight;
        map[XKB_KEY_XF86Book] =                 key.Sym.book;
        map[XKB_KEY_XF86CD] =                   key.Sym.cd;
        map[XKB_KEY_XF86Calculater] =           key.Sym.calculator;
        map[XKB_KEY_XF86Clear] =                key.Sym.clear;
        map[XKB_KEY_XF86ClearGrab] =            key.Sym.clearGrab;
        map[XKB_KEY_XF86Close] =                key.Sym.close;
        map[XKB_KEY_XF86Copy] =                 key.Sym.copy;
        map[XKB_KEY_XF86Cut] =                  key.Sym.cut;
        map[XKB_KEY_XF86Display] =              key.Sym.display;
        map[XKB_KEY_XF86DOS] =                  key.Sym.dos;
        map[XKB_KEY_XF86Documents] =            key.Sym.documents;
        map[XKB_KEY_XF86Excel] =                key.Sym.excel;
        map[XKB_KEY_XF86Explorer] =             key.Sym.explorer;
        map[XKB_KEY_XF86Game] =                 key.Sym.game;
        map[XKB_KEY_XF86Go] =                   key.Sym.go;
        map[XKB_KEY_XF86iTouch] =               key.Sym.iTouch;
        map[XKB_KEY_XF86LogOff] =               key.Sym.logOff;
        map[XKB_KEY_XF86Market] =               key.Sym.market;
        map[XKB_KEY_XF86Meeting] =              key.Sym.meeting;
        map[XKB_KEY_XF86MenuKB] =               key.Sym.menuKB;
        map[XKB_KEY_XF86MenuPB] =               key.Sym.menuPB;
        map[XKB_KEY_XF86MySites] =              key.Sym.mySites;
        map[XKB_KEY_XF86New] =                  key.Sym.new_;
        map[XKB_KEY_XF86News] =                 key.Sym.news;
        map[XKB_KEY_XF86OfficeHome] =           key.Sym.officeHome;
        map[XKB_KEY_XF86Open] =                 key.Sym.open;
        map[XKB_KEY_XF86Option] =               key.Sym.option;
        map[XKB_KEY_XF86Paste] =                key.Sym.paste;
        map[XKB_KEY_XF86Phone] =                key.Sym.phone;
        map[XKB_KEY_XF86Reply] =                key.Sym.reply;
        map[XKB_KEY_XF86Reload] =               key.Sym.reload;
        map[XKB_KEY_XF86RotateWindows] =        key.Sym.rotateWindows;
        map[XKB_KEY_XF86RotationPB] =           key.Sym.rotationPB;
        map[XKB_KEY_XF86RotationKB] =           key.Sym.rotationKB;
        map[XKB_KEY_XF86Save] =                 key.Sym.save;
        map[XKB_KEY_XF86Send] =                 key.Sym.send;
        map[XKB_KEY_XF86Spell] =                key.Sym.spell;
        map[XKB_KEY_XF86SplitScreen] =          key.Sym.splitScreen;
        map[XKB_KEY_XF86Support] =              key.Sym.support;
        map[XKB_KEY_XF86TaskPane] =             key.Sym.taskPane;
        map[XKB_KEY_XF86Terminal] =             key.Sym.terminal;
        map[XKB_KEY_XF86Tools] =                key.Sym.tools;
        map[XKB_KEY_XF86Travel] =               key.Sym.travel;
        map[XKB_KEY_XF86Video] =                key.Sym.video;
        map[XKB_KEY_XF86Word] =                 key.Sym.word;
        map[XKB_KEY_XF86Xfer] =                 key.Sym.xfer;
        map[XKB_KEY_XF86ZoomIn] =               key.Sym.zoomIn;
        map[XKB_KEY_XF86ZoomOut] =              key.Sym.zoomOut;
        map[XKB_KEY_XF86Away] =                 key.Sym.away;
        map[XKB_KEY_XF86Messenger] =            key.Sym.messenger;
        map[XKB_KEY_XF86WebCam] =               key.Sym.webCam;
        map[XKB_KEY_XF86MailForward] =          key.Sym.mailForward;
        map[XKB_KEY_XF86Pictures] =             key.Sym.pictures;
        map[XKB_KEY_XF86Music] =                key.Sym.music;
        map[XKB_KEY_XF86Battery] =              key.Sym.battery;
        map[XKB_KEY_XF86Bluetooth] =            key.Sym.bluetooth;
        map[XKB_KEY_XF86WLAN] =                 key.Sym.wlan;
        map[XKB_KEY_XF86UWB] =                  key.Sym.uwb;
        map[XKB_KEY_XF86AudioForward] =         key.Sym.audioForward;
        map[XKB_KEY_XF86AudioRepeat] =          key.Sym.audioRepeat;
        map[XKB_KEY_XF86AudioRandomPlay] =      key.Sym.audioRandomPlay;
        map[XKB_KEY_XF86Subtitle] =             key.Sym.subtitle;
        map[XKB_KEY_XF86AudioCycleTrack] =      key.Sym.audioCycleTrack;
        map[XKB_KEY_XF86Time] =                 key.Sym.time;
        map[XKB_KEY_XF86Select] =               key.Sym.select;
        map[XKB_KEY_XF86View] =                 key.Sym.view;
        map[XKB_KEY_XF86TopMenu] =              key.Sym.topMenu;
        map[XKB_KEY_XF86Red] =                  key.Sym.red;
        map[XKB_KEY_XF86Green] =                key.Sym.green;
        map[XKB_KEY_XF86Yellow] =               key.Sym.yellow;
        map[XKB_KEY_XF86Blue] =                 key.Sym.blue;
        map[XKB_KEY_XF86Bluetooth] =            key.Sym.bluetooth;
        map[XKB_KEY_XF86Suspend] =              key.Sym.suspend;
        map[XKB_KEY_XF86Hibernate] =            key.Sym.hibernate;
        map[XKB_KEY_XF86TouchpadToggle] =       key.Sym.touchpadToggle;
        map[XKB_KEY_XF86TouchpadOn] =           key.Sym.touchpadOn;
        map[XKB_KEY_XF86TouchpadOff] =          key.Sym.touchpadOff;
        map[XKB_KEY_XF86AudioMicMute] =         key.Sym.micMute;
        map[XKB_KEY_XF86Launch0] =              key.Sym.launch0;
        map[XKB_KEY_XF86Launch1] =              key.Sym.launch1;
        map[XKB_KEY_XF86Launch2] =              key.Sym.launch2;
        map[XKB_KEY_XF86Launch3] =              key.Sym.launch3;
        map[XKB_KEY_XF86Launch4] =              key.Sym.launch4;
        map[XKB_KEY_XF86Launch5] =              key.Sym.launch5;
        map[XKB_KEY_XF86Launch6] =              key.Sym.launch6;
        map[XKB_KEY_XF86Launch7] =              key.Sym.launch7;
        map[XKB_KEY_XF86Launch8] =              key.Sym.launch8;
        map[XKB_KEY_XF86Launch9] =              key.Sym.launch9;
        map[XKB_KEY_XF86LaunchA] =              key.Sym.launchA;
        map[XKB_KEY_XF86LaunchB] =              key.Sym.launchB;
        map[XKB_KEY_XF86LaunchC] =              key.Sym.launchC;
        map[XKB_KEY_XF86LaunchD] =              key.Sym.launchD;
        map[XKB_KEY_XF86LaunchE] =              key.Sym.launchE;
        map[XKB_KEY_XF86LaunchF] =              key.Sym.launchF;

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
// #define KEY_RFKILL		247	/* key.Sym that controls all radios */
//
// #define KEY_MICMUTE		248	/* Mute / unmute the microphone */
