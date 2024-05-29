const std = @import("std");
const testing = std.testing;

// Quick helper to flip the (expect, actual) arguments to (actual, expect)
// because reading it this way makes more intuitive sense.
pub fn expectEqual(got: anytype, want: anytype) !void {
    return testing.expectEqual(want, got);
}
