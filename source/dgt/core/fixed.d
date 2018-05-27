module dgt.core.fixed;


alias Fixed16 = Fixed!(16, 16);
alias Fixed26_6 = Fixed!(26, 6);

struct Fixed(size_t I, size_t D)
{
    import std.traits : isFloatingPoint, isIntegral;

    enum ipart = I;
    enum dpart = D;

    static if (ipart+dpart == 8) {
        alias Rep = byte;
        private alias URep = ubyte;
    }
    else static if (ipart+dpart == 16) {
        alias Rep = short;
        private alias URep = ushort;
    }
    else static if (ipart+dpart == 32) {
        alias Rep = int;
        private alias URep = uint;
    }
    else static if (ipart+dpart == 64) {
        alias Rep = long;
        private alias URep = ulong;
    }
    else {
        import std.format : format;
        static assert (false, format("Fixed!(%s, %s) is not a suitable fixed point type.", ipart, dpart));
    }

    static assert(dpart != 0);

    enum Fixed max = Fixed(Rep.max, PrivCtor.init);
    enum Fixed min = Fixed(Rep.min, PrivCtor.init);

    private enum Rep one = 1 << dpart;
    private enum Rep half = 1 << (dpart-1);
    private enum URep dmask = one - 1;
    private enum URep imask = URep(-1) & ~dmask;
    private enum PrivCtor { _ }

    Rep rep;

    private this (in Rep rep, PrivCtor) {
        this.rep = rep;
    }

    this(T) (in T val) if (isIntegral!T) {
        rep = val * one;
    }

    this(F) (in F val) if (isFloatingPoint!F) {
        rep = cast(Rep)(val * one);
    }

    Fixed opBinary(string op)(in Fixed rhs) const {
        static if (op == "+") {
            return Fixed (rep + rhs.rep, PrivCtor.init);
        }
        else static if (op == "-") {
            return Fixed (rep - rhs.rep, PrivCtor.init);
        }
        else static if (op == "*") {
            static assert (Rep.sizeof < 8, "multiplication not available in 64bits fixed");
            return Fixed (cast(Rep)((long(rep) * long(rhs.rep)) >> dpart), PrivCtor.init);
        }
        else static if (op == "/") {
            static assert (Rep.sizeof < 8, "division not available in 64bits fixed");
            const long r = ((cast(ulong)long(rep)) << dpart) / rhs.rep;
            if (r < Fixed.min.rep) return Fixed.min;
            else if (r > Fixed.max.rep) return Fixed.max;
            return Fixed(cast(Rep)r, PrivCtor.init);
        }
        else {
            static assert(false, "unsupported Fixed operator: "~op);
        }
    }


    Fixed opBinary(string op)(in Rep rhs) const {
        static if (op == "+") {
            return Fixed (rep + cast(Rep)(cast(URep)(rhs)<<dpart), PrivCtor.init);
        }
        else static if (op == "-") {
            return Fixed (rep - cast(Rep)(cast(URep)(rhs)<<dpart), PrivCtor.init);
        }
        else static if (op == "*") {
            return Fixed (rep * rhs, PrivCtor.init);
        }
        else static if (op == "/") {
            return Fixed (rep / rhs, PrivCtor.init);
        }
        else {
            static assert(false, "unsupported Fixed operator: "~op);
        }
    }

    Fixed opBinary(string op, F)(in F rhs) const if (isFloatingPoint!F) {
        return opBinary!(op)(Fixed(rhs));
    }

    int opCmp(in Fixed rhs) const {
        if (rep < rhs.rep) {
            return -1;
        }
        else if (rep > rhs.rep) {
            return 1;
        }
        else {
            return 0;
        }
    }

    @property Rep asRoundedInt() const {
        return (rep + half) >> dpart;
    }

    @property Rep asCeiledInt() const {
        return (rep + one - 1) >> dpart;
    }

    @property Rep asFlooredInt() const {
        return rep >> dpart;
    }

    @property F as(F)() const if(isFloatingPoint!F) {
        return rep / cast(F)one;
    }
}

template isFixed(F) {
    import std.traits : TemplateOf;
    enum isFixed = __traits(isSame, TemplateOf!F, Fixed);
}

F ceil(F)(in F val) if(isFixed!F) {
    F f = void;
    f.rep = (val.rep + F.half) & F.imask;
    return f;
}

F round(F)(in F val) if(isFixed!F) {
    F f = void;
    f.rep = (val.rep + F.one - 1) & F.imask;
    return f;
}

F floor(F)(in F val) if(isFixed!F) {
    F f = void;
    f.rep = val.rep & F.imask;
    return rep;
}

///
unittest {
    const f = Fixed16(54.7);
    assert(f + 10.5 == Fixed16(54.7+10.5));
}
