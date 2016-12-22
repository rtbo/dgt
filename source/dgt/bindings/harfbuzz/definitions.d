module dgt.bindings.harfbuzz.definitions;

import dgt.bindings;

extern(C) nothrow @nogc:

mixin(globalEnumsAliasesCode!(
    hb_memory_mode_t,
    hb_buffer_content_type_t,
    hb_buffer_flags_t,
    hb_buffer_cluster_level_t,
    hb_buffer_serialize_flags_t,
    hb_buffer_serialize_format_t,
    hb_direction_t,
    hb_script_t,
    hb_unicode_general_category_t,
    hb_unicode_combining_class_t,
));


// Blob

enum hb_memory_mode_t
{
    HB_MEMORY_MODE_DUPLICATE,
    HB_MEMORY_MODE_READONLY,
    HB_MEMORY_MODE_WRITABLE,
    HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE
}

struct hb_blob_t;

// buffer

struct hb_glyph_info_t
{
    hb_codepoint_t codepoint;
    hb_mask_t mask;
    uint cluster;

    private hb_var_int_t var1;
    private hb_var_int_t var2;
}

struct hb_glyph_position_t
{
    hb_position_t x_advance;
    hb_position_t y_advance;
    hb_position_t x_offset;
    hb_position_t y_offset;

    private hb_var_int_t var;
}

struct hb_segment_properties_t
{
    hb_direction_t direction;
    hb_script_t script;
    hb_language_t language;

    private void* reserved1;
    private void* reserved2;
}

enum HB_SEGMENT_PROPERTIES_DEFAULT = hb_segment_properties_t(
    HB_DIRECTION_INVALID,
    HB_SCRIPT_INVALID,
    HB_LANGUAGE_INVALID,
    null,
    null
);

struct hb_buffer_t;

enum hb_buffer_content_type_t
{
    HB_BUFFER_CONTENT_TYPE_INVALID = 0,
    HB_BUFFER_CONTENT_TYPE_UNICODE,
    HB_BUFFER_CONTENT_TYPE_GLYPHS
}

enum hb_buffer_flags_t
{
    HB_BUFFER_FLAG_DEFAULT = 0x00000000u,
    HB_BUFFER_FLAG_BOT = 0x00000001u,
    HB_BUFFER_FLAG_EOT = 0x00000002u,
    HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES = 0x00000004u
}

enum hb_buffer_cluster_level_t
{
    HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES = 0,
    HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS = 1,
    HB_BUFFER_CLUSTER_LEVEL_CHARACTERS = 2,
    HB_BUFFER_CLUSTER_LEVEL_DEFAULT = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
}

enum HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT = 0xFFFDu;

enum hb_buffer_serialize_flags_t
{
    HB_BUFFER_SERIALIZE_FLAG_DEFAULT = 0x00000000u,
    HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS = 0x00000001u,
    HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS = 0x00000002u,
    HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES = 0x00000004u,
    HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS = 0x00000008u
}

enum hb_buffer_serialize_format_t
{
    HB_BUFFER_SERIALIZE_FORMAT_TEXT = HB_TAG('T', 'E', 'X', 'T'),
    HB_BUFFER_SERIALIZE_FORMAT_JSON = HB_TAG('J', 'S', 'O', 'N'),
    HB_BUFFER_SERIALIZE_FORMAT_INVALID = HB_TAG_NONE
}

alias hb_buffer_message_func_t = hb_bool_t function(hb_buffer_t* buffer,
 hb_font_t* font, const(char)* message, void* user_data);

// common

alias hb_bool_t = int;

alias hb_codepoint_t = uint;
alias hb_position_t = int;
alias hb_mask_t = uint;

union hb_var_int_t
{
    uint u32;
    int i32;
    ushort[2] u16;
    short[2] i16;
    ubyte[4] u8;
    byte[4] i8;
}

alias hb_tag_t = uint;

hb_tag_t HB_TAG(ubyte c1, ubyte c2, ubyte c3, ubyte c4)
{
    return c1 << 24 | c2 << 16 | c2 << 8 | c1;
}

// #define HB_UNTAG(tag)   ((ubyte)((tag)>>24)), ((ubyte)((tag)>>16)), ((ubyte)((tag)>>8)), ((ubyte)(tag))

enum HB_TAG_NONE = HB_TAG(0, 0, 0, 0);
enum HB_TAG_MAX = HB_TAG(0xff, 0xff, 0xff, 0xff);
enum HB_TAG_MAX_SIGNED = HB_TAG(0x7f, 0xff, 0xff, 0xff);

enum hb_direction_t
{
    HB_DIRECTION_INVALID = 0,
    HB_DIRECTION_LTR = 4,
    HB_DIRECTION_RTL,
    HB_DIRECTION_TTB,
    HB_DIRECTION_BTT
}

bool HB_DIRECTION_IS_VALID(in hb_direction_t dir)
{
    immutable idir = cast(uint) dir;
    return (idir & ~3U) == 4;
}

bool HB_DIRECTION_IS_HORIZONTAL(in hb_direction_t dir)
{
    immutable idir = cast(uint) dir;
    return (idir & ~1U) == 4;
}

bool HB_DIRECTION_IS_VERTICAL(in hb_direction_t dir)
{
    immutable idir = cast(uint) dir;
    return (idir & ~1U) == 6;
}

bool HB_DIRECTION_IS_FORWARD(in hb_direction_t dir)
{
    immutable idir = cast(uint) dir;
    return (idir & ~2U) == 4;
}

bool HB_DIRECTION_IS_BACKWARD(in hb_direction_t dir)
{
    immutable idir = cast(uint) dir;
    return (idir & ~2U) == 6;
}

hb_direction_t HB_DIRECTION_REVERSE(in hb_direction_t dir)
{
    return cast(hb_direction_t)((cast(uint) dir) ^ 1);
}

struct hb_language_impl_t;
alias hb_language_t = const(hb_language_impl_t)*;
enum HB_LANGUAGE_INVALID = cast(hb_language_t)null;

enum hb_script_t
{
    /*1.1*/
    HB_SCRIPT_COMMON = HB_TAG('Z', 'y', 'y', 'y'),
    /*1.1*/
    HB_SCRIPT_INHERITED = HB_TAG('Z', 'i',
            'n', 'h'),
    /*5.0*/
    HB_SCRIPT_UNKNOWN = HB_TAG('Z', 'z', 'z', 'z'),

    /*1.1*/
    HB_SCRIPT_ARABIC = HB_TAG('A', 'r', 'a', 'b'),
    /*1.1*/
    HB_SCRIPT_ARMENIAN = HB_TAG('A', 'r',
            'm', 'n'),
    /*1.1*/
    HB_SCRIPT_BENGALI = HB_TAG('B', 'e', 'n', 'g'),
    /*1.1*/
    HB_SCRIPT_CYRILLIC = HB_TAG('C', 'y', 'r', 'l'),
    /*1.1*/
    HB_SCRIPT_DEVANAGARI = HB_TAG('D', 'e',
            'v', 'a'),
    /*1.1*/
    HB_SCRIPT_GEORGIAN = HB_TAG('G', 'e', 'o', 'r'),
    /*1.1*/
    HB_SCRIPT_GREEK = HB_TAG('G', 'r', 'e', 'k'),
    /*1.1*/
    HB_SCRIPT_GUJARATI = HB_TAG('G', 'u',
            'j', 'r'),
    /*1.1*/
    HB_SCRIPT_GURMUKHI = HB_TAG('G', 'u', 'r', 'u'),
    /*1.1*/
    HB_SCRIPT_HANGUL = HB_TAG('H', 'a', 'n', 'g'),
    /*1.1*/
    HB_SCRIPT_HAN = HB_TAG('H', 'a',
            'n', 'i'),
    /*1.1*/
    HB_SCRIPT_HEBREW = HB_TAG('H', 'e', 'b', 'r'),
    /*1.1*/
    HB_SCRIPT_HIRAGANA = HB_TAG('H', 'i', 'r', 'a'),
    /*1.1*/
    HB_SCRIPT_KANNADA = HB_TAG('K', 'n',
            'd', 'a'),
    /*1.1*/
    HB_SCRIPT_KATAKANA = HB_TAG('K', 'a', 'n', 'a'),
    /*1.1*/
    HB_SCRIPT_LAO = HB_TAG('L', 'a', 'o', 'o'),
    /*1.1*/
    HB_SCRIPT_LATIN = HB_TAG('L', 'a',
            't', 'n'),
    /*1.1*/
    HB_SCRIPT_MALAYALAM = HB_TAG('M', 'l', 'y', 'm'),
    /*1.1*/
    HB_SCRIPT_ORIYA = HB_TAG('O', 'r', 'y', 'a'),
    /*1.1*/
    HB_SCRIPT_TAMIL = HB_TAG('T', 'a',
            'm', 'l'),
    /*1.1*/
    HB_SCRIPT_TELUGU = HB_TAG('T', 'e', 'l', 'u'),
    /*1.1*/
    HB_SCRIPT_THAI = HB_TAG('T', 'h', 'a', 'i'),

    /*2.0*/
    HB_SCRIPT_TIBETAN = HB_TAG('T', 'i',
            'b', 't'),

    /*3.0*/
    HB_SCRIPT_BOPOMOFO = HB_TAG('B', 'o', 'p', 'o'),
    /*3.0*/
    HB_SCRIPT_BRAILLE = HB_TAG('B', 'r', 'a', 'i'),
    /*3.0*/
    HB_SCRIPT_CANADIAN_SYLLABICS = HB_TAG('C', 'a', 'n',
            's'),
    /*3.0*/
    HB_SCRIPT_CHEROKEE = HB_TAG('C', 'h', 'e', 'r'),
    /*3.0*/
    HB_SCRIPT_ETHIOPIC = HB_TAG('E', 't', 'h', 'i'),
    /*3.0*/
    HB_SCRIPT_KHMER = HB_TAG('K', 'h', 'm',
            'r'),
    /*3.0*/
    HB_SCRIPT_MONGOLIAN = HB_TAG('M', 'o', 'n', 'g'),
    /*3.0*/
    HB_SCRIPT_MYANMAR = HB_TAG('M', 'y', 'm', 'r'),
    /*3.0*/
    HB_SCRIPT_OGHAM = HB_TAG('O', 'g',
            'a', 'm'),
    /*3.0*/
    HB_SCRIPT_RUNIC = HB_TAG('R', 'u', 'n', 'r'),
    /*3.0*/
    HB_SCRIPT_SINHALA = HB_TAG('S', 'i', 'n', 'h'),
    /*3.0*/
    HB_SCRIPT_SYRIAC = HB_TAG('S',
            'y', 'r', 'c'),
    /*3.0*/
    HB_SCRIPT_THAANA = HB_TAG('T', 'h', 'a', 'a'),
    /*3.0*/
    HB_SCRIPT_YI = HB_TAG('Y', 'i', 'i', 'i'),

    /*3.1*/
    HB_SCRIPT_DESERET = HB_TAG('D', 's', 'r',
            't'),
    /*3.1*/
    HB_SCRIPT_GOTHIC = HB_TAG('G', 'o', 't', 'h'),
    /*3.1*/
    HB_SCRIPT_OLD_ITALIC = HB_TAG('I', 't', 'a', 'l'),

    /*3.2*/
    HB_SCRIPT_BUHID = HB_TAG('B', 'u',
            'h', 'd'),
    /*3.2*/
    HB_SCRIPT_HANUNOO = HB_TAG('H', 'a', 'n', 'o'),
    /*3.2*/
    HB_SCRIPT_TAGALOG = HB_TAG('T', 'g', 'l', 'g'),
    /*3.2*/
    HB_SCRIPT_TAGBANWA = HB_TAG('T', 'a',
            'g', 'b'),

    /*4.0*/
    HB_SCRIPT_CYPRIOT = HB_TAG('C', 'p', 'r', 't'),
    /*4.0*/
    HB_SCRIPT_LIMBU = HB_TAG('L', 'i', 'm', 'b'),
    /*4.0*/
    HB_SCRIPT_LINEAR_B = HB_TAG('L', 'i',
            'n', 'b'),
    /*4.0*/
    HB_SCRIPT_OSMANYA = HB_TAG('O', 's', 'm', 'a'),
    /*4.0*/
    HB_SCRIPT_SHAVIAN = HB_TAG('S', 'h', 'a', 'w'),
    /*4.0*/
    HB_SCRIPT_TAI_LE = HB_TAG('T', 'a', 'l',
            'e'),
    /*4.0*/
    HB_SCRIPT_UGARITIC = HB_TAG('U', 'g', 'a', 'r'),

    /*4.1*/
    HB_SCRIPT_BUGINESE = HB_TAG('B', 'u', 'g', 'i'),
    /*4.1*/
    HB_SCRIPT_COPTIC = HB_TAG('C', 'o', 'p',
            't'),
    /*4.1*/
    HB_SCRIPT_GLAGOLITIC = HB_TAG('G', 'l', 'a', 'g'),
    /*4.1*/
    HB_SCRIPT_KHAROSHTHI = HB_TAG('K', 'h', 'a', 'r'),
    /*4.1*/
    HB_SCRIPT_NEW_TAI_LUE = HB_TAG('T', 'a', 'l', 'u'),
    /*4.1*/
    HB_SCRIPT_OLD_PERSIAN = HB_TAG('X', 'p', 'e', 'o'),
    /*4.1*/
    HB_SCRIPT_SYLOTI_NAGRI = HB_TAG('S', 'y', 'l',
            'o'),
    /*4.1*/
    HB_SCRIPT_TIFINAGH = HB_TAG('T', 'f', 'n', 'g'),

    /*5.0*/
    HB_SCRIPT_BALINESE = HB_TAG('B', 'a', 'l', 'i'),
    /*5.0*/
    HB_SCRIPT_CUNEIFORM = HB_TAG('X', 's',
            'u', 'x'),
    /*5.0*/
    HB_SCRIPT_NKO = HB_TAG('N', 'k', 'o', 'o'),
    /*5.0*/
    HB_SCRIPT_PHAGS_PA = HB_TAG('P', 'h', 'a', 'g'),
    /*5.0*/
    HB_SCRIPT_PHOENICIAN = HB_TAG('P',
            'h', 'n', 'x'),

    /*5.1*/
    HB_SCRIPT_CARIAN = HB_TAG('C', 'a', 'r', 'i'),
    /*5.1*/
    HB_SCRIPT_CHAM = HB_TAG('C', 'h', 'a', 'm'),
    /*5.1*/
    HB_SCRIPT_KAYAH_LI = HB_TAG('K', 'a',
            'l', 'i'),
    /*5.1*/
    HB_SCRIPT_LEPCHA = HB_TAG('L', 'e', 'p', 'c'),
    /*5.1*/
    HB_SCRIPT_LYCIAN = HB_TAG('L', 'y', 'c', 'i'),
    /*5.1*/
    HB_SCRIPT_LYDIAN = HB_TAG('L', 'y',
            'd', 'i'),
    /*5.1*/
    HB_SCRIPT_OL_CHIKI = HB_TAG('O', 'l', 'c', 'k'),
    /*5.1*/
    HB_SCRIPT_REJANG = HB_TAG('R', 'j', 'n', 'g'),
    /*5.1*/
    HB_SCRIPT_SAURASHTRA = HB_TAG('S', 'a',
            'u', 'r'),
    /*5.1*/
    HB_SCRIPT_SUNDANESE = HB_TAG('S', 'u', 'n', 'd'),
    /*5.1*/
    HB_SCRIPT_VAI = HB_TAG('V', 'a', 'i', 'i'),

    /*5.2*/
    HB_SCRIPT_AVESTAN = HB_TAG('A', 'v', 's', 't'),
    /*5.2*/
    HB_SCRIPT_BAMUM = HB_TAG('B', 'a', 'm', 'u'),
    /*5.2*/
    HB_SCRIPT_EGYPTIAN_HIEROGLYPHS = HB_TAG('E', 'g', 'y', 'p'),
    /*5.2*/
    HB_SCRIPT_IMPERIAL_ARAMAIC = HB_TAG('A', 'r', 'm', 'i'),
    /*5.2*/
    HB_SCRIPT_INSCRIPTIONAL_PAHLAVI = HB_TAG('P', 'h', 'l', 'i'),
    /*5.2*/
    HB_SCRIPT_INSCRIPTIONAL_PARTHIAN = HB_TAG('P', 'r', 't', 'i'),
    /*5.2*/
    HB_SCRIPT_JAVANESE = HB_TAG('J',
            'a', 'v', 'a'),
    /*5.2*/
    HB_SCRIPT_KAITHI = HB_TAG('K', 't', 'h', 'i'),
    /*5.2*/
    HB_SCRIPT_LISU = HB_TAG('L', 'i', 's', 'u'),
    /*5.2*/
    HB_SCRIPT_MEETEI_MAYEK = HB_TAG('M', 't', 'e', 'i'),
    /*5.2*/
    HB_SCRIPT_OLD_SOUTH_ARABIAN = HB_TAG('S', 'a', 'r', 'b'),
    /*5.2*/
    HB_SCRIPT_OLD_TURKIC = HB_TAG('O', 'r', 'k',
            'h'),
    /*5.2*/
    HB_SCRIPT_SAMARITAN = HB_TAG('S', 'a', 'm', 'r'),
    /*5.2*/
    HB_SCRIPT_TAI_THAM = HB_TAG('L', 'a', 'n', 'a'),
    /*5.2*/
    HB_SCRIPT_TAI_VIET = HB_TAG('T', 'a',
            'v', 't'),

    /*6.0*/
    HB_SCRIPT_BATAK = HB_TAG('B', 'a', 't', 'k'),
    /*6.0*/
    HB_SCRIPT_BRAHMI = HB_TAG('B', 'r', 'a', 'h'),
    /*6.0*/
    HB_SCRIPT_MANDAIC = HB_TAG('M', 'a', 'n', 'd'),

    /*6.1*/
    HB_SCRIPT_CHAKMA = HB_TAG('C', 'a', 'k', 'm'),
    /*6.1*/
    HB_SCRIPT_MEROITIC_CURSIVE = HB_TAG('M', 'e', 'r', 'c'),
    /*6.1*/
    HB_SCRIPT_MEROITIC_HIEROGLYPHS = HB_TAG('M', 'e', 'r', 'o'),
    /*6.1*/
    HB_SCRIPT_MIAO = HB_TAG('P', 'l', 'r',
            'd'),
    /*6.1*/
    HB_SCRIPT_SHARADA = HB_TAG('S', 'h', 'r', 'd'),
    /*6.1*/
    HB_SCRIPT_SORA_SOMPENG = HB_TAG('S', 'o', 'r', 'a'),
    /*6.1*/
    HB_SCRIPT_TAKRI = HB_TAG('T', 'a', 'k', 'r'),

    /*7.0*/
    HB_SCRIPT_BASSA_VAH = HB_TAG('B', 'a', 's', 's'),
    /*7.0*/
    HB_SCRIPT_CAUCASIAN_ALBANIAN = HB_TAG('A', 'g',
            'h', 'b'),
    /*7.0*/
    HB_SCRIPT_DUPLOYAN = HB_TAG('D', 'u', 'p', 'l'),
    /*7.0*/
    HB_SCRIPT_ELBASAN = HB_TAG('E', 'l', 'b', 'a'),
    /*7.0*/
    HB_SCRIPT_GRANTHA = HB_TAG('G', 'r',
            'a', 'n'),
    /*7.0*/
    HB_SCRIPT_KHOJKI = HB_TAG('K', 'h', 'o', 'j'),
    /*7.0*/
    HB_SCRIPT_KHUDAWADI = HB_TAG('S', 'i', 'n', 'd'),
    /*7.0*/
    HB_SCRIPT_LINEAR_A = HB_TAG('L', 'i', 'n',
            'a'),
    /*7.0*/
    HB_SCRIPT_MAHAJANI = HB_TAG('M', 'a', 'h', 'j'),
    /*7.0*/
    HB_SCRIPT_MANICHAEAN = HB_TAG('M', 'a', 'n', 'i'),
    /*7.0*/
    HB_SCRIPT_MENDE_KIKAKUI = HB_TAG('M',
            'e', 'n', 'd'),
    /*7.0*/
    HB_SCRIPT_MODI = HB_TAG('M', 'o', 'd', 'i'),
    /*7.0*/
    HB_SCRIPT_MRO = HB_TAG('M', 'r', 'o', 'o'),
    /*7.0*/
    HB_SCRIPT_NABATAEAN = HB_TAG('N', 'b', 'a', 't'),
    /*7.0*/
    HB_SCRIPT_OLD_NORTH_ARABIAN = HB_TAG('N', 'a', 'r', 'b'),
    /*7.0*/
    HB_SCRIPT_OLD_PERMIC = HB_TAG('P', 'e', 'r',
            'm'),
    /*7.0*/
    HB_SCRIPT_PAHAWH_HMONG = HB_TAG('H', 'm', 'n', 'g'),
    /*7.0*/
    HB_SCRIPT_PALMYRENE = HB_TAG('P', 'a', 'l', 'm'),
    /*7.0*/
    HB_SCRIPT_PAU_CIN_HAU = HB_TAG('P', 'a', 'u', 'c'),
    /*7.0*/
    HB_SCRIPT_PSALTER_PAHLAVI = HB_TAG('P', 'h', 'l', 'p'),
    /*7.0*/
    HB_SCRIPT_SIDDHAM = HB_TAG('S', 'i', 'd',
            'd'),
    /*7.0*/
    HB_SCRIPT_TIRHUTA = HB_TAG('T', 'i', 'r', 'h'),
    /*7.0*/
    HB_SCRIPT_WARANG_CITI = HB_TAG('W', 'a', 'r', 'a'),

    /*8.0*/
    HB_SCRIPT_AHOM = HB_TAG('A', 'h', 'o', 'm'),
    /*8.0*/
    HB_SCRIPT_ANATOLIAN_HIEROGLYPHS = HB_TAG('H', 'l', 'u', 'w'),
    /*8.0*/
    HB_SCRIPT_HATRAN = HB_TAG('H', 'a', 't',
            'r'),
    /*8.0*/
    HB_SCRIPT_MULTANI = HB_TAG('M', 'u', 'l', 't'),
    /*8.0*/
    HB_SCRIPT_OLD_HUNGARIAN = HB_TAG('H', 'u', 'n', 'g'),
    /*8.0*/
    HB_SCRIPT_SIGNWRITING = HB_TAG('S', 'g',
            'n', 'w'),

    /*9.0*/
    HB_SCRIPT_ADLAM = HB_TAG('A', 'd', 'l', 'm'),
    /*9.0*/
    HB_SCRIPT_BHAIKSUKI = HB_TAG('B', 'h', 'k', 's'),
    /*9.0*/
    HB_SCRIPT_MARCHEN = HB_TAG('M', 'a',
            'r', 'c'),
    /*9.0*/
    HB_SCRIPT_OSAGE = HB_TAG('O', 's', 'g', 'e'),
    /*9.0*/
    HB_SCRIPT_TANGUT = HB_TAG('T', 'a', 'n', 'g'),
    /*9.0*/
    HB_SCRIPT_NEWA = HB_TAG('N',
            'e', 'w', 'a'),

    HB_SCRIPT_INVALID = HB_TAG_NONE,

    _HB_SCRIPT_MAX_VALUE = HB_TAG_MAX, /*< skip >*/
    _HB_SCRIPT_MAX_VALUE_SIGNED = HB_TAG_MAX_SIGNED /*< skip >*/

}

struct hb_user_data_key_t
{
    private char unused;
}

alias hb_destroy_func_t = void function(void* user_data);

// face

struct hb_face_t;
alias hb_reference_table_func_t = hb_blob_t* function(hb_face_t* face, hb_tag_t tag,
        void* user_data);

// font

struct hb_font_t;

struct hb_font_funcs_t;

struct hb_font_extents_t
{
    hb_position_t ascender;
    hb_position_t descender;
    hb_position_t line_gap;

    private hb_position_t reserved9;
    private hb_position_t reserved8;
    private hb_position_t reserved7;
    private hb_position_t reserved6;
    private hb_position_t reserved5;
    private hb_position_t reserved4;
    private hb_position_t reserved3;
    private hb_position_t reserved2;
    private hb_position_t reserved1;
}

struct hb_glyph_extents_t
{
    hb_position_t x_bearing;
    hb_position_t y_bearing;
    hb_position_t width;
    hb_position_t height;
}

alias hb_font_get_font_extents_func_t = hb_bool_t function(hb_font_t* font,
        void* font_data, hb_font_extents_t* metrics, void* user_data);
alias hb_font_get_font_h_extents_func_t = hb_font_get_font_extents_func_t;
alias hb_font_get_font_v_extents_func_t = hb_font_get_font_extents_func_t;

alias hb_font_get_nominal_glyph_func_t = hb_bool_t function(hb_font_t* font,
        void* font_data, hb_codepoint_t unicode, hb_codepoint_t* glyph, void* user_data);
alias hb_font_get_variation_glyph_func_t = hb_bool_t function(hb_font_t* font, void* font_data,
        hb_codepoint_t unicode, hb_codepoint_t variation_selector,
        hb_codepoint_t* glyph, void* user_data);

alias hb_font_get_glyph_advance_func_t = hb_position_t function(hb_font_t* font,
        void* font_data, hb_codepoint_t glyph, void* user_data);
alias hb_font_get_glyph_h_advance_func_t = hb_font_get_glyph_advance_func_t;
alias hb_font_get_glyph_v_advance_func_t = hb_font_get_glyph_advance_func_t;

alias hb_font_get_glyph_origin_func_t = hb_bool_t function(hb_font_t* font, void* font_data,
        hb_codepoint_t glyph, hb_position_t* x, hb_position_t* y, void* user_data);
alias hb_font_get_glyph_h_origin_func_t = hb_font_get_glyph_origin_func_t;
alias hb_font_get_glyph_v_origin_func_t = hb_font_get_glyph_origin_func_t;

alias hb_font_get_glyph_kerning_func_t = hb_position_t function(hb_font_t* font,
        void* font_data, hb_codepoint_t first_glyph, hb_codepoint_t second_glyph, void* user_data);
alias hb_font_get_glyph_h_kerning_func_t = hb_font_get_glyph_kerning_func_t;
alias hb_font_get_glyph_v_kerning_func_t = hb_font_get_glyph_kerning_func_t;

alias hb_font_get_glyph_extents_func_t = hb_bool_t function(hb_font_t* font,
        void* font_data, hb_codepoint_t glyph, hb_glyph_extents_t* extents, void* user_data);
alias hb_font_get_glyph_contour_point_func_t = hb_bool_t function(hb_font_t* font, void* font_data,
        hb_codepoint_t glyph, uint point_index, hb_position_t* x,
        hb_position_t* y, void* user_data);

alias hb_font_get_glyph_name_func_t = hb_bool_t function(hb_font_t* font,
        void* font_data, hb_codepoint_t glyph, char* name, uint size, void* user_data);
alias hb_font_get_glyph_from_name_func_t = hb_bool_t function(hb_font_t* font,
        void* font_data, const(char)* name, int len, /* -1 means nul-terminated */
        hb_codepoint_t* glyph, void* user_data);

// set

enum HB_SET_VALUE_INVALID = cast(hb_codepoint_t)-1;

struct hb_set_t;

// shape

struct hb_feature_t
{
    hb_tag_t tag;
    uint value;
    uint start;
    uint end;
}

// shape-plan

struct hb_shape_plan_t;

// unicode

enum hb_unicode_general_category_t
{
    HB_UNICODE_GENERAL_CATEGORY_CONTROL, /* Cc */
    HB_UNICODE_GENERAL_CATEGORY_FORMAT, /* Cf */
    HB_UNICODE_GENERAL_CATEGORY_UNASSIGNED, /* Cn */
    HB_UNICODE_GENERAL_CATEGORY_PRIVATE_USE, /* Co */
    HB_UNICODE_GENERAL_CATEGORY_SURROGATE, /* Cs */
    HB_UNICODE_GENERAL_CATEGORY_LOWERCASE_LETTER, /* Ll */
    HB_UNICODE_GENERAL_CATEGORY_MODIFIER_LETTER, /* Lm */
    HB_UNICODE_GENERAL_CATEGORY_OTHER_LETTER, /* Lo */
    HB_UNICODE_GENERAL_CATEGORY_TITLECASE_LETTER, /* Lt */
    HB_UNICODE_GENERAL_CATEGORY_UPPERCASE_LETTER, /* Lu */
    HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK, /* Mc */
    HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK, /* Me */
    HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK, /* Mn */
    HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER, /* Nd */
    HB_UNICODE_GENERAL_CATEGORY_LETTER_NUMBER, /* Nl */
    HB_UNICODE_GENERAL_CATEGORY_OTHER_NUMBER, /* No */
    HB_UNICODE_GENERAL_CATEGORY_CONNECT_PUNCTUATION, /* Pc */
    HB_UNICODE_GENERAL_CATEGORY_DASH_PUNCTUATION, /* Pd */
    HB_UNICODE_GENERAL_CATEGORY_CLOSE_PUNCTUATION, /* Pe */
    HB_UNICODE_GENERAL_CATEGORY_FINAL_PUNCTUATION, /* Pf */
    HB_UNICODE_GENERAL_CATEGORY_INITIAL_PUNCTUATION, /* Pi */
    HB_UNICODE_GENERAL_CATEGORY_OTHER_PUNCTUATION, /* Po */
    HB_UNICODE_GENERAL_CATEGORY_OPEN_PUNCTUATION, /* Ps */
    HB_UNICODE_GENERAL_CATEGORY_CURRENCY_SYMBOL, /* Sc */
    HB_UNICODE_GENERAL_CATEGORY_MODIFIER_SYMBOL, /* Sk */
    HB_UNICODE_GENERAL_CATEGORY_MATH_SYMBOL, /* Sm */
    HB_UNICODE_GENERAL_CATEGORY_OTHER_SYMBOL, /* So */
    HB_UNICODE_GENERAL_CATEGORY_LINE_SEPARATOR, /* Zl */
    HB_UNICODE_GENERAL_CATEGORY_PARAGRAPH_SEPARATOR, /* Zp */
    HB_UNICODE_GENERAL_CATEGORY_SPACE_SEPARATOR /* Zs */
}

enum hb_unicode_combining_class_t
{
    HB_UNICODE_COMBINING_CLASS_NOT_REORDERED = 0,
    HB_UNICODE_COMBINING_CLASS_OVERLAY = 1,
    HB_UNICODE_COMBINING_CLASS_NUKTA = 7,
    HB_UNICODE_COMBINING_CLASS_KANA_VOICING = 8,
    HB_UNICODE_COMBINING_CLASS_VIRAMA = 9,

    /* Hebrew */
    HB_UNICODE_COMBINING_CLASS_CCC10 = 10,
    HB_UNICODE_COMBINING_CLASS_CCC11 = 11,
    HB_UNICODE_COMBINING_CLASS_CCC12 = 12,
    HB_UNICODE_COMBINING_CLASS_CCC13 = 13,
    HB_UNICODE_COMBINING_CLASS_CCC14 = 14,
    HB_UNICODE_COMBINING_CLASS_CCC15 = 15,
    HB_UNICODE_COMBINING_CLASS_CCC16 = 16,
    HB_UNICODE_COMBINING_CLASS_CCC17 = 17,
    HB_UNICODE_COMBINING_CLASS_CCC18 = 18,
    HB_UNICODE_COMBINING_CLASS_CCC19 = 19,
    HB_UNICODE_COMBINING_CLASS_CCC20 = 20,
    HB_UNICODE_COMBINING_CLASS_CCC21 = 21,
    HB_UNICODE_COMBINING_CLASS_CCC22 = 22,
    HB_UNICODE_COMBINING_CLASS_CCC23 = 23,
    HB_UNICODE_COMBINING_CLASS_CCC24 = 24,
    HB_UNICODE_COMBINING_CLASS_CCC25 = 25,
    HB_UNICODE_COMBINING_CLASS_CCC26 = 26,

    /* Arabic */
    HB_UNICODE_COMBINING_CLASS_CCC27 = 27,
    HB_UNICODE_COMBINING_CLASS_CCC28 = 28,
    HB_UNICODE_COMBINING_CLASS_CCC29 = 29,
    HB_UNICODE_COMBINING_CLASS_CCC30 = 30,
    HB_UNICODE_COMBINING_CLASS_CCC31 = 31,
    HB_UNICODE_COMBINING_CLASS_CCC32 = 32,
    HB_UNICODE_COMBINING_CLASS_CCC33 = 33,
    HB_UNICODE_COMBINING_CLASS_CCC34 = 34,
    HB_UNICODE_COMBINING_CLASS_CCC35 = 35,

    /* Syriac */
    HB_UNICODE_COMBINING_CLASS_CCC36 = 36,

    /* Telugu */
    HB_UNICODE_COMBINING_CLASS_CCC84 = 84,
    HB_UNICODE_COMBINING_CLASS_CCC91 = 91,

    /* Thai */
    HB_UNICODE_COMBINING_CLASS_CCC103 = 103,
    HB_UNICODE_COMBINING_CLASS_CCC107 = 107,

    /* Lao */
    HB_UNICODE_COMBINING_CLASS_CCC118 = 118,
    HB_UNICODE_COMBINING_CLASS_CCC122 = 122,

    /* Tibetan */
    HB_UNICODE_COMBINING_CLASS_CCC129 = 129,
    HB_UNICODE_COMBINING_CLASS_CCC130 = 130,
    HB_UNICODE_COMBINING_CLASS_CCC133 = 132,

    HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW_LEFT = 200,
    HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW = 202,
    HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE = 214,
    HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE_RIGHT = 216,
    HB_UNICODE_COMBINING_CLASS_BELOW_LEFT = 218,
    HB_UNICODE_COMBINING_CLASS_BELOW = 220,
    HB_UNICODE_COMBINING_CLASS_BELOW_RIGHT = 222,
    HB_UNICODE_COMBINING_CLASS_LEFT = 224,
    HB_UNICODE_COMBINING_CLASS_RIGHT = 226,
    HB_UNICODE_COMBINING_CLASS_ABOVE_LEFT = 228,
    HB_UNICODE_COMBINING_CLASS_ABOVE = 230,
    HB_UNICODE_COMBINING_CLASS_ABOVE_RIGHT = 232,
    HB_UNICODE_COMBINING_CLASS_DOUBLE_BELOW = 233,
    HB_UNICODE_COMBINING_CLASS_DOUBLE_ABOVE = 234,

    HB_UNICODE_COMBINING_CLASS_IOTA_SUBSCRIPT = 240,

    HB_UNICODE_COMBINING_CLASS_INVALID = 255
}

struct hb_unicode_funcs_t;

alias hb_unicode_combining_class_func_t = hb_unicode_combining_class_t function(
        hb_unicode_funcs_t*, hb_codepoint_t, void*);
alias hb_unicode_eastasian_width_func_t = uint function(hb_unicode_funcs_t*,
        hb_codepoint_t, void*);
alias hb_unicode_general_category_func_t = hb_unicode_general_category_t function(
        hb_unicode_funcs_t*, hb_codepoint_t, void*);
alias hb_unicode_mirroring_func_t = hb_codepoint_t function(hb_unicode_funcs_t*,
        hb_codepoint_t, void*);
alias hb_unicode_script_func_t = hb_script_t function(hb_unicode_funcs_t*, hb_codepoint_t, void*);

alias hb_unicode_compose_func_t = hb_bool_t function(hb_unicode_funcs_t*,
        hb_codepoint_t, hb_codepoint_t, hb_codepoint_t*, void*);
alias hb_unicode_decompose_func_t = hb_bool_t function(hb_unicode_funcs_t*,
        hb_codepoint_t, hb_codepoint_t*, hb_codepoint_t*, void*);

alias hb_unicode_decompose_compatibility_func_t = uint function(
        hb_unicode_funcs_t*, hb_codepoint_t, hb_codepoint_t*, void*);

enum HB_UNICODE_MAX_DECOMPOSITION_LEN = 18 + 1;

// version

enum HB_VERSION_MAJOR = 1;
enum HB_VERSION_MINOR = 3;
enum HB_VERSION_MICRO = 2;

enum HB_VERSION_STRING = "1.3.2";

auto HB_VERSION_ATLEAST(U, V, W)(U major, V minor, W micro)
{
    return major * 10000 + minor * 100 + micro <= HB_VERSION_MAJOR * 10000
        + HB_VERSION_MINOR * 100 + HB_VERSION_MICRO;
}
