---
layout: single
title: Advent Of Code - Day 2 Bathroom Security
tags: [Scala]
excerpt: In this post, I am going to share the solution of **Day 2 Bathroom Security** problem from [Advent Of Code](http://adventofcode.com/) site.
---
{% include toc %}

In this post, I am going to share the solution of **Day 2 : Bathroom Security** problem. 

### Problem Definition
---

You can go through the problem definition [here](https://adventofcode.com/2016/day/2). The key thing in solving this problem was the representation of the numeric keypad. 

| 1 |2|3|
|---|---|---|
|4|5|6|
|7|8|9|

First instinct is to represent the above grid using two dimensional array. The solution will work but code will become overly complicated because of all of the boundary conditions. In the solution below, I have created two maps : one for mapping number against grid position(1 -> (0,0)) & another map which is basically reverse of the first one i.e. ((0,0) -> 1). From the code below, you will be able to understand how the two maps helped me in solving the problem.

### Solution
---

```scala
import scala.io.Source

val fileName = "/Users/mishrapaw/ScalaInAction/src/main/resources/Day2Input.txt"
val directions = { for (line <- Source.fromFile(fileName).getLines) yield line } toList

/* For Part 1
val keyToIndex = Map(
  1 -> (0,0),
  2 -> (0,1),
  3 -> (0,2),
  4 -> (1,0),
  5 -> (1,1),
  6 -> (1,2),
  7 -> (2,0),
  8 -> (2,1),
  9 -> (2,2))

val indexToKey = keyToIndex.map(x => (x._2 -> x._1))
*/

// For Part 2
val keyToIndex = Map(
  "1" -> (0,2),
  "2" -> (1,1),
  "3" -> (1,2),
  "4" -> (1,3),
  "5" -> (2,0),
  "6" -> (2,1),
  "7" -> (2,2),
  "8" -> (2,3),
  "9" -> (2,4),
  "A" -> (3,1),
  "B" -> (3,2),
  "C" -> (3,3),
  "D" -> (4,2))

val indexToKey = keyToIndex.map(x => (x._2 -> x._1))

def getCode(lines: List[String]): Unit = {

  def movement(key: String, direction: Char): String = {
    val position = keyToIndex.get(key).get
    val newPosition = direction match {
      case 'U' => (position._1 - 1, position._2)
      case 'D' => (position._1 + 1, position._2)
      case 'L' => (position._1, position._2 - 1)
      case 'R' => (position._1, position._2 + 1)
    }

    val newKey = indexToKey.get(newPosition)
    if (newKey.isDefined) newKey.get else key
  }

  def parse(data: List[String], key: String): Unit = {
    data match {
      case x::xs =>
        val finalKey = x.foldLeft(key)((k,t) => movement(k, t))
        print(finalKey)
        parse(xs, finalKey)
      case Nil => println("Done")
    }
  }

  parse(lines, "5")

}

getCode(directions)
```
Instead of manually creating the map(**keyToIndex**), you can also created it automatically using the below code :

```scala
val index = for (i <- 0 to 2; j <- 0 to 2) yield (i, j)
val keys = { for ((value, count) <- index.zip(Stream from 1)) yield (count -> value) } toMap
```
