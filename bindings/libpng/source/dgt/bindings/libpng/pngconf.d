module dgt.bindings.libpng.pngconf;

import core.stdc.stdio : FILE;

alias png_uint_32 = uint;
alias png_int_32 = int;
alias png_uint_16 = ushort;
alias png_int_16 = short;
alias png_byte = ubyte;

alias png_size_t = size_t;
alias png_ptrdiff_t = ptrdiff_t;

alias png_alloc_size_t = png_size_t;

alias png_fixed_point = png_int_32;

alias png_voidp = void*;
alias png_const_voidp = const(void)*;
alias png_bytep = png_byte*;
alias png_const_bytep = const(png_byte)*;
alias png_uint_32p = png_uint_32*;
alias png_const_uint_32p = const(png_uint_32)*;
alias png_int_32p = png_int_32*;
alias png_const_int_32p = const(png_int_32)*;
alias png_uint_16p = png_uint_16*;
alias png_const_uint_16p = const(png_uint_16)*;
alias png_int_16p = png_int_16*;
alias png_const_int_16p = const(png_int_16)*;
alias png_charp = char*;
alias png_const_charp = const(char)*;
alias png_fixed_point_p = png_fixed_point*;
alias png_const_fixed_point_p = const(png_fixed_point)*;
alias png_size_tp = png_size_t*;
alias png_const_size_tp = const(png_size_t)*;

alias png_FILE_p = FILE*;

alias png_doublep = double*;
alias png_const_doublep = const(double)*;

alias png_bytepp = png_byte**;
alias png_uint_32pp = png_uint_32**;
alias png_int_32pp = png_int_32**;
alias png_uint_16pp = png_uint_16**;
alias png_int_16pp = png_int_16**;
alias png_const_charpp = const(char)**;
alias png_charpp = char**;
alias png_fixed_point_pp = png_fixed_point**;
alias png_doublepp = double**;

alias png_charppp = char***;
