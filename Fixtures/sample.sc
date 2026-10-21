// Scala script
case class Point(x: Int, y: Int)

val points = List(Point(1, 2), Point(3, 4))
println(points.map(p => p.x + p.y).sum)
