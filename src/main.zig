const std = @import("std");
const zdeck = @import("zigdeck");

pub fn main() !void {
    var rng = std.rand.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));

    const total = 20;
    var counter: usize = 0;
    for (0..total) |_| {
        var deck = zdeck.Deck.init();
        zdeck.Deck.shuffle(&deck, &rng.random());
        const hand = getFiveCards(&deck);
        const hasPair = containsPair(hand);

        if (hasPair) {
            counter += 1;
        }
        std.debug.print("Hand: {any}\n\n", .{hand});
    }

    std.debug.print("hands: {d} | pairs: {d}\n", .{total, counter});
}

fn getFiveCards(deck: *zdeck.Deck) [5]zdeck.Card {
    var hand: [5]zdeck.Card = undefined;
    for (hand, 0..) |_, i| {
        hand[i] = deck.getTopCard() orelse unreachable;
    }
    return hand;
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
