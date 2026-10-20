import Foundation

/// A point in 2D space.
struct Point: Hashable {
    var x: Double
    var y: Double

    func distance(to other: Point) -> Double {
        ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
    }
}

let origin = Point(x: 0, y: 0)
print("Distance: \(origin.distance(to: Point(x: 3, y: 4)))") // 5.0
