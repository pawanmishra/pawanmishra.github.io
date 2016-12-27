---
layout: single
title: Advent Of Code - Day 1: No Time for a Taxicab
tags: [Scala]
excerpt: I recently came across this site called [Advent Of Code](http://adventofcode.com/) which lists set of problems in increasing order of complexity. If you are like me, trying to learn new programming language(in my case it's Scala), then solving handful of such problems will greatly expedite your learning process.
---
{% include toc %}

I recently came across this site called [Advent Of Code](http://adventofcode.com/) which lists set of problems in increasing order of complexity. If you are like me, trying to learn new programming language(in my case it's Scala), then solving handful of such problems will greatly expedite your learning process.

> If you find [Advent Of Code](http://adventofcode.com/) problems difficult then you can try [99 Problems](http://aperiodic.net/phil/scala/s-99/). Problems are grouped in easy, medium & difficult category & are backed by well implemented solutions.

> Spoiler: If you haven't solved the problem on your own then I would highly recommend giving it a try once. Remember : first solve the problem then solve it properly.

### Day 1: No Time for a Taxicab
---

Given below is the working but not so good solution for **Day 1: No Time for a Taxicab** problem.

#### Not So Functional
---

```scala
case class Movement(direction: String, length: Int)
val input = "R4, R4, L1, R3"
var position = (0,0)
val coordinates = input.split(", ").map(x => Movement(x.charAt(0).toString, x.substring(1).toInt)).toList

def findDistance(data: List[Movement]): Unit = {

  val visited = scala.collection.mutable.Stack[(Int, Int)]((0,0))

  def newDirection(currentDirection: String, movement: Movement): String = {
    currentDirection match {
      case "C" => if(movement.direction.equalsIgnoreCase("R"))
        {
          position = (position._1 + movement.length, position._2)
          "E"
        }
        else
        {
          position = (position._1 - movement.length, position._2)
          "W"
        }
      case "N" => if(movement.direction.equalsIgnoreCase("R")) {
        position = (position._1 + movement.length, position._2)
        "E"
      } else {
        position = (position._1 - movement.length, position._2)
        "W"
      }
      case "E" => if(movement.direction.equalsIgnoreCase("R")) {
        position = (position._1, position._2 - movement.length)
        "S"
      } else {
        position = (position._1, position._2 + movement.length)
        "N"
      }
      case "W" => if(movement.direction.equalsIgnoreCase("R")) {
        position = (position._1, position._2 + movement.length)
        "N"
      } else {
        position = (position._1, position._2 - movement.length)
        "S"
      }
      case "S" => if(movement.direction.equalsIgnoreCase("R")) {
        position = (position._1 - movement.length, position._2)
        "W"
      } else {
        position = (position._1 + movement.length, position._2)
        "E"
      }
    }
  }

  def updateVisited(position: (Int, Int)): Unit = {
    val top = visited.top

    val coordinates = if (top._1 == position._1) {
      val rangeBy = if (top._2 > position._2) -1 else 1
      for (i <- top._2 to position._2 by rangeBy) yield (top._1, i)
    }
    else {
      val rangeBy = if (top._1 > position._1) -1 else 1
      for (i <- top._1 to position._1 by rangeBy) yield (i, top._2)
    }

    for(i <- coordinates.tail) {
      val exists = visited.exists(x => x._1 == i._1 && x._2 == i._2)

      if (exists)
        println(math.abs(i._1) + math.abs(i._2))
      else
        visited.push(i)
    }
  }

  def walk(data: List[Movement], direction: String): Unit = {
    data match {
      case head::tail =>
        val newPosition = newDirection(direction, head)
        updateVisited(position)
        walk(tail, newPosition)
      case _ => println(math.abs(position._1 - 0) + math.abs(position._2 - 0))
    }
  }

  walk(data, "C")
}

findDistance(coordinates)
```

##### Discussion
---

* **Movement** case class is for representing each move. It contains two field. One for representing the direction & other the movement length.
* **position** is mutable tuple & it represents the x & y coordinate. It's used for tracking the current position. 
* **coordinates** is initialized by splitting the input variable & then mapping those splitter values into individual **Movement** case class instance.
* **findDistance** function contains nested function : newDirection, updateVisited & walk function. It's common pattern in functional programming to nest functions inside another function. In our case, we are only concerned in exposing function which takes coordinates as input & calculating the final distance. Instead of writing one monolithic function block, its good practice to break down the work in smaller chunks & compose the functions together.
* **newDirection** function accepts movement & current direction of movement & determines the updated direction post movement. It also updates the **position** mutable tuple variable.
* **updateVisited** is used for solving 2nd part of the problem. I will not go into the detail of this function.
* **walk** function combines the other function & recursively invokes the newDirection & updateVisited function in solving the problem. 
* In the end of **findDistance** function, I invoke **walk** function with initial seed data i.e. list of movements & station position which is Center("C").

##### Problems
---

* Use of mutable **position** variable. Mutability is not much appreciated in functional programming world.
* Exceedingly lengthy **newDirection** function. Repetitive assignment & modification of **position** variable.
* Hard to read & modify solution.

In the below solution, I have modified the **newDirection** function by breaking down the code re-usable chunks of small functions. As you will see below, the new code is much more readable & short.

#### Somewhat Functional
---

```scala
case class Movement(direction: String, length: Int)
val input = "R4, R4, L1, R3, L5, R2, R5, R1, L4, R3, L5, R2, L3, L4, L3, R1, R5, R1, L3, L1, R3, L1, R2, R2, L2, R5, L3, L4, R4, R4, R2, L4, L1, R5, L1, L4, R4, L1, R1, L2, R5, L2, L3, R2, R1, L194, R2, L4, R49, R1, R3, L5, L4, L1, R4, R2, R1, L5, R3, L5, L4, R4, R4, L2, L3, R78, L5, R4, R191, R4, R3, R1, L2, R1, R3, L1, R3, R4, R2, L2, R1, R4, L5, R2, L2, L4, L2, R1, R2, L3, R5, R2, L3, L3, R3, L1, L1, R5, L4, L4, L2, R5, R1, R4, L3, L5, L4, R5, L4, R5, R4, L3, L2, L5, R4, R3, L3, R1, L5, R5, R1, L3, R2, L5, R5, L3, R1, R4, L5, R4, R2, R3, L4, L5, R3, R4, L5, L5, R4, L4, L4, R1, R5, R3, L1, L4, L3, L4, R1, L5, L1, R2, R2, R4, R4, L5, R4, R1, L1, L1, L3, L5, L2, R4, L3, L5, L4, L1, R3"
val coordinates = input.split(", ").map(x => Movement(x.charAt(0).toString, x.substring(1).toInt)).toList

def moveUp = (position: (Int, Int), length: Int) => (position._1, position._2 + length)
def moveDown = (position: (Int, Int), length: Int) => (position._1, position._2 - length)
def moveRight = (position: (Int, Int), length: Int) => (position._1 + length, position._2)
def moveLeft = (position: (Int, Int), length: Int) => (position._1 - length, position._2)

def findDistance(data: List[Movement]): Unit = {

  val visited = scala.collection.mutable.Stack[(Int, Int)]((0,0))

  def newDirection(currentDirection: String, direction: String):
    (((Int, Int), Int) => (Int, Int), String) = {
    (currentDirection, direction == "R") match {
      case ("C", isTrue) => if (isTrue) (moveRight, "E") else (moveLeft, "W")
      case ("N", isTrue) => if (isTrue) (moveRight, "E") else (moveLeft, "W")
      case ("E", isTrue) => if (isTrue) (moveDown, "S") else (moveUp, "N")
      case ("W", isTrue) => if (isTrue) (moveUp, "N") else (moveDown, "S")
      case ("S", isTrue) => if (isTrue) (moveLeft, "W") else (moveRight, "E")
    }
  }

  def updateVisited(position: (Int, Int)): Unit = {
    val top = visited.top

    val coordinates = if (top._1 == position._1) {
      val rangeBy = if (top._2 > position._2) -1 else 1
      for (i <- top._2 to position._2 by rangeBy) yield (top._1, i)
    }
    else {
      val rangeBy = if (top._1 > position._1) -1 else 1
      for (i <- top._1 to position._1 by rangeBy) yield (i, top._2)
    }

    for(i <- coordinates.tail) {
      val exists = visited.exists(x => x._1 == i._1 && x._2 == i._2)

      if (exists)
        println(math.abs(i._1) + math.abs(i._2))
      else
        visited.push(i)
    }
  }

  def walk(data: List[Movement], position: (Int, Int), direction: String): Unit = {
    data match {
      case head::tail =>
        val nextMove = newDirection(direction, head.direction)
        val newPosition = nextMove._1(position, head.length)
        updateVisited(newPosition)
        walk(tail, newPosition, nextMove._2)
      case _ => println(math.abs(position._1) + math.abs(position._2))
    }
  }

  walk(data, (0, 0), "C")
}

findDistance(coordinates)

```

As you can see the **newDirection** method is now much small & is easy to read. I have extracted the if-else block & replaced it with smaller functions like moveUp, moveDown etc. All this is possible because of Scala's ability of treating functions as objects. This allows functions to be treated as objects i.e. functions can be passed as input arguments, can be returned as value. 

I do understand that the above code can still be significantly improved specially the **updateVisited** block. Also string constants like "N", "S" etc can be replaced with enums. I think for Day 1 problem, the solution listed above is sufficient. As I move forward, I will try to learn & improve my Scala skills by incorporating Scala's core & advanced language traits in my solutions.

Thanks.
