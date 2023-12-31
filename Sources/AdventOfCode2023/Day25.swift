import Foundation

class Day25: Day {
    let filePath = "input/25"

    typealias Components = [Component: [Component: Int]]
    typealias Component = String
    struct Edge: Equatable {
        let component1: Component
        let component2: Component
        let count: Int

        init(component1: Component, component2: Component, count: Int = 1) {
            self.component1 = component1
            self.component2 = component2
            self.count = count
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseComponentsAndSeparateInto2GroupsAndMultipleTheirSizes(lines)
        print("A: \(result)")
    }

    func b() async throws {
    }

    func parseComponentsAndSeparateInto2GroupsAndMultipleTheirSizes(_ lines: [String]) -> Int {
        let components = parseComponents(lines)
        let (group1, group2) = removeConnectionsUntil2Groups(components)!
        return group1.count * group2.count
    }

    func removeConnectionsUntil2Groups(
        _ components: Components,
        numberOfConnectionsToRemove: Int = 3
    ) -> ([Component], [Component])? {
        // Karger's algorithm, not a 100% solution, but a pretty fast and probable one, it will also fail fast if it can't find a solution
        let removeUntil = 100

        var currentComponents = components
        var edges = componentsToEdges(currentComponents)

        if edges.count > removeUntil {
            print("Using Karger's algorithm to contract edges from \(edges.count) edges")

            while edges.count > removeUntil {
                let edgesToChooseFrom =
                    edges
                    .flatMap { edge in
                        (1...edge.count)
                            .map { _ in
                                edge
                            }
                    }

                let edgesToContract =
                    (edgesToChooseFrom
                    .shuffled())[0...removeUntil/2]

                currentComponents = edgesToContract.reduce(currentComponents, { contractEdge($1, in: $0) })
                edges = componentsToEdges(currentComponents)
            }

            print("Using brute force to remove \(numberOfConnectionsToRemove) connections from \(edges.map{ $0.count}.reduce(0, +)) edges")
        }

        let edgeCombinations = combinations(edges, of: numberOfConnectionsToRemove)

        for edgeCombination in edgeCombinations {
            let componentsWithoutEdges = edgeCombination.reduce(currentComponents) { currentComponents, edge in
                removeEdge(edge, from: currentComponents)
            }
            let groups = disjointGroups(componentsWithoutEdges)
            if groups.count == 2 {
                let group1 = groups[0].flatMap { $0.components(separatedBy: "_") }
                let group2 = groups[1].flatMap { $0.components(separatedBy: "_") }
                return (group1, group2)
            }
        }

        return nil
    }

    func componentsToEdges(_ components: Components) -> [Edge] {
        components.flatMap { component1, connectedComponents in
            connectedComponents.map { (component2, count) in
                Edge(component1: component1, component2: component2, count: count)
            }
        }.uniqued(by: { edge in
            min(edge.component1, edge.component2) + "-" + max(edge.component1, edge.component2)
        })
    }

    func disjointGroups(_ components: Components) -> [Set<Component>] {
        var nodes = Set(components.keys)
        var groups: [Set<Component>] = []
        var currentGroup = Set<Component>()
        var toProcess: [Component] = []

        while !nodes.isEmpty {
            toProcess = [nodes.first!]
            while let component = toProcess.popLast() {
                currentGroup.insert(component)
                nodes.remove(component)
                toProcess += components[component]!.keys.filter { !currentGroup.contains($0) }
            }
            groups.append(currentGroup)
            currentGroup = []
        }

        return groups
    }

    func contractEdge(_ edge: Edge, in components: Components) -> Components {
        var newComponents = components
        let component1 = edge.component1
        let component2 = edge.component2

        if newComponents[component1] == nil || newComponents[component2] == nil {
            return newComponents
        }

        let connectedComponents1 =
            Dictionary(uniqueKeysWithValues:
                newComponents.removeValue(forKey: component1)!.filter {
                    $0.key != component2
                }
            )

        for (connectedComponent1, _) in connectedComponents1 {
            newComponents[connectedComponent1] =
                Dictionary(uniqueKeysWithValues:
                    newComponents[connectedComponent1]!.filter {
                        $0.key != component1
                    }
                )
        }

        let connectedComponents2 =
            Dictionary(uniqueKeysWithValues:
                newComponents.removeValue(forKey: component2)!.filter {
                    $0.key != component1
                }
            )

        for (connectedComponent2, _) in connectedComponents2 {
            newComponents[connectedComponent2] =
                Dictionary(uniqueKeysWithValues:
                    newComponents[connectedComponent2]!.filter {
                        $0.key != component2
                    }
                )
        }

        let contractedComponent = component1 + "_" + component2

        let contractedConnectedComponents = connectedComponents1.merging(connectedComponents2) {
            $0 + $1
        }

        newComponents[contractedComponent] = contractedConnectedComponents

        for (contractedConnectedComponent, count) in contractedConnectedComponents {
            newComponents[contractedConnectedComponent]![contractedComponent] = count
        }

        return newComponents
    }

    func combinations(_ edges: [Edge], of count: Int) -> [[Edge]] {
        struct ToProcessElement {
            let chosenEdges: [Edge]
            let idx: Int
            let countLeft: Int
        }
        var combinations: [[Edge]] = []
        var toProcess = [
            ToProcessElement(chosenEdges: [], idx: 0, countLeft: count)
        ]

        while let element = toProcess.popLast() {
            if element.countLeft == 0 {
                combinations.append(element.chosenEdges)
                continue
            } else if element.countLeft < 0 {
                continue
            }

            if element.idx >= edges.count {
                continue
            }

            let edge = edges[element.idx]

            toProcess.append(
                ToProcessElement(
                    chosenEdges: element.chosenEdges,
                    idx: element.idx + 1,
                    countLeft: element.countLeft
                )
            )

            toProcess.append(
                ToProcessElement(
                    chosenEdges: element.chosenEdges + [edge],
                    idx: element.idx + 1,
                    countLeft: element.countLeft - edge.count
                )
            )
        }

        return combinations
    }

    func removeEdge(_ edge: Edge, from components: Components) -> Components {
        Dictionary(uniqueKeysWithValues:
            components.map { component, connectedComponents in
                if component == edge.component1 {
                    return (
                        component,
                        Dictionary(uniqueKeysWithValues:
                            connectedComponents.filter { $0.key != edge.component2 }
                        )
                    )
                } else if component == edge.component2 {
                    return (
                        component,
                        Dictionary(uniqueKeysWithValues:
                            connectedComponents.filter { $0.key != edge.component1 }
                        )
                    )
                } else {
                    return (component, connectedComponents)
                }
            }
        )
    }

    func display(_ components: Components, componentsToDisplay: [Component] = []) {
        // Display in a way compatible with Graphviz for further visualization
        struct ComponentPair: Hashable, Equatable {
            let component1: Component
            let component2: Component
        }
        var visited = Set<ComponentPair>()
        print("graph G {")
        for (component, connectedComponents) in components {
            if !componentsToDisplay.isEmpty && !componentsToDisplay.contains(where: { component.contains($0) }) {
                continue
            }
            for (connectedComponent, count) in connectedComponents {
                let pair1 = ComponentPair(component1: component, component2: connectedComponent)
                let pair2 = ComponentPair(component1: connectedComponent, component2: component)
                if visited.contains(pair1) || visited.contains(pair2) {
                    continue
                }
                visited.insert(pair1)
                visited.insert(pair2)

                var componentName: String;
                var connectedComponentName: String;

                componentName = component
                connectedComponentName = connectedComponent

                if count > 1 {
                    print("\(componentName) -- \(connectedComponentName) [label=\"\(count)\"];")
                } else {
                    print("\(componentName) -- \(connectedComponentName);")
                }
            }
        }
        print("}")
    }

    func parseComponents(_ lines: [String]) -> Components {
        var componentConnections = Components()
        for line in lines {
            let parts = line.components(separatedBy: ":")
            let component1 = parts[0]
            let connectedComponents = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ")

            for component2 in connectedComponents {
                componentConnections[component1, default: [:]][component2] = 1
                componentConnections[component2, default: [:]][component1] = 1
            }
        }
        return componentConnections
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                jqt: rhn xhk nvd
                rsh: frs pzl lsr
                xhk: hfx
                cmg: qnr nvd lhk bvb
                rhn: xhk bvb hfx
                bvb: xhk hfx
                pzl: lsr hfx nvd
                qnr: nvd
                ntq: jqt hfx bvb xhk
                nvd: lhk
                lsr: lhk
                rzs: qnr cmg lsr rsh
                frs: qnr lhk lsr
                """
            )

        let components = parseComponents(example)

        assert(components.count == 15)
        assert(components["jqt"] == ["rhn": 1, "xhk": 1, "nvd": 1, "ntq": 1])
        assert(components["lhk"] == ["cmg": 1, "nvd": 1, "lsr": 1, "frs": 1])
        assert(components["ntq"] == ["jqt": 1, "hfx": 1, "bvb": 1, "xhk": 1])
        assert(components["rzs"] == ["qnr": 1, "cmg": 1, "lsr": 1, "rsh": 1])

        let newComponents1 = contractEdge(Edge(component1: "xhk", component2: "rhn"), in: components)
        assert(newComponents1.count == 14)
        assert(newComponents1["xhk_rhn"] == ["bvb": 2, "hfx": 2, "jqt": 2, "ntq": 1])
        assert(newComponents1["bvb"] == ["cmg": 1, "hfx": 1, "ntq": 1, "xhk_rhn": 2])
        assert(newComponents1["hfx"] == ["bvb": 1, "ntq": 1, "pzl": 1, "xhk_rhn": 2])
        assert(newComponents1["jqt"] == ["ntq": 1, "nvd": 1, "xhk_rhn": 2])
        assert(newComponents1["ntq"] == ["bvb": 1, "hfx": 1, "jqt": 1, "xhk_rhn": 1])

        let newComponents2 = contractEdge(Edge(component1: "xhk_rhn", component2: "bvb", count: 2), in: newComponents1)
        assert(newComponents2.count == 13)
        assert(newComponents2["xhk_rhn_bvb"] == ["hfx": 3, "jqt": 2, "ntq": 2, "cmg": 1])
        assert(newComponents2["hfx"] == ["ntq": 1, "pzl": 1, "xhk_rhn_bvb": 3])
        assert(newComponents2["jqt"] == ["ntq": 1, "nvd": 1, "xhk_rhn_bvb": 2])
        assert(newComponents2["ntq"] == ["hfx": 1, "jqt": 1, "xhk_rhn_bvb": 2])

        assert(disjointGroups(components).count == 1)
        let components1 = removeEdge(Edge(component1: "hfx", component2: "pzl"), from: components)
        assert(disjointGroups(components1).count == 1)
        let components2 = removeEdge(Edge(component1: "bvb", component2: "cmg"), from: components1)
        assert(disjointGroups(components2).count == 1)
        let components3 = removeEdge(Edge(component1: "nvd", component2: "jqt"), from: components2)
        assert(disjointGroups(components3).count == 2)

        assert(
            combinations([
                Edge(component1: "a", component2: "b", count: 1),
                Edge(component1: "a", component2: "c", count: 2),
                Edge(component1: "b", component2: "c", count: 1),
                Edge(component1: "b", component2: "d", count: 3),
                Edge(component1: "c", component2: "d", count: 1),
            ], of: 3) == [
                [
                    Edge(component1: "a", component2: "b", count: 1),
                    Edge(component1: "a", component2: "c", count: 2),
                ],
                [
                    Edge(component1: "a", component2: "b", count: 1),
                    Edge(component1: "b", component2: "c", count: 1),
                    Edge(component1: "c", component2: "d", count: 1),
                ],
                [
                    Edge(component1: "a", component2: "c", count: 2),
                    Edge(component1: "b", component2: "c", count: 1)
                ],
                [
                    Edge(component1: "a", component2: "c", count: 2),
                    Edge(component1: "c", component2: "d", count: 1)
                ],
                [
                    Edge(component1: "b", component2: "d", count: 3)
                ]
            ])

        let (group1, group2) = removeConnectionsUntil2Groups(components)!

        let sortedGroup1 = group1.sorted()
        let sortedGroup2 = group2.sorted()

        let minGroup = min(sortedGroup1, sortedGroup2)
        let maxGroup = max(sortedGroup1, sortedGroup2)

        assert(minGroup == ["bvb", "hfx", "jqt", "ntq", "rhn", "xhk"])
        assert(maxGroup == ["cmg", "frs", "lhk", "lsr", "nvd", "pzl", "qnr", "rsh", "rzs"])
    }
}
