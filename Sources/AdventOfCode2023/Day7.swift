import Foundation

class Day7: Day {
    let filePath = "input/7"

    let cardTypes = "23456789TJQKA".map { String($0) }
    let cardTypesWithJoker = "J23456789TQKA".map { String($0) }

    enum HandType: Int {
        case highCard = 0
        case onePair = 1
        case twoPair = 2
        case threeOfAKind = 3
        case fullHouse = 4
        case fourOfAKind = 5
        case fiveOfAKind = 6
    }
    typealias Hand = String
    typealias Bid = Int
    struct HandWithBid: Equatable {
        let hand: Hand
        let bid: Bid
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseAndCalculateTotalWinnings(lines, withJoker: false)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseAndCalculateTotalWinnings(lines, withJoker: true)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseAndCalculateTotalWinnings(_ lines: [String], withJoker: Bool) -> Int {
        calculateTotalWinnings(sortHands(parseHandsAndBids(lines), withJoker: withJoker))
    }

    func parseHandsAndBids(_ lines: [String]) -> [HandWithBid] {
        lines.map {
            let components = $0.components(separatedBy: .whitespaces)
            return HandWithBid(
                hand: components[0],
                bid: Int(components[1])!
            )
        }
    }

    func calculateTotalWinnings(_ hands: [HandWithBid]) -> Int {
        hands.enumerated().map { (index, handWithBid) in handWithBid.bid * (index + 1) }.reduce(0, +)
    }

    func sortHands(_ hands: [HandWithBid], withJoker: Bool) -> [HandWithBid] {
        hands.sorted(by: { hand1, hand2 in
            let handType1 = withJoker ? computeHandTypeWithJoker(hand1.hand) : computeHandType(hand1.hand)
            let handType2 = withJoker ? computeHandTypeWithJoker(hand2.hand) : computeHandType(hand2.hand)
            if handType1 == handType2 {
                let cardOrders1 = computeCardOrders(hand1.hand, withJoker: withJoker)
                let cardOrders2 = computeCardOrders(hand2.hand, withJoker: withJoker)

                return cardOrders1 < cardOrders2
            } else {
                return handType1.rawValue < handType2.rawValue
            }
        })
    }

    private func computeHandType(_ hand: Hand) -> HandType {
        let frequencies = Dictionary<String, Int>(hand.map{ (String($0), 1) }, uniquingKeysWith: +)

        switch frequencies.count {
        case 1:
            assert(frequencies.values.first! == 5)
            return .fiveOfAKind
        case 2:
            if frequencies.values.sorted() == [1, 4] {
                return .fourOfAKind
            } else if frequencies.values.sorted() == [2, 3] {
                return .fullHouse
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        case 3:
            if frequencies.values.sorted() == [1, 1, 3] {
                return .threeOfAKind
            } else if frequencies.values.sorted() == [1, 2, 2] {
                return .twoPair
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        case 4:
            if frequencies.values.sorted() == [1, 1, 1, 2] {
                return .onePair
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        case 5:
            if frequencies.values.sorted() == [1, 1, 1, 1, 1] {
                return .highCard
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        default:
            fatalError("Wrong frequencies: \(frequencies)")
        }
    }

    private func computeHandTypeWithJoker(_ hand: Hand) -> HandType {
        let frequencies = Dictionary<String, Int>(hand.map{ (String($0), 1) }, uniquingKeysWith: +)

        switch frequencies.count {
        case 1:
            assert(frequencies.values.first! == 5)
            return .fiveOfAKind
        case 2:
            if frequencies.values.sorted() == [1, 4] {
                if frequencies["J"] != nil {
                    return .fiveOfAKind
                } else {
                    return .fourOfAKind
                }
            } else if frequencies.values.sorted() == [2, 3] {
                if frequencies["J"] != nil {
                    return .fiveOfAKind
                } else {
                    return .fullHouse
                }
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        case 3:
            if frequencies.values.sorted() == [1, 1, 3] {
                if frequencies["J"] != nil {
                    return .fourOfAKind
                } else {
                    return .threeOfAKind
                }
            } else if frequencies.values.sorted() == [1, 2, 2] {
                switch(frequencies["J"]) {
                case .some(2):
                    return .fourOfAKind
                case .some(1):
                    return .fullHouse
                case .none:
                    return .twoPair
                default:
                    fatalError("Wrong frequencies: \(frequencies)")
                }
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        case 4:
            if frequencies.values.sorted() == [1, 1, 1, 2] {
                if frequencies["J"] != nil {
                    return .threeOfAKind
                } else {
                    return .onePair
                }
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        case 5:
            if frequencies.values.sorted() == [1, 1, 1, 1, 1] {
                switch frequencies["J"] {
                case .some(1):
                    return .onePair
                case .none:
                    return .highCard
                default:
                    fatalError("Wrong frequencies: \(frequencies)")
                }
            } else {
                fatalError("Wrong frequencies: \(frequencies)")
            }
        default:
            fatalError("Wrong frequencies: \(frequencies)")
        }
    }

    private func computeCardOrders(_ hand: String, withJoker: Bool) -> [Int] {
        if withJoker {
            return hand.map{ cardTypesWithJoker.firstIndex(of: String($0))! }
        } else {
            return hand.map{ cardTypes.firstIndex(of: String($0))! }
        }
    }

    func runTests() {
        let example =
            """
            32T3K 765
            T55J5 684
            KK677 28
            KTJJT 220
            QQQJA 483
            """
            .components(separatedBy: .newlines)

        assert(
            parseHandsAndBids(example) == [
                HandWithBid(hand: "32T3K", bid: 765),
                HandWithBid(hand: "T55J5", bid: 684),
                HandWithBid(hand: "KK677", bid: 28),
                HandWithBid(hand: "KTJJT", bid: 220),
                HandWithBid(hand: "QQQJA", bid: 483)
            ]
        )

        assert(parseAndCalculateTotalWinnings(example, withJoker: false) == 6440)
        assert(parseAndCalculateTotalWinnings(example, withJoker: true) == 5905)
    }
}