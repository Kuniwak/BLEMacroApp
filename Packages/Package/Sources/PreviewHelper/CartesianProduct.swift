public func cartesianProduct2<A, B>(_ a: [A], _ b: [B]) -> [(A, B)] {
    a.flatMap { a in b.map { b in (a, b) } }
}


public func cartesianProduct3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
    a.flatMap { a in b.flatMap { b in c.map { c in (a, b, c) } } }
}


public func cartesianProduct4<A, B, C, D>(_ a: [A], _ b: [B], _ c: [C], _ d: [D]) -> [(A, B, C, D)] {
    a.flatMap { a in b.flatMap { b in c.flatMap { c in d.map { d in (a, b, c, d) } } } }
}


public func cartesianProduct5<A, B, C, D, E>(_ a: [A], _ b: [B], _ c: [C], _ d: [D], _ e: [E]) -> [(A, B, C, D, E)] {
    a.flatMap { a in b.flatMap { b in c.flatMap { c in d.flatMap { d in e.map { e in (a, b, c, d, e) } } } } }
}
