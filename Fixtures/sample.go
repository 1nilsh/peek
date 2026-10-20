package main

import (
	"fmt"
	"math"
)

type Point struct{ X, Y float64 }

func (p Point) Distance(q Point) float64 {
	return math.Hypot(p.X-q.X, p.Y-q.Y)
}

func main() {
	fmt.Println(Point{0, 0}.Distance(Point{3, 4})) // 5
}
