const std = @import("std");
const zdeck = @import("zigdeck");

pub const HandType = enum {
    Pair,
    Straight,
    // Add other hand types here as needed
};

pub fn main() !void {
    var rng = std.rand.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));

    const total = 1000;
    var handCounts: std.AutoHashMap(HandType, usize) = std.AutoHashMap(HandType, usize).init(std.heap.page_allocator);
    defer handCounts.deinit();
    std.debug.print("Evaluating {d} hands...\n\n", .{total});
    for (0..total) |_| {
        var deck = zdeck.Deck.init();
        zdeck.Deck.shuffle(&deck, &rng.random());
        const hand = getFiveCards(&deck);
        evaluateHand(hand, &handCounts);
        // std.debug.print("Hand: {any}\n\n", .{hand});
    }

    var it = handCounts.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

fn getFiveCards(deck: *zdeck.Deck) [5]zdeck.Card {
    var hand: [5]zdeck.Card = undefined;
    for (hand, 0..) |_, i| {
        hand[i] = deck.getTopCard() orelse unreachable;
    }
    return hand;
}

fn evaluateHand(hand: [5]zdeck.Card, handCounts: *std.AutoHashMap(HandType, usize)) void {
    if (containsPair(hand)) {
        const result = handCounts.get(HandType.Pair) orelse 0;
        _ = handCounts.put(HandType.Pair, result + 1) catch unreachable;
    }
    if (containsStraight(hand)) {
        const result = handCounts.get(HandType.Straight) orelse 0;
        _ = handCounts.put(HandType.Straight, result + 1) catch unreachable;
    }
    // Add checks for other hand types here
}

fn containsPair(hand: [5]zdeck.Card) bool {
    var counts: [13]u8 = [_]u8{0} ** 13; // Initialize array with zeros

    for (hand) |card| {
        const faceIndex: usize = @intFromEnum(card.face) - 1; // Convert enum to int and adjust for zero-based indexing
        counts[faceIndex] += 1;
    }

    for (counts) |count| {
        if (count >= 2) {
            return true;
        }
    }

    return false;
}

fn asc(_: void, lhs: usize, rhs: usize) bool {
    return lhs < rhs;
}

fn containsStraight(hand: [5]zdeck.Card) bool {
    var values: [5]usize = undefined;
    for (hand, 0..) |card, i| {
        values[i] = @intFromEnum(card.face);
    }

    std.mem.sort(usize, &values, {}, asc);

    // Check for a straight with Ace as high
    var isStraight = true;
    for (1..5) |i| {
        if (values[i] != values[i - 1] + 1) {
            isStraight = false;
            break;
        }
    }
    if (isStraight) return true;

    // Check for a straight with Ace as low (Ace, Two, Three, Four, Five)
    if (values[0] == 1 and values[1] == 2 and values[2] == 3 and values[3] == 4 and values[4] == 13) {
        return true;
    }

    return false;
}

test "simple test" {
    var deck = zdeck.Deck.init();
    var rng = std.rand.DefaultPrng.init(1);
    zdeck.Deck.shuffle(&deck, &rng.random());

    var hand = getFiveCards(&deck);
    std.debug.print("Hand: {any}\n", .{hand});
    try std.testing.expectEqual(true, containsPair(hand));

    hand = getFiveCards(&deck);
    std.debug.print("Hand: {any}\n", .{hand});
    try std.testing.expectEqual(true, containsPair(hand));

    hand = getFiveCards(&deck);
    std.debug.print("Hand: {any}\n", .{hand});
    try std.testing.expectEqual(false, containsPair(hand));
}
