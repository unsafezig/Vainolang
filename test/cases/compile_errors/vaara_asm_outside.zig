export fn f() void {
    asm volatile ("nop");
}

// error
// vaara_strict=true
//
// :2:5: error: assembly outside vaara block
