const __fixunssfsi = @import("fixunssfsi.zig").__fixunssfsi;
const assert = @import("../../debug.zig").assert;

fn test__fixunssfsi(a: f32, expected: u32) {
    const x = __fixunssfsi(a);
    assert(x == expected);
}

test "fixunssfsi" {
    test__fixunssfsi(0.0, 0);

    test__fixunssfsi(0.5, 0);
    test__fixunssfsi(0.99, 0);
    test__fixunssfsi(1.0, 1);
    test__fixunssfsi(1.5, 1);
    test__fixunssfsi(1.99, 1);
    test__fixunssfsi(2.0, 2);
    test__fixunssfsi(2.01, 2);
    test__fixunssfsi(-0.5, 0);
    test__fixunssfsi(-0.99, 0);

    test__fixunssfsi(-1.0, 0);
    test__fixunssfsi(-1.5, 0);
    test__fixunssfsi(-1.99, 0);
    test__fixunssfsi(-2.0, 0);
    test__fixunssfsi(-2.01, 0);

    test__fixunssfsi(0x1.000000p+31, 0x80000000);
    test__fixunssfsi(0x1.000000p+32, 0xFFFFFFFF);
    test__fixunssfsi(0x1.FFFFFEp+31, 0xFFFFFF00);
    test__fixunssfsi(0x1.FFFFFEp+30, 0x7FFFFF80);
    test__fixunssfsi(0x1.FFFFFCp+30, 0x7FFFFF00);

    test__fixunssfsi(-0x1.FFFFFEp+30, 0);
    test__fixunssfsi(-0x1.FFFFFCp+30, 0);
}
