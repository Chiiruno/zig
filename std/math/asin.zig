// Special Cases:
//
// - asin(+-0) = +-0
// - asin(x)   = nan if x < -1 or x > 1

const math = @import("index.zig");
const assert = @import("../debug.zig").assert;

pub const asin = asin_workaround;

// TODO issue #393
pub fn asin_workaround(x: var) -> @typeOf(x) {
    const T = @typeOf(x);
    switch (T) {
        f32 => @inlineCall(asin32, x),
        f64 => @inlineCall(asin64, x),
        else => @compileError("asin not implemented for " ++ @typeName(T)),
    }
}

fn r32(z: f32) -> f32 {
    const pS0 =  1.6666586697e-01;
    const pS1 = -4.2743422091e-02;
    const pS2 = -8.6563630030e-03;
    const qS1 = -7.0662963390e-01;

    const p = z * (pS0 + z * (pS1 + z * pS2));
    const q = 1.0 + z * qS1;
    p / q
}

fn asin32(x: f32) -> f32 {
    const pio2 = 1.570796326794896558e+00;

    const hx: u32 = @bitCast(u32, x);
    const ix: u32 = hx & 0x7FFFFFFF;

    // |x| >= 1
    if (ix >= 0x3F800000) {
        // |x| >= 1
        if (ix == 0x3F800000) {
            return x * pio2 + 0x1.0p-120;   // asin(+-1) = +-pi/2 with inexact
        } else {
            return math.nan(f32);           // asin(|x| > 1) is nan
        }
    }

    // |x| < 0.5
    if (ix < 0x3F000000) {
        // 0x1p-126 <= |x| < 0x1p-12
        if (ix < 0x39800000 and ix >= 0x00800000) {
            return x;
        } else {
            return x + x * r32(x * x);
        }
    }

    // 1 > |x| >= 0.5
    const z = (1 - math.fabs(x)) * 0.5;
    const s = math.sqrt(z);
    const fx = pio2 - 2 * (s + s * r32(z));

    if (hx >> 31 != 0) {
        -fx
    } else {
        fx
    }
}

fn r64(z: f64) -> f64 {
    const pS0: f64 =  1.66666666666666657415e-01;
    const pS1: f64 = -3.25565818622400915405e-01;
    const pS2: f64 =  2.01212532134862925881e-01;
    const pS3: f64 = -4.00555345006794114027e-02;
    const pS4: f64 =  7.91534994289814532176e-04;
    const pS5: f64 =  3.47933107596021167570e-05;
    const qS1: f64 = -2.40339491173441421878e+00;
    const qS2: f64 =  2.02094576023350569471e+00;
    const qS3: f64 = -6.88283971605453293030e-01;
    const qS4: f64 =  7.70381505559019352791e-02;

    const p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
    const q = 1.0 + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
    p / q
}

fn asin64(x: f64) -> f64 {
    const pio2_hi: f64 = 1.57079632679489655800e+00;
    const pio2_lo: f64 = 6.12323399573676603587e-17;

    const ux = @bitCast(u64, x);
    const hx = u32(ux >> 32);
    const ix = hx & 0x7FFFFFFF;

    // |x| >= 1 or nan
    if (ix >= 0x3FF00000) {
        const lx = u32(ux & 0xFFFFFFFF);

        // asin(1) = +-pi/2 with inexact
        if ((ix - 0x3FF00000) | lx == 0) {
            return x * pio2_hi + 0x1.0p-120;
        } else {
            return math.nan(f64);
        }
    }

    // |x| < 0.5
    if (ix < 0x3FE00000) {
        // if 0x1p-1022 <= |x| < 0x1p-26 avoid raising overflow
        if (ix < 0x3E500000 and ix >= 0x00100000) {
            return x;
        } else {
            return x + x * r64(x * x);
        }
    }

    // 1 > |x| >= 0.5
    const z = (1 - math.fabs(x)) * 0.5;
    const s = math.sqrt(z);
    const r = r64(z);
    var fx: f64 = undefined;

    // |x| > 0.975
    if (ix >= 0x3FEF3333) {
        fx = pio2_hi - 2 * (s + s * r)
    } else {
        const jx = @bitCast(u64, s);
        const df = @bitCast(f64, jx & 0xFFFFFFFF00000000);
        const c = (z - df * df) / (s + df);
        fx = 0.5 * pio2_hi - (2 * s * r - (pio2_lo - 2 * c) - (0.5 * pio2_hi - 2 * df));
    }

    if (hx >> 31 != 0) {
        -fx
    } else {
        fx
    }
}

test "math.asin" {
    assert(asin_workaround(f32(0.0)) == asin32(0.0));
    assert(asin_workaround(f64(0.0)) == asin64(0.0));
}

test "math.asin32" {
    const epsilon = 0.000001;

    assert(math.approxEq(f32, asin32(0.0), 0.0, epsilon));
    assert(math.approxEq(f32, asin32(0.2), 0.201358, epsilon));
    assert(math.approxEq(f32, asin32(-0.2), -0.201358, epsilon));
    assert(math.approxEq(f32, asin32(0.3434), 0.350535, epsilon));
    assert(math.approxEq(f32, asin32(0.5), 0.523599, epsilon));
    assert(math.approxEq(f32, asin32(0.8923), 1.102415, epsilon));
}

test "math.asin64" {
    const epsilon = 0.000001;

    assert(math.approxEq(f64, asin64(0.0), 0.0, epsilon));
    assert(math.approxEq(f64, asin64(0.2), 0.201358, epsilon));
    assert(math.approxEq(f64, asin64(-0.2), -0.201358, epsilon));
    assert(math.approxEq(f64, asin64(0.3434), 0.350535, epsilon));
    assert(math.approxEq(f64, asin64(0.5), 0.523599, epsilon));
    assert(math.approxEq(f64, asin64(0.8923), 1.102415, epsilon));
}

test "math.asin32.special" {
    assert(asin32(0.0) == 0.0);
    assert(asin32(-0.0) == -0.0);
    assert(math.isNan(asin32(-2)));
    assert(math.isNan(asin32(1.5)));
}

test "math.asin64.special" {
    assert(asin64(0.0) == 0.0);
    assert(asin64(-0.0) == -0.0);
    assert(math.isNan(asin64(-2)));
    assert(math.isNan(asin64(1.5)));
}
