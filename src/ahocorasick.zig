//! Aho-Corasick algorithm implementation with a trie of unsigned bytes
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");

pub fn AhoCorasick() type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            end:          bool,
            next:         [256]?*Node,
            failure_link: ?*Node,

            fn init(allocator: std.mem.Allocator) !*Node {
                const node = try allocator.create(Node);
                node.* = .{ .end = false, .next = [_]?*Node{null} ** 256, .failure_link = null };
                return node;
            }
        };

        allocator: std.mem.Allocator,
        root:      *Node,
        current:   *Node,

        pub fn start(self: *Self) void { self.current = self.root; }

        pub fn initEmpty(alloc: std.mem.Allocator) !Self {
            // Creates root node
            const root_node: *Node = try Node.init(alloc);
            root_node.failure_link = root_node;
            return Self { .allocator = alloc, .root = root_node, .current = root_node };
        }

        pub fn add(self: *Self, data: []const u8) !void {
            errdefer self.deinit();
            if (data.len == 0) return;

            self.current = self.root;
            for (data) |byte| {
                if (self.current.next[byte] == null) {
                    self.current.next[byte] = try Node.init(self.allocator);
                }
                self.current = self.current.next[byte].?;
            }
            self.current.end = true;
        }

        /// Configures failure links
        pub fn configure(self: *const Self) !void {
            var deque: std.Deque(*Node) = .empty;
            defer deque.deinit(self.allocator);

            // First level returns to root
            for (0..256) |i| {
                if (self.root.next[i]) |node| {
                    node.failure_link = self.root;
                    try deque.pushBack(self.allocator, node);
                }
            }

            // Loops while queue is not empty
            while (true) {
                const node: ?*Node = deque.popFront() orelse return;

                // Adds all node childs in queue
                for (0..256) |i| {
                  if (node.?.next[i]) |child| {
                        try deque.pushBack(self.allocator, child);

                        // Finds the deepest node reachable via failure links that has a transition
                        var failure_link: ?*Node = node.?.failure_link.?;
                        while (failure_link != self.root and failure_link.?.next[i] == null)
                            failure_link = failure_link.?.failure_link;

                        // Sets failure link
                        if (failure_link.?.next[i]) |target| {
                            if (target != child) {
                                child.failure_link = target;
                                continue;
                            }
                        }
                        child.failure_link = self.root;
                    }
                }
            }
        }

        pub fn init(alloc: std.mem.Allocator, patterns: []const []const u8) !Self {
            // Creates root node
            var ahocorasick = try AhoCorasick().initEmpty(alloc);

            // Creates the trie adding data
            for (patterns) |pattern| { try ahocorasick.add(pattern); }

            // Set failure links
            try ahocorasick.configure();

            return ahocorasick;
        }

        pub fn deinit(self: *Self) void { self.destroyNode(self.root); }

        fn destroyNode(self: *Self, node: *Node) void {
            for (node.next) |child_opt| {
                if (child_opt) |child| { self.destroyNode(child); }
            }
            self.allocator.destroy(node);
        }

        pub fn contains(self: *Self, data: []const u8) bool {
            self.current = self.root;
            return self.containsBuffer(data);
        }

        pub fn containsBuffer(self: *Self, buffer: []const u8) bool {
            for (buffer) |byte| {
                while (self.current != self.root and self.current.next[byte] == null)
                    self.current = self.current.failure_link.?;

                if (self.current.next[byte]) |next_node| { self.current = next_node; }
                if (self.current.end) return true;
            }
            return false;
        }
    };
}

test "Pattern matching" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{ "He", "Hers", "His", "She" });
    defer ac.deinit();

    try std.testing.expect(ac.contains("serHtSheetr"));
    try std.testing.expect(ac.contains("He"));
    try std.testing.expect(ac.contains("She"));
    try std.testing.expect(ac.contains("His"));
    try std.testing.expect(!ac.contains("xyz"));
    try std.testing.expect(!ac.contains(""));
}

test "Overlapping patterns" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{ "he", "she", "his", "hers" });
    defer ac.deinit();

    // "ushers" contains both "she" and "he" and "hers"
    try std.testing.expect(ac.contains("ushers"));
}

test "Start and end" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{"abc"});
    defer ac.deinit();

    try std.testing.expect(ac.contains("abc"));
    try std.testing.expect(ac.contains("abcdef"));
    try std.testing.expect(ac.contains("xyzabc"));
    try std.testing.expect(ac.contains("xyzabcdef"));
}

test "Single character patterns" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{ "a", "b", "c" });
    defer ac.deinit();

    try std.testing.expect(ac.contains("abc"));
    try std.testing.expect(ac.contains("xyz a xyz"));
    try std.testing.expect(!ac.contains("xyz"));
}

test "No matches" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{ "foo", "bar" });
    defer ac.deinit();

    try std.testing.expect(!ac.contains("baz"));
}

test "Empty pattern list" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{});
    defer ac.deinit();

    try std.testing.expect(!ac.contains("anything"));
}

test "Suffix patterns" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // "ers" is a suffix of "hers"
    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{ "hers", "ers" });
    defer ac.deinit();

    try std.testing.expect(ac.contains("hers")); // Should match both patterns
    try std.testing.expect(ac.contains("ers"));
    try std.testing.expect(ac.contains("others")); // Should match "ers"
}

test "Nested overlaps" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ac = try AhoCorasick().init(gpa.allocator(), &[_][]const u8{ "a", "aa", "aaa" });
    defer ac.deinit();

    try std.testing.expect(ac.contains("aaa")); // Should detect at least one match
    try std.testing.expect(ac.contains("baaab"));
}
