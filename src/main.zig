//
// MIT License
//
// Copyright (c) 2024 Andy Alt (arch_stanton5995@proton.me)
// Project URL: https://github.com/andy5995/zigpokerhands
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Author's Email: arch_stanton5995@proton.me

const std = @import("std");
const zdeck = @import("zigdeck");

pub const HandType = enum {
    Pair,
    TwoPair,
    ThreeOfAKind,
    Straight,
    Flush,
    FullHouse,
    FourOfAKind,
    StraightFlush,
    RoyalFlush,
};

pub fn main() !void {
    var rng = std.rand.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));

    const total = 1000000;
    std.debug.print("Evaluating {d} hands...\n\n", .{total});

    var handCounts: std.AutoHashMap(HandType, usize) = std.AutoHashMap(HandType, usize).init(std.heap.page_allocator);
    defer handCounts.deinit();
    for (0..total) |_| {
        var deck = zdeck.Deck.init();
        zdeck.Deck.shuffle(&deck, &rng.random());
        const hand = getFiveCards(&deck);
        evaluateHand(hand, &handCounts);
    }

    const handRanks = [_]HandType{
        HandType.Pair,
        HandType.TwoPair,
        HandType.ThreeOfAKind,
        HandType.Straight,
        HandType.Flush,
        HandType.FullHouse,
        HandType.FourOfAKind,
        HandType.StraightFlush,
        HandType.RoyalFlush,
    };

    for (handRanks) |rank| {
        const count = handCounts.get(rank) orelse 0;
        const rankStr = @tagName(rank);
        std.debug.print("{s:39}: {}\n", .{ rankStr, count });
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
    if (containsRoyalFlush(hand)) {
        const result = handCounts.get(HandType.RoyalFlush) orelse 0;
        _ = handCounts.put(HandType.RoyalFlush, result + 1) catch unreachable;
    } else if (containsStraightFlush(hand)) {
        const result = handCounts.get(HandType.StraightFlush) orelse 0;
        _ = handCounts.put(HandType.StraightFlush, result + 1) catch unreachable;
    } else if (containsFourOfAKind(hand)) {
        const result = handCounts.get(HandType.FourOfAKind) orelse 0;
        _ = handCounts.put(HandType.FourOfAKind, result + 1) catch unreachable;
    } else if (containsFullHouse(hand)) {
        const result = handCounts.get(HandType.FullHouse) orelse 0;
        _ = handCounts.put(HandType.FullHouse, result + 1) catch unreachable;
    } else if (containsThreeOfAKind(hand)) {
        const result = handCounts.get(HandType.ThreeOfAKind) orelse 0;
        _ = handCounts.put(HandType.ThreeOfAKind, result + 1) catch unreachable;
    } else if (containsTwoPair(hand)) {
        const result = handCounts.get(HandType.TwoPair) orelse 0;
        _ = handCounts.put(HandType.TwoPair, result + 1) catch unreachable;
    } else if (containsPair(hand)) {
        const result = handCounts.get(HandType.Pair) orelse 0;
        _ = handCounts.put(HandType.Pair, result + 1) catch unreachable;
    }
    if (containsStraight(hand)) {
        const result = handCounts.get(HandType.Straight) orelse 0;
        _ = handCounts.put(HandType.Straight, result + 1) catch unreachable;
    }
    if (containsFlush(hand)) {
        const result = handCounts.get(HandType.Flush) orelse 0;
        _ = handCounts.put(HandType.Flush, result + 1) catch unreachable;
    }
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

fn containsTwoPair(hand: [5]zdeck.Card) bool {
    var counts: [13]u8 = [_]u8{0} ** 13; // Initialize array with zeros

    for (hand) |card| {
        const faceIndex: usize = @intFromEnum(card.face) - 1;
        counts[faceIndex] += 1;
    }

    const pairCount: usize = blk: {
        var count: usize = 0;
        for (counts) |c| {
            if (c == 2) count += 1;
        }
        break :blk count;
    };

    return pairCount == 2;
}

fn containsThreeOfAKind(hand: [5]zdeck.Card) bool {
    var counts: [13]u8 = [_]u8{0} ** 13; // Initialize array with zeros

    for (hand) |card| {
        const faceIndex: usize = @intFromEnum(card.face) - 1;
        counts[faceIndex] += 1;
    }

    for (counts) |count| {
        if (count >= 3) {
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

fn containsFlush(hand: [5]zdeck.Card) bool {
    const firstSuit = hand[0].suit;
    for (hand[1..]) |card| {
        if (card.suit != firstSuit) {
            return false;
        }
    }
    return true;
}

fn containsFullHouse(hand: [5]zdeck.Card) bool {
    var counts: [13]u8 = [_]u8{0} ** 13; // Initialize array with zeros

    for (hand) |card| {
        const faceIndex: usize = @intFromEnum(card.face) - 1;
        counts[faceIndex] += 1;
    }

    var threeOfAKind = false;
    var pair = false;
    for (counts) |count| {
        if (count == 3) {
            threeOfAKind = true;
        } else if (count == 2) {
            pair = true;
        }
    }

    return threeOfAKind and pair;
}

fn containsFourOfAKind(hand: [5]zdeck.Card) bool {
    var counts: [13]u8 = [_]u8{0} ** 13; // Initialize array with zeros

    for (hand) |card| {
        const faceIndex: usize = @intFromEnum(card.face) - 1;
        counts[faceIndex] += 1;
    }

    for (counts) |count| {
        if (count == 4) {
            return true;
        }
    }

    return false;
}

fn containsStraightFlush(hand: [5]zdeck.Card) bool {
    return containsStraight(hand) and containsFlush(hand);
}

fn containsRoyalFlush(hand: [5]zdeck.Card) bool {
    return containsStraightFlush(hand) and hand[4].face == zdeck.Face.Ace;
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
