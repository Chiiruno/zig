// Special Cases:
//
// - trunc(+-0)   = +-0
// - trunc(+-inf) = +-inf
// - trunc(nan)   = nan

const math = @import("index.zig");
const assert = @import("../debug.zig").assert;

pub fn trunc(x: var) -> @typeOf(x) {
    const T = @typeOf(x);
    switch (T) {
        f32 => @inlineCall(trunc32, x),
        f64 => @inlineCall(trunc64, x),
        else => @compileError("trunc not implemented for " ++ @typeName(T)),
    }
}

fn trunc32(x: f32) -> f32 {
    const u = @bitCast(u32, x);
    var e = i32(((u >> 23) & 0xFF)) - 0x7F + 9;
    var m: u32 = undefined;

    if (e >= 23 + 9) {
        return x;
    }
    if (e < 9) {
        e = 1;
    }

    m = u32(@maxValue(u32)) >> u5(e);
    if (u & m == 0) {
        x
    } else {
        math.forceEval(x + 0x1p120);
        @bitCast(f32, u & ~m)
    }
}

fn trunc64(x: f64) -> f64 {
    const u = @bitCast(u64, x);
    var e = i32(((u >> 52) & 0x7FF)) - 0x3FF + 12;
    var m: u64 = undefined;

    if (e >= 52 + 12) {
        return x;
    }
    if (e < 12) {
        e = 1;
    }

    m = u64(@maxValue(u64)) >> u6(e);
    if (u & m == 0) {
        x
    } else {
        math.forceEval(x + 0x1p120);
        @bitCast(f64, u & ~m)
    }
}

test "math.trunc" {
    assert(trunc(f32(1.3)) == trunc32(1.3));
    assert(trunc(f64(1.3)) == trunc64(1.3));
}

test "math.trunc32" {
    assert(trunc32(1.3) == 1.0);
    assert(trunc32(-1.3) == -1.0);
    assert(trunc32(0.2) == 0.0);
}

test "math.trunc64" {
    assert(trunc64(1.3) == 1.0);
    assert(trunc64(-1.3) == -1.0);
    assert(trunc64(0.2) == 0.0);
}

test "math.trunc32.special" {
    assert(trunc32(0.0) == 0.0); // 0x3F800000
    assert(trunc32(-0.0) == -0.0);
    assert(math.isPositiveInf(trunc32(math.inf(f32))));
    assert(math.isNegativeInf(trunc32(-math.inf(f32))));
    assert(math.isNan(trunc32(math.nan(f32))));
}

test "math.trunc64.special" {
    assert(trunc64(0.0) == 0.0);
    assert(trunc64(-0.0) == -0.0);
    assert(math.isPositiveInf(trunc64(math.inf(f64))));
    assert(math.isNegativeInf(trunc64(-math.inf(f64))));
    assert(math.isNan(trunc64(math.nan(f64))));
}
