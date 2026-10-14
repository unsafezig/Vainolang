export fn f() void {
    const p: [*]u8 = @ptrFromInt(0x1000);
    _ = p;
}

// error
// vaara_strict=true
//
// :2:24: error: @ptrFromInt outside vaara block
