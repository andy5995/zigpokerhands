const std = @import("std");
const zdeck = @import("zigdeck");

pub fn main() !void {
    var deck = zdeck.Deck.init();
    var rng = std.rand.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));
    zdeck.Deck.shuffle(&deck, &rng.random());

    const hand = getFiveCards(&deck);
    const hasPair = containsPair(hand);
    std.debug.print("Hand: {}\n", .{hand});
    std.debug.print("Contains a pair: {}\n", .{hasPair});
}

fn getFiveCards(deck: *zdeck.Deck) [5]zdeck.Card {
    var hand: [5]zdeck.Card = undefined;
    for (hand[0..]) |i| {
        hand[i] = deck.getTopCard() orelse unreachable;
    }
    return hand;
}

fn containsPair(hand: [5]zdeck.Card) bool {
    var counts: [13]u4 = undefined;
    for (counts[0..]) |i| {
        counts[i] = 0;
    }

    for (hand[0..]) |card| {
        counts[card.value - 1] += 1;
    }

    for (counts[0..]) |count| {
        if (count >= 2) {
            return true;
        }
    }

    return false;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
