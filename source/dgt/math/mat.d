/// Matrix definition module
module dgt.math.mat;

import dgt.math.vec;
import dgt.core.typecons : staticRange;

import std.traits;
import std.meta : allSatisfy;
import std.exception : enforce;

alias FMat(size_t R, size_t C) = Mat!(float, R, C);
alias DMat(size_t R, size_t C) = Mat!(double, R, C);
alias IMat(size_t R, size_t C) = Mat!(int, R, C);

alias Mat2x2(T) = Mat!(T, 2, 2);
alias Mat3x3(T) = Mat!(T, 3, 3);
alias Mat4x4(T) = Mat!(T, 4, 4);
alias Mat2x3(T) = Mat!(T, 2, 3);
alias Mat2x4(T) = Mat!(T, 2, 4);
alias Mat3x4(T) = Mat!(T, 3, 4);
alias Mat3x2(T) = Mat!(T, 3, 2);
alias Mat4x2(T) = Mat!(T, 4, 2);
alias Mat4x3(T) = Mat!(T, 4, 3);

alias FMat2x2 = Mat!(float, 2, 2);
alias FMat3x3 = Mat!(float, 3, 3);
alias FMat4x4 = Mat!(float, 4, 4);
alias FMat2x3 = Mat!(float, 2, 3);
alias FMat2x4 = Mat!(float, 2, 4);
alias FMat3x4 = Mat!(float, 3, 4);
alias FMat3x2 = Mat!(float, 3, 2);
alias FMat4x2 = Mat!(float, 4, 2);
alias FMat4x3 = Mat!(float, 4, 3);

alias DMat2x2 = Mat!(double, 2, 2);
alias DMat3x3 = Mat!(double, 3, 3);
alias DMat4x4 = Mat!(double, 4, 4);
alias DMat2x3 = Mat!(double, 2, 3);
alias DMat2x4 = Mat!(double, 2, 4);
alias DMat3x4 = Mat!(double, 3, 4);
alias DMat3x2 = Mat!(double, 3, 2);
alias DMat4x2 = Mat!(double, 4, 2);
alias DMat4x3 = Mat!(double, 4, 3);

alias IMat2x2 = Mat!(int, 2, 2);
alias IMat3x3 = Mat!(int, 3, 3);
alias IMat4x4 = Mat!(int, 4, 4);
alias IMat2x3 = Mat!(int, 2, 3);
alias IMat2x4 = Mat!(int, 2, 4);
alias IMat3x4 = Mat!(int, 3, 4);
alias IMat3x2 = Mat!(int, 3, 2);
alias IMat4x2 = Mat!(int, 4, 2);
alias IMat4x3 = Mat!(int, 4, 3);

// further shortcuts
alias Mat2(T) = Mat2x2!T;
alias Mat3(T) = Mat3x3!T;
alias Mat4(T) = Mat4x4!T;
alias FMat2 = FMat2x2;
alias FMat3 = FMat3x3;
alias FMat4 = FMat4x4;
alias DMat2 = DMat2x2;
alias DMat3 = DMat3x3;
alias DMat4 = DMat4x4;
alias IMat2 = IMat2x2;
alias IMat3 = IMat3x3;
alias IMat4 = IMat4x4;

/// Row major matrix type.
/// Mat.init is a null matrix.
struct Mat(T, size_t R, size_t C)
if (isNumeric!T && R > 0 && C > 0)
{
    private T[R * C] _rep = 0;

    /// The amount of rows in the matrix.
    enum rows = R;
    /// The amount of columns in the matrix.
    enum columns = C;
    /// The matrix rows type.
    alias Row = Vec!(T, columns);
    /// The matrix columns type.
    alias Column = Vec!(T, rows);
    /// The type of the components.
    alias Component = T;

    static if (rows == columns)
    {
        /// The identity matrix.
        enum identity = mixin(identityCode);
    }

    /// Build a matrix from its elements.
    /// To be provided row major.
    this (Args...)(in Args args)
    if (Args.length == R*C &&
        allSatisfy!(isNumeric, Args) &&
        isImplicitlyConvertible!(CommonType!Args, T))
    {
        _rep = [ args ];
    }

    /// Build a matrix from the provided rows.
    /// Each row must be an array (static or dynamic) and have the correct number
    /// of elements.
    this (Args...)(in Args args)
    if (Args.length == rows && allSatisfy!(isArray, Args))
    {
        foreach (r, arg; args)
        {
            static if (isStaticArray!(typeof(arg)))
            {
                static assert(arg.length == columns);
            }
            else
            {
                assert(arg.length == columns);
            }
            _rep[r*columns .. (r+1)*columns] = arg;
        }
    }

    /// ditto
    this (Args...)(in Args args)
    if (Args.length == rows &&
        allSatisfy!(isVec, Args))
    {
        foreach(r, arg; args)
        {
            static assert(arg.length == columns, "incorrect row size");
            _rep[r*columns .. (r+1)*columns] = arg;
        }
    }

    /// Build a matrix from the provided data.
    /// data.length must be rows*columns.
    this (in T[] data)
    {
        enforce(data.length == rows*columns);
        _rep[] = data;
    }

    /// Cast a matrix to another type
    Mat!(U, rows, columns) opCast(V : Mat!(U, rows, columns), U)() const
    if (__traits(compiles, cast(U)T.init))
    {
         Mat!(U, rows, columns) res = void;
         foreach (i; staticRange!(0, rows*columns))
         {
             res._rep[i] = cast(U)_rep[i];
         }
         return res;
    }

    // compile time indexing

    /// Index a matrix component at compile time
    @property T ctComp(size_t r, size_t c)() const
    if (r < rows && c < columns)
    {
        return _rep[r*columns + c];
    }

    /// Assign a matrix component with index known at compile time
    @property void ctComp(size_t r, size_t c, U)(in U val)
    if (r < rows && c < columns && isImplicitlyConvertible!(U, T))
    {
        _rep[r*columns + c] = val;
    }

    /// Index a row at compile time
    @property Row ctRow(size_t r)() const
    if (r < rows)
    {
        return Row(_rep[r*columns .. (r+1)*columns]);
    }

    /// Assign a row with index known at compile time
    @property void ctRow(size_t r)(in Row row)
    if (r < rows)
    {
        _rep[r*columns .. (r+1)*columns] = row._rep;
    }

    /// Index a row at compile time
    @property Column ctColumn(size_t c)() const
    if (c < columns)
    {
        Column col = void;
        foreach (r; staticRange!(0, rows))
        {
            col.ctComp!r = _rep[r*columns + c];
        }
        return col;
    }

    /// Assign a column with index known at compile time
    @property void ctColumn(size_t c)(in Column column)
    if (c < columns)
    {
        foreach(r; staticRange!(0, rows))
        {
            _rep[r*columns, c] = column.ctComp!(r);
        }
    }

    /// Return a slice whose size is known at compile-time.
    @property Mat!(T, RE-RS, CE-CS) ctSlice(size_t RS, size_t RE, size_t CS, size_t CE)() const
    if (RE > RS && RE <= rows && CE > CS && CE <= columns)
    {
        Mat!(T, RE-RS, CE-CS) res = void;
        foreach (r; staticRange!(RS, RE))
        {
            foreach (c; staticRange!(CS, CE))
            {
                res.ctComp!(r-RS, c-CS) = ctComp!(r, c);
            }
        }
        return res;
    }

    /// Assign a slice whose size is known at compile-time.
    /// e.g: $(D_CODE mat.ctSlice!(0, 2) = otherMat;)
    @property void ctSlice(size_t RS, size_t CS, U, size_t UR, size_t UC)(in Mat!(U, UR, UC) mat)
    if (RS+UR <= rows && CS+UC <= columns && isImplicitlyConvertible!(U, T))
    {
        foreach (r; staticRange!(0, UR))
        {
            foreach (c; staticRange!(0, UC))
            {
                ctComp!(r+RS, c+CS) = mat.ctComp!(r, c);
            }
        }
    }


    // runtime indexing

    /// Index a matrix row.
    Row row(in size_t r) const
    {
        assert(r < rows);
        return Row(_rep[r*columns .. (r+1)*columns]);
    }

    /// Index a matrix column.
    Column column(in size_t c) const
    {
        assert(c < columns);
        Column res=void;
        foreach (r; staticRange!(0, rows))
        {
            res[r] = _rep[index(r, c)];
        }
        return res;
    }

    /// Index a matrix component
    T comp(in size_t r, in size_t c) const
    {
        return _rep[index(r, c)];
    }

    /// Build an augmented matrix (add oth to the right of this matrix)
    /// ---
    /// immutable m = IMat2(4, 5, 6, 8);
    /// assert( m ~ IMat2.identity == IMat2x4(4, 5, 1, 0, 6, 8, 0, 1));
    /// ---
    auto opBinary(string op, U, size_t UC)(in Mat!(U, rows, UC) mat) const
    if (op == "~")
    {
        alias ResMat = Mat!(CommonType!(T, U), rows, columns+UC);
        ResMat res = void;
        res.ctSlice!(0, 0) = this;
        res.ctSlice!(0, columns) = mat;
        return res;
    }

    /// Index a matrix component.
    T opIndex(in size_t r, in size_t c) const
    {
        return _rep[index(r, c)];
    }

    /// Assign a matrix component.
    void opIndexAssign(in T val, in size_t r, in size_t c)
    {
        _rep[index(r, c)] = val;
    }

    /// Apply op on a matrix component.
    void opIndexOpAssign(string op)(in T val, in size_t r, in size_t c)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        mixin("_rep[index(r, c)] "~op~"= val;");
    }

    /// Index a matrix row
    Row opIndex(in size_t r) const
    {
        return row(r);
    }

    /// Number of components per direction.
    size_t opDollar(size_t i)() const
    {
        static assert(i < 2, "A matrix only has 2 dimensions.");
        static if(i == 0)
        {
            return rows;
        }
        else
        {
            return columns;
        }
    }

    /// Add/Subtract by a matrix to its right.
    auto opBinary(string op, U)(in Mat!(U, rows, columns) oth) const
    if ((op == "+" || op == "-") && !is(CommonType!(T, U) == void))
    {
        alias ResMat = Mat!(CommonType!(T, U), rows, columns);
        ResMat res = void;
        foreach (r; staticRange!(0, rows))
        {
            foreach (c; staticRange!(0, columns))
            {
                mixin("res[r, c] = comp(r, c) "~op~" oth[r, c]");
            }
        }
        return res;
    }

    /// Multiply by a matrix to its right.
    auto opBinary(string op, U, size_t UR, size_t UC)(in Mat!(U, UR, UC) oth) const
    if (op == "*" && columns == UR && !is(CommonType!(T, U) == void))
    {
        // multiply the rows of this by the columns of oth.
        //  1 2 3     7 8     1*7 + 2*9 + 3*3   1*8 + 2*1 + 3*5
        //  4 5 6  x  9 1  =  4*7 + 5*9 + 6*3   4*8 + 5*9 + 6*3
        //            3 5
        alias ResMat = Mat!(CommonType!(T, U), rows, UC);
        ResMat res = void;
        foreach(r; staticRange!(0, rows))
        {
            foreach (c; staticRange!(0, UC))
            {
                ResMat.Component resComp = 0;
                foreach (rc; staticRange!(0, columns))
                {
                    resComp += comp(r, rc) * oth[rc, c];
                }
                res[r, c] = resComp;
            }
        }
        return res;
    }

    /// Multiply a matrix by a vector to its right.
    auto opBinary(string op, U, size_t N)(in Vec!(U, N) vec) const
    if (op == "*" && N == columns && !is(CommonType!(T, U) == void))
    {
        // import std.conv : to;
        // pragma(msg, op);
        // pragma(msg, rows.to!string);
        // pragma(msg, columns.to!string);
        // pragma(msg, N.to!string);
        // pragma(msg, "");
        // same as matrix with one column
        alias ResVec = Vec!(CommonType!(T, U), rows);
        ResVec res = void;
        foreach (r; staticRange!(0, rows))
        {
            ResVec.Component resComp = 0;
            foreach (c; staticRange!(0, columns))
            {
                resComp += comp(r, c) * vec[c];
            }
            res[r] = resComp;
        }
        return res;
    }

    /// Multiply a matrix by a vector to its left.
    auto opBinaryRight(string op, U, size_t N)(in Vec!(U, N) vec) const
    if (op == "*" && N == rows && !is(CommonType!(T, U) == void))
    {
        // same as matrix with one row
        alias ResVec = Vec!(CommonType!(T, U), columns);
        ResVec res = void;
        foreach (c; staticRange!(0, columns))
        {
            ResVec.Component resComp = 0;
            foreach (r; staticRange!(0, rows))
            {
                resComp += vec[r]*comp(r, c);
            }
            res[c] = resComp;
        }
        return res;
    }


    /// Operation of a matrix with a scalar on its right.
    auto opBinary(string op, U)(in U val) const
    if ((op == "+" || op == "-" || op == "*" || op == "/") &&
        !is(CommonType!(T, U) == void))
    {
        alias ResMat = Mat!(CommonType!(T, U), rows, columns);
        ResMat mat = void;
        foreach (r; staticRange!(0, rows))
        {
            foreach (c; staticRange!(0, columns))
            {
                mixin("res.ctComp!(r, c) = ctComp!(r, c) "~op~" val;");
            }
        }
        return res;
    }

    /// Operation of a matrix with a scalar on its left.
    auto opBinaryRight(string op, U)(in U val) const
    if ((op == "+" || op == "-" || op == "*" || op == "/") &&
        !is(CommonType!(T, U) == void))
    {
        alias ResMat = Mat!(CommonType!(T, U), rows, columns);
        ResMat mat = void;
        foreach (r; staticRange!(0, rows))
        {
            foreach (c; staticRange!(0, columns))
            {
                mixin("res.ctComp!(r, c) = val "~op~" ctComp!(r, c);");
            }
        }
        return res;
    }

    /// Assign operation of a matrix with a scalar on its right.
    auto opOpAssign(string op, U)(in U val)
    if ((op == "+" || op == "-" || op == "*" || op == "/") &&
        !is(CommonType!(T, U) == void))
    {
        foreach (r; staticRange!(0, rows))
        {
            foreach (c; staticRange!(0, columns))
            {
                mixin("_rep[r*columns+c] "~op~"= val;");
            }
        }
        return res;
    }


    string toString() const
    {
        /// [
        ///     [      1.0000,       2.0000 ],
        ///     [      3.0000,       4.0000 ]
        /// ]
        import std.format : format;
        string res = "[\n";
        foreach (r; staticRange!(0, rows))
        {
            static if (isFloatingPoint!T)
            {
                enum fmt = "   [ %(%#10.4f%|, %) ]";
            }
            else
            {
                enum fmt = "   [ %(% 10s%|, %) ]";
            }
            res ~= format(fmt, _rep[r*columns .. (r+1)*columns]);
            if (r != rows-1) res ~= ",\n";
            else res ~= "\n";
        }
        return res ~ "]";
    }

    private static size_t index(in size_t r, in size_t c)
    {
        assert(r < rows && c < columns);
        return r * columns + c;
    }

    private static @property string identityCode()
    {
        string code = "Mat (";
        foreach (r; 0 .. rows)
        {
            foreach (c; 0 .. columns)
            {
                code ~= r == c ? "1, " : "0, ";
            }
        }
        return code ~ ")";
    }
}

/// Give the transposed form of a matrix.
template transpose(T, size_t R, size_t C)
{
    @property Mat!(T, C, R) transpose(in Mat!(T, R, C) mat)
    {
        Mat!(T, C, R) res = void;
        foreach (r; staticRange!(0, R))
        {
            foreach (c; staticRange!(0, C))
            {
                res[c, r] = mat[r, c];
            }
        }
        return res;
    }
}


/// Check whether MatT is a Mat
template isMat(MatT)
{
    import std.traits : TemplateOf;
    enum isMat = __traits(isSame, TemplateOf!MatT, Mat);
}

/// Check whether MatT is a Mat
template isMat(size_t R, size_t C, MatT)
{
    import std.traits : TemplateOf;
    enum isMat = isMat!MatT && MatT.rows == R && MatT.columns == C;
}

/// Compute the determinant of a matrix.
template determinant(T)
{
    @property T determinant(in Mat2!T mat)
    {
        return mat[0, 0]*mat[1, 1] - mat[0, 1]*mat[1, 0];
    }
    @property T determinant(in Mat3!T mat)
    {
        return mat[0, 0] * determinant(Mat2!T(mat[1, 1], mat[1, 2], mat[2, 1], mat[2, 2]))
            - mat[1, 0] * determinant(Mat2!T(mat[0, 1], mat[0, 2], mat[2, 1], mat[2, 2]))
            + mat[2, 0] * determinant(Mat2!T(mat[0, 1], mat[0, 2], mat[1, 1], mat[1, 2]));
    }
    @property T determinant(in Mat4!T mat)
    {
        return mat[0, 0] * determinant(Mat3!T(
            mat[1, 1], mat[1, 2], mat[1, 3],
            mat[2, 1], mat[2, 2], mat[2, 3],
            mat[3, 1], mat[3, 2], mat[3, 3],
        ))
        - mat[1, 0] * determinant(Mat3!T(
            mat[0, 1], mat[0, 2], mat[0, 3],
            mat[2, 1], mat[2, 2], mat[2, 3],
            mat[3, 1], mat[3, 2], mat[3, 3],
        ))
        + mat[2, 0] * determinant(Mat3!T(
            mat[0, 1], mat[0, 2], mat[0, 3],
            mat[1, 1], mat[1, 2], mat[1, 3],
            mat[3, 1], mat[3, 2], mat[3, 3],
        ))
        - mat[2, 0] * determinant(Mat3!T(
            mat[0, 1], mat[0, 2], mat[0, 3],
            mat[1, 1], mat[1, 2], mat[1, 3],
            mat[2, 1], mat[2, 2], mat[2, 3],
        ));
    }
}

/// Compute the inverse of a matrix.
/// Complexity O(n3).
template inverse (T, size_t N)
if (isFloatingPoint!T)
{
    @property Mat!(T, N, N) inverse(in Mat!(T, N, N) mat)
    {
        // Gaussian elimination method
        auto pivot = mat ~ Mat!(real, N, N).identity;
        static assert(is(pivot.Component == real));
        ptrdiff_t pivotR = -1;
        foreach (c; staticRange!(0, N))
        {
            // find the max row of column c.
            auto colMax = pivot[pivotR+1, c];
            ptrdiff_t maxR = pivotR+1;
            foreach (r; pivotR+2 .. N)
            {
                immutable val = pivot[r, c];
                if (val > colMax)
                {
                    maxR = r;
                    colMax = val;
                }
            }
            if (colMax != 0)
            {
                pivotR += 1;
                // normalizing the row where the max was found
                foreach (cc; staticRange!(0, 2*N))
                {
                    pivot[maxR, cc] /= colMax;
                }
                // switching pivot row with the max row
                if (pivotR != maxR)
                {
                    foreach (cc; staticRange!(0, 2*N))
                    {
                        immutable swapTmp = pivot[maxR, cc];
                        pivot[maxR, cc] = pivot[pivotR, cc];
                        pivot[pivotR, cc] = swapTmp;
                    }
                }
                foreach (r; staticRange!(0, N))
                {
                    if (r != pivotR)
                    {
                        immutable fact = pivot.ctComp!(r, c);
                        if (fact != 0)
                        {
                            foreach (cc; staticRange!(0, 2*N))
                            {
                                pivot.ctComp!(r, cc) = pivot.ctComp!(r, cc) - fact * pivot[pivotR, cc];
                            }
                        }
                    }
                }
            }
        }
        return cast(Mat!(T, N, N)) pivot.ctSlice!(0, N, N, 2*N);
    }
}


import dgt.math.approx : approxUlp;

///
unittest
{
    assert(approxUlp(FMat2x2.identity, FMat2x2(
        1, 0,
        0, 1
    )));
}

///
unittest
{
    immutable ml = Mat!(float, 2, 3)(
        1, 2, 3,
        4, 5, 6,
    );
    immutable mr = Mat!(float, 3, 2)(
        1, 2,
        3, 4,
        5, 6,
    );
    immutable exp = Mat!(float, 2, 2)(
        1+6+15,  2+8+18,
        4+15+30, 8+20+36
    );
    assert(approxUlp(ml * mr, exp));
}

///
unittest
{
    /// Example from https://en.wikipedia.org/wiki/Gaussian_elimination
    immutable m = FMat3(
        2, -1, 0,
        -1, 2, -1,
        0, -1, 2
    );
    immutable invM = inverse(m);
    assert(approxUlp(invM, FMat3(
        0.75f, 0.5f, 0.25f,
        0.5f,  1f,   0.5f,
        0.25f, 0.5f, 0.75f
    )));
    assert(approxUlp(inverse(invM), m));
}
