module dgt.math.vec;

import dgt.core.typecons : staticRange;

import std.traits;
import std.meta;
import std.typecons : Tuple, tuple;

version (unittest)
{
    import std.algorithm : equal;
}

alias Vec2(T) = Vec!(T, 2);
alias Vec3(T) = Vec!(T, 3);
alias Vec4(T) = Vec!(T, 4);

alias DVec(int N) = Vec!(double, N);
alias FVec(int N) = Vec!(float, N);
alias IVec(int N) = Vec!(int, N);

alias DVec2 = Vec!(double, 2);
alias DVec3 = Vec!(double, 3);
alias DVec4 = Vec!(double, 4);

alias FVec2 = Vec!(float, 2);
alias FVec3 = Vec!(float, 3);
alias FVec4 = Vec!(float, 4);

alias IVec2 = Vec!(int, 2);
alias IVec3 = Vec!(int, 3);
alias IVec4 = Vec!(int, 4);


/// Build a Vec whose component type and size is deducted from arguments.
auto vec(Comps...)(Comps comps)
if (Comps.length > 0 && !(Comps.length == 1 && isStaticArray!(Comps[0])))
{
    alias FlatTup = ComponentTuple!(Comps);
    alias CompType = CommonType!(typeof(FlatTup.init.expand));
    alias ResVec = Vec!(CompType, FlatTup.length);
    return ResVec (comps);
}

/// ditto
auto vec(Arr)(in Arr arr)
if (isStaticArray!Arr)
{
    alias CompType = Unqual!(typeof(arr[0]));
    alias ResVec = Vec!(CompType, Arr.length);
    return ResVec(arr);
}

///
unittest
{
    immutable v1 = vec (1, 2, 4.0, 0); // CommonType!(int, double) is double
    static assert( is(Unqual!(typeof(v1)) == DVec4) );
    assert(equal(v1.data, [1, 2, 4, 0]));

    immutable int[3] arr = [0, 1, 2];
    immutable v2 = vec (arr);
    static assert( is(Unqual!(typeof(v2)) == IVec3) );
    assert(equal(v2.data, [0, 1, 2]));
}

/// Build a Vec with specified component type T and size deducted from arguments.
template vec (T) if (isNumeric!T)
{
    auto vec (Comps...)(Comps comps)
    if (Comps.length > 0 && !(Comps.length == 1 && isStaticArray!(Comps[0])))
    {
        alias ResVec = Vec!(T, numComponents!Comps);
        return ResVec (comps);
    }
    auto vec (ArrT)(in ArrT arr)
    if (isStaticArray!ArrT)
    {
        alias ResVec = Vec!(T, ArrT.length);
        return ResVec (arr);
    }
}

/// ditto
alias dvec = vec!double;
/// ditto
alias fvec = vec!float;
/// ditto
alias ivec = vec!int;

///
unittest
{
    immutable v1 = dvec (1, 2, 4, 0); // none of the args is double
    static assert( is(Unqual!(typeof(v1)) == DVec4) );
    assert(equal(v1.data, [1, 2, 4, 0]));

    immutable int[3] arr = [0, 1, 2];
    immutable v2 = fvec(arr);
    static assert( is(Unqual!(typeof(v2)) == FVec3) );
    assert(equal(v2.data, [0, 1, 2]));

    immutable v3 = dvec (1, 2);
    immutable v4 = dvec (0, v3, 3);
    static assert( is(Unqual!(typeof(v4)) == DVec4) );
    assert(equal(v4.data, [0, 1, 2, 3]));
}

/// Build a Vec with specified size and type deducted from arguments
template vec (size_t N)
{
    auto vec (Arr)(in Arr arr)
    if (isDynamicArray!Arr)
    in
    {
        assert(arr.length == N);
    }
    body
    {
        alias CompType = Unqual!(typeof(arr[0]));
        return Vec!(CompType, N)(arr);
    }

    auto vec (T)(in T comp)
    if (isNumeric!T)
    {
        return Vec!(T, N)(comp);
    }
}

/// ditto
alias vec2 = vec!2;
/// ditto
alias vec3 = vec!3;
/// ditto
alias vec4 = vec!4;

///
unittest
{
    immutable double[] arr = [1, 2, 4, 0];  // arr.length known at runtime
    immutable v1 = vec4 (arr);             // asserts that arr.length == 4
    static assert( is(Unqual!(typeof(v1)) == DVec4) );
    assert(equal(v1.data, [1, 2, 4, 0]));

    immutable int comp = 2;
    immutable v2 = vec4 (comp);
    static assert( is(Unqual!(typeof(v2)) == IVec4) );
    assert(equal(v2.data, [2, 2, 2, 2]));
}


/// A vector type with size known at compile time suitable for linear algebra.
struct Vec(T, size_t N) if (N > 0 && isNumeric!T)
{
    package T[N] _rep = 0; // accessible from dgt.math.mat

    /// The length of the vector.
    enum length = N;
    /// The vector components type.
    alias Component = T;

    /// Build a vector from its components
    /// It can be given any combination of scalars or vecs in any order as long
    /// as the total number of components fit the size of the vector.
    this(Comps...)(in Comps comps)
    if (Comps.length > 1)
    {
        import std.conv : to;
        enum numComps = numComponents!(Comps);
        static assert(numComps == N,
            "type sequence "~Comps.stringof~" (size "~numComps.to!string~
            ") do not fit the size of "~Vec!(T, N).stringof~" (size "~N.to!string~").");

        static if (
            is(typeof([ componentTuple(comps).expand ])) &&
            isImplicitlyConvertible!(typeof([ componentTuple(comps).expand ]), typeof(_rep))
        )
        {
            _rep = [ componentTuple(comps).expand ];
        }
        else
        {
            //auto compT = componentTuple(comps);
            foreach(i, c; componentTuple(comps))
            {
                _rep[i] = cast(T)c;
            }
        }

    }

    /// Build a vector from an array.
    this(Arr)(in Arr arr)
    if (isArray!Arr)
    {
        static if (isStaticArray!Arr)
        {
            static assert(Arr.length == length);
        }
        else
        {
            assert(arr.length == length);
        }
        static if (is(typeof(arr[0]) == T))
        {
            _rep[] = arr;
        }
        else
        {
            static assert(isImplicitlyConvertible!(typeof(arr[0]), T));
            foreach (i; staticRange!(0, N))
            {
                _rep[i] = arr[i];
            }
        }
    }

    /// Build a vector with all components assigned to one value
    this(in T comp)
    {
        _rep = comp;
    }

    // Tuple representation

    /// Alias to a type sequence holding all components
    alias CompSeq = Repeat!(N, T);

    /// All components in a tuple
    @property Tuple!(CompSeq) tup() const
    {
        return Tuple!(CompSeq)(_rep);
    }

    /// Return the data of the array
    @property inout(T)[] data() inout
    {
        return _rep[];
    }

    // compile time addressing

    /// Index a vector component at compile time
    @property T ctComp(size_t i)() const
    if (i < length)
    {
        return _rep[i];
    }

    /// Assign a vector component with index known at compile time
    @property void ctComp(size_t i, U)(in U val)
    if (i < length && isImplicitlyConvertible!(U, T))
    {
        _rep[i] = val;
    }

    /// Slice a vector at compile time
    /// ---
    /// FVec2 v = FVec4.init.ctSlice!(1, 3);
    /// ---
    @property auto ctSlice(size_t istart, size_t iend)() const
    if (istart < iend && iend <= length)
    {
        return Vec!(T, iend-istart)(_rep[istart .. iend]);
    }

    /// Assign a vector slice with indices known at compile time
    @property void ctSlice(size_t istart, U, size_t UN)(in Vec!(U, UN) val)
    if (istart+UN <= length && isImplicitlyConvertible!(U, T))
    {
        _rep[istart .. istart+UN] = val._rep;
    }

    // access by component name and swizzling

    private template compNameIndex(char c)
    {
        static if (c == 'x' || c == 'r' || c == 's' || c == 'u')
        {
            enum compNameIndex = 0;
        }
        else static if (c == 'y' || c == 'g' || c == 't' || c == 'v')
        {
            enum compNameIndex =  1;
        }
        else static if (c == 'z' || c == 'b' || c == 'p')
        {
            static assert (N >= 3, "component "~c~" is only accessible with 3 or more components vectors");
            enum compNameIndex =  2;
        }
        else static if (c == 'w' || c == 'a' || c == 'q')
        {
            static assert (N >= 4, "component "~c~" is only accessible with 4 or more components vectors");
            enum compNameIndex =  3;
        }
        else
        {
            static assert (false, "component "~c~" is not recognized");
        }
    }

    /// Access the component by name.
    @property T opDispatch(string name)() const
    if (name.length == 1)
    {
        return _rep[compNameIndex!(name[0])];
    }

    /// Assign the component by name.
    @property void opDispatch(string name)(in T val)
    if (name.length == 1)
    {
        _rep[compNameIndex!(name[0])] = val;
    }

    /// Access the components by swizzling.
    @property auto opDispatch(string name)() const
    if (name.length > 1)
    {
        Vec!(T, name.length) res;
        foreach (i; staticRange!(0, name.length))
        {
            res[i] = _rep[compNameIndex!(name[i])];
        }
        return res;
    }

    /// Assign the components by swizzling.
    @property void opDispatch(string name, U, size_t num)(in Vec!(U, num) v)
    if (isImplicitlyConvertible!(U, T))
    {
        static assert(name.length == num, name~" number of components do not match with type "~(Vec!(U, num).stringof));
        foreach (i; staticRange!(0, name.length))
        {
            _rep[compNameIndex!(name[i])] = v[i];
        }
    }

    /// Cast the vector to another type of component
    auto opCast(V)() const
    if (isVec!(length, V))
    {
        V res;
        foreach (i; staticRange!(0, length))
        {
            res.ctComp!i = cast(V.Component)ctComp!i;
        }
        return res;
    }

    /// Unary "+" operation.
    Vec!(T, N) opUnary(string op : "+")() const
    {
        return this;
    }
    /// Unary "-" operation.
    Vec!(T, N) opUnary(string op : "-")() const
    {
        Vec!(T, N) res = this;
        foreach (ref v; res)
        {
            v = -v;
        }
        return res;
    }

    /// Perform a term by term assignment operation on the vector.
    ref Vec!(T, N) opOpAssign(string op, U)(in Vec!(U, N) oth)
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        foreach (i, ref v; _rep)
        {
            mixin("v " ~ op ~ "= oth[i];");
        }
        return this;
    }

    /// Perform a scalar assignment operation on the vector.
    ref Vec!(T, N) opOpAssign(string op, U)(in U val)
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        foreach (ref v; _rep)
        {
            mixin("v " ~ op ~ "= val;");
        }
        return this;
    }

    /// Perform a term by term operation on the vector.
    Vec!(T, N) opBinary(string op, U)(in Vec!(U, N) oth) const
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        Vec!(T, N) res = this;
        mixin("res " ~ op ~ "= oth;");
        return res;
    }

    /// Perform a scalar operation on the vector.
    Vec!(T, N) opBinary(string op, U)(in U val) const
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && isIntegral!U)) && isNumeric!U)
    {
        Vec!(T, N) res = this;
        mixin("res " ~ op ~ "= val;");
        return res;
    }

    /// Perform a scalar operation on the vector.
    Vec!(T, N) opBinaryRight(string op, U)(in U val) const
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        Vec!(T, N) res = void;
        foreach (i, ref r; res)
        {
            mixin("r = val " ~ op ~ " _rep[i];");
        }
        return res;
    }

    /// Foreach support.
    int opApply(int delegate(size_t i, ref T) dg)
    {
        int res;
        foreach (i, ref v; _rep)
        {
            res = dg(i, v);
            if (res)
                break;
        }
        return res;
    }

    /// Foreach support.
    int opApply(int delegate(ref T) dg)
    {
        int res;
        foreach (ref v; _rep)
        {
            res = dg(v);
            if (res)
                break;
        }
        return res;
    }

    // TODO: const opApply and foreach_reverse

    /// Index a vector component.
    T opIndex(in size_t index) const
    in
    {
        assert(index < N);
    }
    body
    {
        return _rep[index];
    }

    /// Assign a vector component.
    void opIndexAssign(in T val, in size_t index)
    in
    {
        assert(index < N);
    }
    body
    {
        _rep[index] = val;
    }

    /// Assign a vector component.
    void opIndexOpAssign(string op)(in T val, in size_t index)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    in
    {
        assert(index < N);
    }
    body
    {
        mixin("_rep[index] "~op~"= val;");
    }

    /// Slicing support
    size_t[2] opSlice(in size_t start, in size_t end) const
    {
        assert(start <= end && end <= length);
        return [ start, end ];
    }

    /// ditto
    inout(T)[] opIndex(in size_t[2] slice) inout
    {
        return _rep[slice[0] .. slice[1]];
    }

    /// ditto
    void opIndexAssign(U)(in U val, in size_t[2] slice)
    {
        assert(correctSlice(slice));
        _rep[slice[0] .. slice[1]] = val;
    }

    /// ditto
    void opIndexAssign(U)(in U[] val, in size_t[2] slice)
    {
        assert(val.length == slice[1]-slice[0] && correctSlice(slice));
        _rep[slice[0] .. slice[1]] = val;
    }

    /// ditto
    void opIndexOpAssign(string op, U)(in U val, in size_t[2] slice)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        foreach (i; slice[0]..slice[1])
        {
            mixin("_rep[i] "~op~"= val;");
        }
    }

    /// Term by term sliced assignement operation.
    void opIndexOpAssign(string op, U)(in U val, in size_t[2] slice)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        foreach (i; slice[0]..slice[1])
        {
            mixin("_rep[i] "~op~"= val;");
        }
    }

    /// End of the vector.
    size_t opDollar()
    {
        return length;
    }

    string toString() const
    {
        string res = "[ ";
        foreach(i, c; _rep)
        {
            import std.format : format;
            immutable fmt = i == length-1 ? "%s " : "%s, ";
            res ~= format(fmt, c);
        }
        return res ~ "]";
    }

    private static bool correctSlice(size_t[2] slice)
    {
        return slice[0] <= slice[1] && slice[1] <= length;
    }
}

/// Check whether VecT is a Vec
template isVec(VecT)
{
    import std.traits : TemplateOf;
    static if (is(typeof(__traits(isSame, TemplateOf!VecT, Vec))))
    {
        enum isVec = __traits(isSame, TemplateOf!VecT, Vec);
    }
    else
    {
        enum isVec = false;
    }
}

static assert( isVec!(FVec2) );
static assert( !isVec!double );

/// Check whether VecT is a Vec of size N
template isVec(size_t N, VecT)
{
    static if (is(typeof(VecT.length)))
    {
        enum isVec = isVec!VecT && VecT.length == N;
    }
    else
    {
        enum isVec = false;
    }
}

/// Check whether a char is a vector component name.
template isCompName(char c)
{
    import std.algorithm : canFind;
    enum isCompName = "xyzwrgbastpquv".canFind(c);
}

/// Check whether a string only contains vector component names.
template areCompNames(string s)
if (s.length != 0)
{
    static if (s.length == 1)
    {
        enum areCompNames = isCompName!(s[0]);
    }
    else
    {
        enum areCompNames = isCompName!(s[0]) && areCompNames!(s[1 .. $]);
    }
}

/// Build a tuple with one entry per component in the type sequence.
/// Each T can be a scalar type (hold 1 component) or a vector type.

auto componentTuple(T...)(T vals)
{
    static if (T.length == 0)
    {
        return tuple();
    }
    else static if (T.length == 1)
    {
        static if (isNumeric!(T[0]))
        {
            return tuple(vals[0]);
        }
        else static if (isVec!(T[0]))
        {
            return vals[0].tup;
        }
        else
        {
            static assert(false,
                "componentTuple only works with scalars and vecs, not with "~T.stringof);
        }
    }
    else
    {
        return tuple(componentTuple(vals[0]).expand, componentTuple(vals[1 .. $]).expand);
    }
}


/// Alias to the type of component tuple
template ComponentTuple(T...)
{
    alias ComponentTuple = typeof(componentTuple(T.init));
}

/// Get the number of component a type sequence can hold.
/// Each T can be a scalar type (hold 1 component) or a vector type.
template numComponents(T...)
{
    enum numComponents = ComponentTuple!(T).length;
}

static assert (numComponents!DVec3 == 3);
static assert (is(ComponentTuple!DVec3 == Tuple!(double, double, double)));
static assert (is(ComponentTuple!(DVec2, int, float) == Tuple!(double, double, int, float)));


static assert(isVec!FVec3);

unittest
{
    DVec3 v;

    assert(v._rep[0] == 0);
    assert(v._rep[1] == 0);
    assert(v._rep[2] == 0);

    v = DVec3(4, 5, 6);

    assert(v._rep[0] == 4);
    assert(v._rep[1] == 5);
    assert(v._rep[2] == 6);
    assert(v[1] == 5);
    assert(v.z == 6);
    assert(v[$ - 1] == 6);

    assert(-v == DVec3(-4, -5, -6));

    v.z = 2;
    v[1] = 1;
    assert(v[1] == 1);
    assert(v.z == 2);

    auto c = DVec4(0.2, 1, 0.6, 0.9);
    assert(c.r == 0.2);
    assert(c.g == 1);
    assert(c.b == 0.6);
    assert(c.a == 0.9);

    assert(c.rrwuzy == DVec!6(0.2, 0.2, 0.9, 0.2, 0.6, 1));
    c.bgra = DVec4(0.3, 0.4, 0.5, 0.6);
    assert(c.data == [0.5, 0.4, 0.3, 0.6]);
}

/// Compute the dot product of two vectors.
template dot(T, size_t N)
{
    T dot(in Vec!(T, N) v1, in Vec!(T, N) v2)
    {
        T sum = 0;
        foreach (i; staticRange!(0, N))
        {
            sum += v1[i] * v2[i];
        }
        return sum;
    }
}

/// Compute the magnitude of a vector.
/// This is not to be confused with length which gives the number of components.
template magnitude(T, size_t N)
{
    T magnitude(in Vec!(T, N) v)
    {
        import std.math : sqrt;
        return sqrt(squaredMag(v));
    }
}

/// Compute the squared magnitude of a vector.
template squaredMag(T, size_t N)
{
    T squaredMag(in Vec!(T, N) v)
    {
        T sum = 0;
        foreach (i; staticRange!(0, N))
        {
            sum += v[i] * v[i];
        }
        return sum;
    }
}

/// Compute the normalization of a vector.
template normalize(T, size_t N) if (isFloatingPoint!T)
{
    import dgt.math.approx : approxUlp;
    Vec!(T, N) normalize(in Vec!(T, N) v)
    in
    {
        assert(!approxUlp(magnitude(v), 0), "Cannot normalize a null vector.");
    }
    out (res)
    {
        assert(approxUlp(magnitude(res), 1));
    }
    body
    {
        import std.math : sqrt;
        return v / magnitude(v);
    }
}

/// Vector cross product
template cross(T)
{
    Vec!(T, 3) cross(in Vec!(T, 3) lhs, in Vec!(T, 3) rhs)
    {
        return Vec!(T, 3)(
            lhs[1]*rhs[2] - lhs[2]*rhs[1],
            lhs[2]*rhs[0] - lhs[0]*rhs[2],
            lhs[0]*rhs[1] - lhs[1]*rhs[0],
        );
    }
    Vec!(T, 7) cross(in Vec!(T, 7) lhs, in Vec!(T, 7) rhs)
    {
        return Vec!(T, 7)(
            lhs[1]*rhs[3] - lhs[3]*rhs[1] + lhs[2]*rhs[6] - lhs[6]*rhs[2] + lhs[4]*rhs[5] - lhs[5]*rhs[4],
            lhs[2]*rhs[4] - lhs[4]*rhs[2] + lhs[3]*rhs[0] - lhs[0]*rhs[3] + lhs[5]*rhs[6] - lhs[6]*rhs[5],
            lhs[3]*rhs[5] - lhs[5]*rhs[3] + lhs[4]*rhs[1] - lhs[1]*rhs[4] + lhs[6]*rhs[0] - lhs[0]*rhs[6],
            lhs[4]*rhs[6] - lhs[6]*rhs[4] + lhs[5]*rhs[2] - lhs[2]*rhs[5] + lhs[0]*rhs[1] - lhs[1]*rhs[0],
            lhs[5]*rhs[0] - lhs[0]*rhs[5] + lhs[6]*rhs[3] - lhs[3]*rhs[6] + lhs[1]*rhs[2] - lhs[2]*rhs[1],
            lhs[6]*rhs[1] - lhs[1]*rhs[6] + lhs[0]*rhs[4] - lhs[4]*rhs[0] + lhs[2]*rhs[3] - lhs[3]*rhs[2],
            lhs[0]*rhs[2] - lhs[2]*rhs[0] + lhs[1]*rhs[5] - lhs[5]*rhs[1] + lhs[3]*rhs[4] - lhs[4]*rhs[3],
        );
    }
}

static assert(DVec2.sizeof == 16);
static assert(DVec3.sizeof == 24);
static assert(DVec4.sizeof == 32);

///
unittest
{
    import dgt.math.approx : approxUlp;

    auto v1 = DVec3(12, 4, 3);
    auto v2 = DVec3(-5, 3, 7);

    assert(approxUlp(dot(v1, v2), -27));

    auto v = DVec3(3, 4, 5);
    assert(approxUlp(squaredMag(v), 50));

    assert(approxUlp(normalize(FVec3(4, 0, 0)), FVec3(1, 0, 0)));
}
