const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const test_helpers = @import("test.zig");

pub fn Node(comptime T: type, capacity: usize) type {
    return struct {
        allocator: Allocator,
        keys: std.ArrayList(T),
        children: std.ArrayList(*T),

        const Self = @This();

        fn init(allocator: Allocator) !Self {
            return Self{
                .allocator = allocator,
                .keys = try std.ArrayList(T).initCapacity(allocator, capacity),
                .children = std.ArrayList(*T).init(allocator),
            };
        }

        fn deinit(self: *Self) void {
            self.keys.deinit();
            self.children.deinit();
        }

        fn isLeaf(self: *Self) bool {
            return self.children.capacity == 0;
        }

        fn isFull(self: *Self) bool {
            return self.keys.items.len == self.keys.capacity;
        }

        // lookupKeyIndex searches for target in the node and returns its index.
        // If it does not exist, it returns the position where this key should be
        // inserted.
        //
        // NOTE: Its answer does not take into account if the node is already
        // full. Checking available capacity is the responsibility of the
        // caller.
        fn lookupKeyIndex(self: *Self, target: T) struct { exists: bool, value: usize } {
            // Early return if the node is empty. Also, length being of type
            // usize, we cannot have a negative value. This check is required to
            // avoid an overflow for calculating the initial value of high.
            // if (self.keys.items.len == 0) {
            //     return .{ .exists = false, .value = 0 };
            // }

            var low: usize = 0;
            var high = self.keys.items.len;
            while (low < high) {
                const mid = (high - low) / 2 + low;
                if (target == self.keys.items[mid]) {
                    return .{ .exists = true, .value = mid };
                }

                if (target < self.keys.items[mid]) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }

            return .{ .exists = false, .value = low };
        }

        fn insert(self: *Self, target: T) !void {
            if (self.isFull()) {
                return error.NodeFull;
            }

            const key_index = self.lookupKeyIndex(target);
            if (key_index.exists) {
                return error.KeyAlreadyExists;
            }

            self.keys.insertAssumeCapacity(key_index.value, target);
        }
    };
}

const NodeAccessError = error{
    NodeFull,
    KeyAlreadyExists,
};

test "Node init" {
    var node = try Node(i8, 2).init(testing.allocator);
    defer node.deinit();

    // Verify state when a node is initialised.
    try test_helpers.expectEqual(node.keys.capacity, 2);
    try test_helpers.expectEqual(node.children.capacity, 0);
    try test_helpers.expectEqual(node.isLeaf(), true);
    try test_helpers.expectEqual(node.isFull(), false);
}

test "Node isLeaf" {
    var node = try Node(i8, 2).init(testing.allocator);
    defer node.deinit();

    try test_helpers.expectEqual(node.isLeaf(), true);

    // TODO: Add tests when we have abilities to connect nodes in a tree.
    return error.SkipZigTest;
}

test "Node isFull" {
    var node = try Node(i8, 2).init(testing.allocator);
    defer node.deinit();

    try testing.expectEqual(false, node.isFull());
}

test "Node lookupKeyIndex" {
    var node = try Node(i8, 9).init(testing.allocator);
    defer node.deinit();

    // Attempt a lookup in an empty node.
    {
        const key_index = node.lookupKeyIndex(10);
        try test_helpers.expectEqual(key_index.exists, false);
        try test_helpers.expectEqual(key_index.value, 0);
    }

    try node.keys.appendSlice(&[_]i8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 });

    const items = node.keys.items;
    for (0..items.len) |i| {
        const key_index = node.lookupKeyIndex(items[i]);
        try test_helpers.expectEqual(key_index.exists, true);
        try test_helpers.expectEqual(key_index.value, i);
    }

    // Try looking up a value that should be inserted at the start even though the
    // node is full.
    //
    // The rationale is that lookupKeyIndex does not care if the node is already
    // full, it merely suggests where the ideal placement of the key should be
    // in the node.
    {
        const key_index = node.lookupKeyIndex(0);
        try test_helpers.expectEqual(key_index.exists, false);
        try test_helpers.expectEqual(key_index.value, 0);
    }

    // Similar to the above, try looking up a value that should be inserted at
    // the end even though the node is full.
    {
        const key_index = node.lookupKeyIndex(10);
        try test_helpers.expectEqual(key_index.exists, false);
        try test_helpers.expectEqual(key_index.value, 9);
    }
}

test "Node insert" {
    var node = try Node(i8, 5).init(testing.allocator);
    defer node.deinit();

    // Verify we are starting with no items.
    try testing.expectEqualSlices(i8, &[0]i8{}, node.keys.items);

    try node.insert(3);
    try testing.expectEqualSlices(i8, &[1]i8{3}, node.keys.items);

    try testing.expectError(error.KeyAlreadyExists, node.insert(3));

    try node.insert(10);
    try testing.expectEqualSlices(i8, &[2]i8{ 3, 10 }, node.keys.items);
    try node.insert(6);
    try testing.expectEqualSlices(i8, &[3]i8{ 3, 6, 10 }, node.keys.items);
    try node.insert(12);
    try testing.expectEqualSlices(i8, &[4]i8{ 3, 6, 10, 12 }, node.keys.items);
    try node.insert(1);
    try testing.expectEqualSlices(i8, &[5]i8{ 1, 3, 6, 10, 12 }, node.keys.items);

    try testing.expectEqual(error.NodeFull, node.insert(1));
}
