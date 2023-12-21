import Foundation
import DequeModule

class Day20: Day {
    let filePath = "input/20"

    typealias Modules = [ModuleName: Module]
    typealias ModuleName = String

    struct Module: Equatable {
        let name: ModuleName
        var type: ModuleType
        let destinationModules: [ModuleName]
        var inputModules: [ModuleName]

        mutating func receivePulse(_ pulse: Pulse) -> [Pulse] {
            switch type {
            case .Broadcaster:
                return destinationModules.map {
                    Pulse(from: name, to: $0, type: pulse.type)
                }
            case .FlipFlop(let state):
                switch pulse.type {
                case .Low:
                    let pulseTypeToSend = state ? PulseType.Low : PulseType.High
                    type = .FlipFlop(state: !state)
                    return destinationModules.map {
                        Pulse(from: name, to: $0, type: pulseTypeToSend)
                    }
                case .High:
                    return []
                }
            case .Conjunction(let lastPulsesPerInput):
                let newLastPulsesPerInput = lastPulsesPerInput.merging([pulse.from: pulse.type]) {
                    $1
                }
                let pulseTypeToSend =
                    newLastPulsesPerInput.values.allSatisfy({ $0 == .High }) ? PulseType.Low : PulseType.High
                type = .Conjunction(lastPulsesPerInput: newLastPulsesPerInput)
                return destinationModules.map {
                    Pulse(from: name, to: $0, type: pulseTypeToSend)
                }
            case .UnTyped:
                return []
            }
        }

        func isConjunction() -> Bool {
            if case .Conjunction(_) = type {
                return true
            } else {
                return false
            }
        }
    }

    enum ModuleType: Equatable {
        case Broadcaster
        case FlipFlop(state: Bool)
        case Conjunction(lastPulsesPerInput: [ModuleName: PulseType])
        case UnTyped
    }

    struct Pulse: Equatable {
        let from: ModuleName
        let to: ModuleName
        let type: PulseType
    }

    enum PulseType: Equatable {
        case Low
        case High
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseModulesAndPressButtonMultipleTimes(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseModulesAndPressButtonUntilDestinationModuleIsReached(lines)
        print("B: \(result)")
    }

    func parseModulesAndPressButtonMultipleTimes(_ lines: [String]) -> Int {
        let modules = parseModules(lines)
        return pressButtonMultipleTimes(modules, count: 1000)
    }

    func parseModulesAndPressButtonUntilDestinationModuleIsReached(_ lines: [String]) -> Int {
        /*
         Brute force did not work, so I have checked the input and found out that
         the destination module (rx) is connected only to a single conjunction module (jm).
         This conjunction module has multiple inputs, so in order for it to send a low pulse
         all of its inputs need to send a high pulse at the same time.
         Figuring out these are periodic we need see how many button presses are needed for
         each input to send a high pulse, and then calculate LCM of these numbers.
         */

        let destinationModule = "rx"
        var modules = parseModules(lines)

        assert(modules[destinationModule]!.inputModules.count == 1)
        let destinationInputModule = modules[modules[destinationModule]!.inputModules[0]]!

        assert(destinationInputModule.isConjunction())
        assert(destinationInputModule.inputModules.count == 4)

        var buttonPressesPerConjunctionInput = [ModuleName: Int](
            uniqueKeysWithValues: destinationInputModule.inputModules.map {
                ($0, 0)
            }
        )

        var buttonPresses = 0
        while !buttonPressesPerConjunctionInput.values.allSatisfy({ $0 > 0 }) {
            let (_, _, pulsesReceivedByModuleNamesToLookFor) =
                pressButton(&modules, moduleNameToLookFor: destinationInputModule.name)
            buttonPresses += 1

            let highPulsesReceived = pulsesReceivedByModuleNamesToLookFor.filter({ $0.type == .High })

            if highPulsesReceived.count > 0 {
                for pulse in highPulsesReceived {
                    buttonPressesPerConjunctionInput[pulse.from]! = buttonPresses
                }
            }
        }

        return Common.calculateLeastCommonMultiple(buttonPressesPerConjunctionInput.values.map {
            $0
        })
    }

    func pressButtonMultipleTimes(_ modules: Modules, count: Int = 1000) -> Int {
        var modules = modules

        let (lowPulses, highPulses) =
            (1...count).reduce((0, 0)) { acc, _ in
                let (lowPulsesTotal, highPulsesTotal) = acc
                let (lowPulsesCount, highPulsesCount, _) = pressButton(&modules)
                return (lowPulsesTotal + lowPulsesCount, highPulsesTotal + highPulsesCount)
            }

        return lowPulses * highPulses
    }

    func pressButton(_ modules: inout Modules, moduleNameToLookFor: ModuleName? = nil) -> (
        lowPulsesCount: Int,
        highPulsesCount: Int,
        pulsesReceivedByModuleToLookFor: [Pulse]
    ) {
        let initialPulse = Pulse(from: "button", to: "broadcaster", type: .Low)
        var pulsesToProcess: Deque<Pulse> = [initialPulse]
        var lowPulsesCount = 0
        var highPulsesCount = 0
        var pulsesReceivedByModuleNamesToLookFor = [Pulse]()

        while let pulse = pulsesToProcess.popFirst() {
            if pulse.to == moduleNameToLookFor {
                pulsesReceivedByModuleNamesToLookFor.append(pulse)
            }

            switch pulse.type {
            case .Low:
                lowPulsesCount += 1
            case .High:
                highPulsesCount += 1
            }
            pulsesToProcess += modules[pulse.to]!.receivePulse(pulse)
        }

        return (lowPulsesCount, highPulsesCount, pulsesReceivedByModuleNamesToLookFor)
    }

    func parseModules(_ lines: [String]) -> Modules {
        var modules: Modules = Modules()
        var inputs: [ModuleName: [ModuleName]] = [:]

        for line in lines {
            let parts = line.components(separatedBy: " -> ")

            let destinationModuleNames =
                parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: ", ").map {
                    ModuleName($0)
                }

            switch parts[0] {
            case let moduleName where moduleName == "broadcaster":
                modules[moduleName] = Module(
                    name: moduleName,
                    type: ModuleType.Broadcaster,
                    destinationModules: destinationModuleNames,
                    inputModules: []
                )
                destinationModuleNames.forEach {
                    inputs[$0, default: []].append(moduleName)
                }
            case let flipFlop where flipFlop.starts(with: "%"):
                let moduleName = ModuleName(flipFlop.replacingOccurrences(of: "%", with: ""))
                modules[moduleName] = Module(
                    name: moduleName,
                    type: ModuleType.FlipFlop(state: false),
                    destinationModules: destinationModuleNames,
                    inputModules: []
                )
                destinationModuleNames.forEach {
                    inputs[$0, default: []].append(moduleName)
                }
            case let conjunction where conjunction.starts(with: "&"):
                let moduleName = conjunction.replacingOccurrences(of: "&", with: "")
                modules[moduleName] = Module(
                    name: moduleName,
                    type: ModuleType.Conjunction(lastPulsesPerInput: [:]),
                    destinationModules: destinationModuleNames,
                    inputModules: []
                )
                destinationModuleNames.forEach {
                    inputs[$0, default: []].append(moduleName)
                }
            default:
                fatalError("Unknown module type \(parts[0])")
            }
        }

        for (moduleName, inputModuleNames) in inputs {
            if let module = modules[moduleName] {
                switch module.type {
                case .Broadcaster:
                    modules[moduleName]!.inputModules = inputModuleNames
                case .Conjunction(_):
                    modules[moduleName]!.type = .Conjunction(
                        lastPulsesPerInput: inputModuleNames.reduce(into: [:]) {
                            $0[$1] = .Low
                        }
                    )
                    modules[moduleName]!.inputModules = inputModuleNames
                case .FlipFlop(_):
                    modules[moduleName]!.inputModules = inputModuleNames
                case .UnTyped:
                    fatalError("Untyped module \(moduleName) should not appear here")
                }
            } else {
                modules[moduleName] = Module(
                    name: moduleName,
                    type: .UnTyped,
                    destinationModules: [],
                    inputModules: inputModuleNames
                )
            }
        }

        return modules
    }

    func runTests() {
        let example1 =
            Common.transformToLines(
                """
                broadcaster -> a, b, c
                %a -> b
                %b -> c
                %c -> inv
                &inv -> a
                """
            )

        let modules1 = parseModules(example1)

        assert(modules1.count == 5)

        assert(
            modules1["broadcaster"]! ==
                Module(
                    name: "broadcaster",
                    type: .Broadcaster,
                    destinationModules: ["a", "b", "c"],
                    inputModules: []
                )
        )

        assert(
            modules1["a"]! ==
                Module(
                    name: "a",
                    type: .FlipFlop(state: false),
                    destinationModules: ["b"],
                    inputModules: ["broadcaster", "inv"]
                )
        )

        assert(
            modules1["b"]! ==
                Module(
                    name: "b",
                    type: .FlipFlop(state: false),
                    destinationModules: ["c"],
                    inputModules: ["broadcaster", "a"]
                )
        )

        assert(
            modules1["c"]! ==
                Module(
                    name: "c",
                    type: .FlipFlop(state: false),
                    destinationModules: ["inv"],
                    inputModules: ["broadcaster", "b"]
                )
        )

        assert(
            modules1["inv"]! ==
                Module(
                    name: "inv",
                    type: .Conjunction(lastPulsesPerInput: ["c": .Low]),
                    destinationModules: ["a"],
                    inputModules: ["c"]
                )
        )

        var newModules1 = modules1
        assert(pressButton(&newModules1) == (lowPulsesCount: 8, highPulsesCount: 4, pulsesReceivedByModuleToLookFor: []))
        assert(pressButtonMultipleTimes(modules1, count: 1000) == 32000000)

        let example2 =
            Common.transformToLines(
                """
                broadcaster -> a
                %a -> inv, con
                &inv -> b
                %b -> con
                &con -> output
                """
            )

        let modules2 = parseModules(example2)
        assert(pressButtonMultipleTimes(modules2, count: 1000) == 11687500)
    }
}