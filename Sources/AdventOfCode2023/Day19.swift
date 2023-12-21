import Foundation
import RegexBuilder

class Day19: Day {
    let filePath = "input/19"

    let workflowRegex = Regex {
        Capture {
            OneOrMore(.word)
        }
        "{"
        Capture {
            OneOrMore(.any)
        }
        "}"
    }

    let ruleRegex = Regex {
        Optionally {
            Capture {
                OneOrMore(.any)
            }
            ":"
        }
        Capture {
            OneOrMore(.word)
        }
    }

    let conditionRegex = Regex {
        Capture {
            ChoiceOf {
                "x"
                "m"
                "a"
                "s"
            }
        }
        Capture {
            ChoiceOf {
                "<"
                ">"
            }
        }
        Capture {
            OneOrMore(.digit)
        }
    }

    let partRegex = Regex {
        "{"
        "x="
        Capture {
            OneOrMore(.digit)
        }
        ","
        "m="
        Capture {
            OneOrMore(.digit)
        }
        ","
        "a="
        Capture {
            OneOrMore(.digit)
        }
        ","
        "s="
        Capture {
            OneOrMore(.digit)
        }
        "}"
    }

    typealias WorkflowName = String
    typealias Workflows = [WorkflowName: Workflow]
    typealias Parts = [Part]

    struct Workflow: Equatable {
        enum Rule: Equatable {
            enum RuleResult: Equatable {
                case accept
                case reject
                case nextWorkflow(WorkflowName)
                case nextRule
            }

            struct Operator {
                let f: (Int, Int) -> Bool
                let name: String
            }

            case condition(Part.Rating, Operator, Int, RuleResult)
            case noCondition(RuleResult)

            func apply(_ part: Part) -> RuleResult {
                switch self {
                case .condition(let rating, let op, let value, let result):
                    return Self.applyCondition(part.ratings[rating]!, op, value, result)
                case .noCondition(let result):
                    return result
                }
            }

            static func applyCondition(_ int: Int, _ op: Operator, _ value: Int, _ result: RuleResult) -> RuleResult {
                if op.f(int, value) {
                    return result
                } else {
                    return .nextRule
                }
            }

            static func ==(lhs: Workflow.Rule, rhs: Workflow.Rule) -> Bool {
                switch (lhs, rhs) {
                case (
                         .condition(let rating1, let op1, let value1, let result1),
                         .condition(let rating2, let op2, let value2, let result2)
                     ):
                    return rating1 == rating2 && op1.name == op2.name && value1 == value2 && result1 == result2
                case (.noCondition(let result1), .noCondition(let result2)):
                    return result1 == result2
                default:
                    return false
                }
            }
        }

        let rules: [Rule]
        let name: WorkflowName
    }

    struct Part: Equatable {
        enum Rating: String, Equatable {
            case x = "x"
            case m = "m"
            case a = "a"
            case s = "s"
        }

        let ratings: [Rating: Int]
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseWorkflowsAndPartsAndComputeAcceptedPartsAndSumRatings(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseWorkflowsAndPartsAndComputeCountOfPossibleAcceptedParts(lines)
        print("B: \(result)")
    }

    func parseWorkflowsAndPartsAndComputeAcceptedPartsAndSumRatings(_ lines: [String]) -> Int {
        let (workflows, parts) = parseWorkflowsAndParts(lines)
        return computeAcceptedPartsAndSumRatings(workflows: workflows, parts: parts)
    }

    func parseWorkflowsAndPartsAndComputeCountOfPossibleAcceptedParts(_ lines: [String]) -> Int {
        let (workflows, _) = parseWorkflowsAndParts(lines)
        return computeCountOfPossibleAcceptedParts(workflows)
    }

    func computeAcceptedPartsAndSumRatings(workflows: Workflows, parts: Parts) -> Int {
        parts
            .filter {
                sendPartThroughWorkflows($0, workflows: workflows) == .accept
            }
            .map {
                $0.ratings.values.reduce(0, +)
            }
            .reduce(0, +)
    }

    func sendPartThroughWorkflows(_ part: Part, workflows: Workflows) -> Workflow.Rule.RuleResult {
        var currentWorkflow = workflows["in"]!

        while true {
            rules: for rule in currentWorkflow.rules {
                let result = rule.apply(part)

                switch result {
                case .accept:
                    return .accept
                case .reject:
                    return .reject
                case .nextWorkflow(let workflowName):
                    currentWorkflow = workflows[workflowName]!
                    break rules
                case .nextRule:
                    continue
                }
            }
        }
    }

    func computeCountOfPossibleAcceptedParts(_ workflows: Workflows) -> Int {
        typealias PartRanges = [Part.Rating: ClosedRange<Int>]
        let initialPartRanges: PartRanges = [
            .x: 1...4000,
            .m: 1...4000,
            .a: 1...4000,
            .s: 1...4000
        ]

        var rangesToProcess: [(PartRanges, Workflow)] = [(initialPartRanges, workflows["in"]!)]
        var acceptedRanges = [PartRanges]()

        func interpretResultAndDecideIfNextRule(_ result: Workflow.Rule.RuleResult, range: PartRanges) -> Bool {
            switch result {
            case .accept:
                acceptedRanges.append(range)
                return false
            case .reject:
                return false
            case .nextWorkflow(let workflowName):
                rangesToProcess.append((range, workflows[workflowName]!))
                return false
            case .nextRule:
                return true
            }
        }

        while let (partRangesToProcess, currentWorkflow) = rangesToProcess.popLast() {
            var currentPartRanges = partRangesToProcess
            rules: for rule in currentWorkflow.rules {
                switch rule {
                case .condition(let rating, let op, let value, let result):
                    let range = currentPartRanges[rating]!

                    if range.contains(value) {
                        let newRange1: ClosedRange<Int>
                        let newRange2: ClosedRange<Int>

                        switch op.name {
                        case "<":
                            newRange1 = range.lowerBound...value - 1
                            newRange2 = value...range.upperBound
                        case ">":
                            newRange1 = range.lowerBound...value
                            newRange2 = value + 1...range.upperBound
                        default:
                            fatalError("Unknown operator: \(op.name)")
                        }

                        let newPartRange1 = currentPartRanges.merging([rating: newRange1]) { _, new in
                            new
                        }
                        let newPartRange2 = currentPartRanges.merging([rating: newRange2]) { _, new in
                            new
                        }

                        let ruleResult1 = Workflow.Rule.applyCondition(newRange1.first!, op, value, result)
                        let ruleResult2 = Workflow.Rule.applyCondition(newRange2.first!, op, value, result)

                        let nextRuleForRange1 = interpretResultAndDecideIfNextRule(ruleResult1, range: newPartRange1)
                        let nextRuleForRange2 = interpretResultAndDecideIfNextRule(ruleResult2, range: newPartRange2)

                        if nextRuleForRange1 && !nextRuleForRange2 {
                            currentPartRanges = newPartRange1
                        } else if !nextRuleForRange1 && nextRuleForRange2 {
                            currentPartRanges = newPartRange2
                        } else {
                            fatalError("Unexpected next rules \(currentPartRanges) \(rule)")
                        }
                    } else {
                        let ruleResult = Workflow.Rule.applyCondition(range.first!, op, value, result)

                        if !interpretResultAndDecideIfNextRule(ruleResult, range: currentPartRanges) {
                            break rules
                        }
                    }
                case .noCondition(let ruleResult):
                    if !interpretResultAndDecideIfNextRule(ruleResult, range: currentPartRanges) {
                        break rules
                    }
                }
            }
        }

        return acceptedRanges.reduce(0) { count, ranges in
            count + ranges.reduce(1) { count, range in
                count * (range.value.upperBound - range.value.lowerBound + 1)
            }
        }
    }

    func parseWorkflowsAndParts(_ lines: [String]) -> (Workflows, Parts) {
        var workflows: Workflows = [:]
        var parts: Parts = []
        var parsingWorkflows = true
        var i = 0

        while parsingWorkflows {
            if lines[i] == "NEXT" {
                parsingWorkflows = false
            } else {
                let workflow = parseWorkflow(lines[i])
                workflows[workflow.name] = workflow
            }
            i += 1
        }

        while i < lines.count {
            parts.append(parsePart(lines[i]))
            i += 1
        }

        return (workflows, parts)
    }

    func parseWorkflow(_ s: String) -> Workflow {
        let (_, workflowName, rules) = (try! workflowRegex.wholeMatch(in: s)!).output
        return Workflow(
            rules: rules.components(separatedBy: ",").map(parseRule),
            name: String(workflowName)
        )
    }

    func parseRule(_ s: String) -> Workflow.Rule {
        func parseOperator(_ s: String) -> Workflow.Rule.Operator {
            switch s {
            case "<":
                return Workflow.Rule.Operator(f: (<), name: s)
            case ">":
                return Workflow.Rule.Operator(f: (>), name: s)
            default:
                fatalError("Unknown operator: \(s)")
            }
        }

        func parseResult(_ s: String) -> Workflow.Rule.RuleResult {
            switch s {
            case "A":
                return .accept
            case "R":
                return .reject
            default:
                return .nextWorkflow(s)
            }
        }

        let (_, conditionOptional, result) = (try! ruleRegex.wholeMatch(in: s)!).output
        let ruleResult = parseResult(String(result))

        if let condition = conditionOptional {
            let (_, rating, op, value) = (try! conditionRegex.wholeMatch(in: condition)!).output
            return Workflow.Rule.condition(
                Part.Rating(rawValue: String(rating))!,
                parseOperator(String(op)),
                Int(value)!,
                ruleResult
            )
        } else {
            return Workflow.Rule.noCondition(ruleResult)
        }
    }

    func parsePart(_ s: String) -> Part {
        let (_, x, m, a, s) = (try! partRegex.wholeMatch(in: s)!).output
        return Part(
            ratings: [
                .x: Int(x)!,
                .m: Int(m)!,
                .a: Int(a)!,
                .s: Int(s)!
            ]
        )
    }

    func runTests() {
        assert(
            parseWorkflow("qsx{m>3295:A,x<651:R,x>1078:gj,vsr}") ==
                Workflow(
                    rules: [
                        .condition(.m, Workflow.Rule.Operator(f: (>), name: ">"), 3295, .accept),
                        .condition(.x, Workflow.Rule.Operator(f: (<), name: "<"), 651, .reject),
                        .condition(.x, Workflow.Rule.Operator(f: (>), name: ">"), 1078, .nextWorkflow("gj")),
                        .noCondition(.nextWorkflow("vsr"))
                    ],
                    name: "qsx"
                )
        )

        assert(
            parsePart("{x=787,m=2655,a=1222,s=2876}") ==
                Part(
                    ratings: [
                        .x: 787,
                        .m: 2655,
                        .a: 1222,
                        .s: 2876
                    ]
                )
        )

        let example =
            Common.transformToLines(
                """
                px{a<2006:qkq,m>2090:A,rfg}
                pv{a>1716:R,A}
                lnx{m>1548:A,A}
                rfg{s<537:gd,x>2440:R,A}
                qs{s>3448:A,lnx}
                qkq{x<1416:A,crn}
                crn{x>2662:A,R}
                in{s<1351:px,qqz}
                qqz{s>2770:qs,m<1801:hdj,R}
                gd{a>3333:R,R}
                hdj{m>838:A,pv}
                NEXT
                {x=787,m=2655,a=1222,s=2876}
                {x=1679,m=44,a=2067,s=496}
                {x=2036,m=264,a=79,s=2244}
                {x=2461,m=1339,a=466,s=291}
                {x=2127,m=1623,a=2188,s=1013}
                """
            )

        let (workflows, parts) = parseWorkflowsAndParts(example)

        assert(workflows.count == 11)
        assert(parts.count == 5)

        assert(computeAcceptedPartsAndSumRatings(workflows: workflows, parts: parts) == 19114)
        assert(computeCountOfPossibleAcceptedParts(workflows) == 167409079868000)
    }
}