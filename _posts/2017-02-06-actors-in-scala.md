---
title: Scala Topics - Actor Based Programming  
tags: [Akka, Scala, Spark]
excerpt: In this blog post, I am going to use Akka's Actor framework for implementing code for scoring Bowling game. Before getting into the code, I will provide quick introduction to Actors & components involved in actor based programming.
---
{% include base_path %}
{% include toc %}

Every programming language has support for building concurrent & parallel programs. Most languages provide support for writing concurrent applications via low level constructs like explicitly creating & managing threads. The only concern here is that writing highly concurrent programs using low level constructs is difficult & hard to get right. Thus majority of languages have come up with libraries & framework for writing concurrent programs e.g. C# has Task Parallel Library, Java has Executor class etc. In the world of Scala, you can implement concurrent programs using either [Akka's Actor](http://akka.io/) library or via [Futures](http://docs.scala-lang.org/overviews/core/futures.html).

### Akka
---

> Akka is an actor-based message-driven runtime for managing concurrency, elasticity and resilience on the JVM with support for both Java and Scala. 

Akka is a toolkit that provides support for building highly concurrent applications via low level entities called actors. Akka is an open source library, managed & supported by [Lightbend](http://www.lightbend.com/) Inc. Scala prior to 2.11 version had its own **scala.actors** library. Since 2.11, Scala has deprecated its own **scala.actors** package in favor of **akka.actors** package. You can include **akka.actors** as dependency in your project via one of the ways mentioned [here](http://akka.io/docs/).

#### Actors
---

As mentioned before, writing concurrent application using low level entities is hard & error prone. Actors provide an abstraction by being entities that encapsulate behavior & state. Common traits of actor include:

* Actors communicate with other actors by sending _immutable_ messages
* Internal state of Actors is completely shielded from other actors
* Actors can create other child actors & those child actors can create their own actors, forming a tree kind of hierarchy
* Because of hierarchy based system, actors also provide monitoring & supervision support for child actors
* Actors are lightweight entities & can be created in large numbers(dependening upon the use-case)
* Actors have lifecycle i.e. actors don't die after finishing their tasks. Actors have to be explicitly stopped or killed.

Once again, official [Akka](http://akka.io/docs/) documentation is the perfect place to read more about Actor based programming.

#### ActorSystem
---

In the previous section, I mentioned that an application can have multiple actors(and child actors). But before you can proceed with actors, you first have to create what is called an [ActorSystem](http://doc.akka.io/docs/akka/2.4/general/actor-systems.html). Unlike actors, _ActorSystem_ are heavy entities & its recommened to limit number of ActorSystem's to one per application. You will see in the section below on how to create _ActorSystem_ & use it for creating application specific actors.

In the section below, I am going to use the **akka.actors** package for implementing a small app for scoring Bowling application. As you will see, with actors & message passing, the intent & understandability of the application increases significantly.

### Bowling Code
---

With theory out of our way, its time to see the actors in action. In order to better understand actors, I decided to use them in implementing scoring of bowling game. If you are not familiar with how scoring works in bowling then watch this [video](https://www.youtube.com/watch?v=aBe71sD8o8c).

> Note : I have only tested happy path. The below code also doesn't cover the special case of 10th frame having three scores i.e. Spare or Strike. You can extend the code & try it yourself. 

```scala
import akka.actor._
import scala.collection.mutable
import scala.io.StdIn._

case object Start
case object Stop
case object Continue
case class Score(x: Int, y: Int)
case class Frame(x: Int, y: Int, var points: Int, var total: Int, movesPlayed: Int, waitForMoves: Int)

object BowlingRunner {
  def main(args: Array[String]): Unit = {
    val system = ActorSystem("BowlingActorSystem")
    val driverActor = system.actorOf(Props[Driver], "driver")
    driverActor ! Start
  }
}

class Driver extends Actor {
  val scorer = context.actorOf(Props[Scorer], "scorer")

  implicit def scoreToInt(s: String) = s match {
    case "X" => 10
    case "-" => 0
    case _ => s.toInt
  }

  def play: Unit = {
    val scoreX = readLine("Enter first score : ")
    val scoreY = readLine("Enter second score : ")
    scorer ! Score(scoreX, scoreY)
  }

  override def receive: Receive = {
    case Start => play
    case Continue => play
    case Stop => println("Game over!! Press ctrl+c to quit.")
    case _ => println("something wrong happened")
  }
}

class Scorer extends Actor {

  var queue = mutable.Queue[Frame]()
  var stack = mutable.Stack[Frame]()

  def shouldContinue: Unit = {
    stack.size match {
      case 10 => {
        println(s"Final Score : [${stack.head.x}][${stack.head.y}][${stack.head.total}]")
        sender() ! Stop
      }
      case 0 => sender() ! Continue
      case _ => {
        println(s"[${stack.head.x}][${stack.head.y}][${stack.head.total}]")
        sender() ! Continue
      }
    }
  }

  def updateScore(frame: Frame): Unit = {
    stack.headOption.isDefined match {
      case true => {
        frame.total += stack.head.total
        stack.push(frame)
      }
      case false => {
        stack.push(frame)
      }
    }
  }

  def enqueueFrame(frame: Frame): Unit = {
    frame.waitForMoves match {
      case x if (x > 0) => queue.enqueue(frame)
      case _ => updateScore(frame)
    }
  }

  def processQueue(points: Int): Unit = {
    val tempFrame = queue.dequeue()
    tempFrame.total = tempFrame.points + points
    updateScore(tempFrame)
  }

  def updateFrames(frame: Frame): Unit = {
    if (queue.headOption.isDefined) {

      (queue.head.waitForMoves, frame.movesPlayed) match {
        // Spare followed by Strike  
        case (1, 1) => processQueue(frame.points)
        // Spare followed by either Spare or regular frame
        case (1, 2) => processQueue(frame.x)
        // Strike followed by Strike
        case (2, 1) if (queue.length == 2) => processQueue(queue.tail.head.points + frame.points)
        // Strike followed by either Spare or regular frame
        case (2, 2) if (queue.length == 1) => processQueue(frame.points)
        // Strike followed by Strike followed by either Spare or regular frame
        case (2, 2) if (queue.length == 2) => {
          processQueue(queue.tail.head.points + frame.x)
          processQueue(frame.points)
        }
        case _ => {}
      }
    }

    enqueueFrame(frame)
    shouldContinue
  }

  override def receive: Receive = {
    case Score(x, y) => {
      (x, y) match {
        case (10, _) => updateFrames(Frame(10, 0, 10, 0, 1, 2))
        case (x, y) if (x + y == 10) => updateFrames(Frame(x, y, 10, 0, 2, 1))
        case _ => updateFrames(Frame(x, y , (x + y), (x + y), 2, 0))
      }
    }
  }
}
```

You can run the above code directly from IDE(IntelliJ) by adding Scala plugin & creating new **SBT** project. Once created, add the following dependency in **build.sbt** file.

```scala
libraryDependencies ++= Seq {
  "com.typesafe.akka" %% "akka-actor" % "2.4.16"
}
```

As mentioned before, the above code covers only _happy_ scenarios. Special or edge cases haven't been tested. If you run the following input(each line is a score of a given frame):

```
8 2     // Spare
7 3     // Spare
3 4
10 0    // Strike
2 8     // Spare
10 0    // Strike
10 0
8 -     // Miss
10 0    // Strike
7 1
```

then you should get the final score of **157**. 

#### Main Method
---

```scala
object BowlingRunner {
  def main(args: Array[String]): Unit = {
    val system = ActorSystem("BowlingActorSystem")
    val driverActor = system.actorOf(Props[Driver], "driver")
    driverActor ! Start
  }
}
```

Main method starts by instantiating [ActorSystem](http://doc.akka.io/docs/akka/2.4/general/actor-systems.html) & ActorSystem instance in turn creates **Driver** actor. finally, main method instructs _driverActor_ to start the game by sending **Start** message.

Any actor based application will have one & only one ActorSystem instance. ActorSystem creates root level actors & those actors in-turn creates child actors and so on. You can imagine the hierarch of ActorSystem & subsequent actors in form of tree data structure. You can read more about actor system [here](http://doc.akka.io/docs/akka/2.4/general/actor-systems.html). 

ActorSystem creates _driverActor_. Actors are lightweight entities taking roughly 300 to 600 bytes of space. Thus you can create large number of actors. Once actor is created, you interact with it by sending messages. In our case, we initiate conversation by sending simple [case](http://docs.scala-lang.org/tutorials/tour/case-classes.html) object instance called **Start**.

> **Case object vs class** : A case class can take arguments, so each instance of that case class can be different based on the values of it's arguments. A case object on the other hand does not take args in the constructor, so there can only be one instance of it (a singleton, like a regular scala object is). Source : [Stackoverflow](http://stackoverflow.com/questions/32078526/difference-between-case-class-and-case-object)

> **Important** : Notice how main method does nothing after sending nessage to _driverActor_. Normally this will cause the application to shutdown immediatly but this is not the case with **Actors**. Actors have definite lifecycle & are not automatically destroyed but instead have to be explicitly destroyed. There is a lot going on under the covers when it comes to actor lifecycle & the best place to read about it is official [Akka](http://doc.akka.io/docs/akka/2.4/scala.html) documentation.

#### Driver class
---

```scala
class Driver extends Actor {
  val scorer = context.actorOf(Props[Scorer], "scorer")

  implicit def scoreToInt(s: String) = s match {
    case "X" => 10
    case "-" => 0
    case _ => s.toInt
  }

  def play: Unit = {
    val scoreX = readLine("Enter first score : ")
    val scoreY = readLine("Enter second score : ")
    scorer ! Score(scoreX, scoreY)
  }

  override def receive: Receive = {
    case Start => play
    case Continue => play
    case Stop => println("Game over!! Press ctrl+c to quit.")
    case _ => println("something wrong happened")
  }
}
```

**Driver** class represents our first Actor & it does so by extending [Actor](http://doc.akka.io/docs/akka/2.4/scala/actors.html) trait. Doing so forces the actor class to implement the _**receive**_ method. Inside _receive_ method, actor provides relevant handlers for messages it intends to support via match block. In case of our _Driver_ actor we have following messages:

* Start : Coming from **Main** method. Triggers the game.
* Continue : Coming from **Scorer**. Requests **Driver** to accept next set of inputs.
* Stop : Coming from **Scorer**. Signals completion of game.

Once again, these messages are represented via **Case** objects.

```scala
case object Start
case object Stop
case object Continue
```

**Driver** actor creates child actor **Scorer** using _**context.actorOf(Props[Scorer], "scorer")**_. Driver's sole responsibility is to accept use input & forward it to **Scorer** & let **Scorer** do the hard work of managing the score. Messages are sent to **Scorer** in form of _Score_ case class which accepts two parameters namely scores within a given frame.

> **Note** : Score class accepts two _Int_ parameters. **readLine** method returns value of type _String_ i.e. scoreX & scoreY are of type String. Then how come automatically from the time variable are initialized & used, they are converted from String to Int? In other languages, converting from _String_ to _Int_ normally requires explicit casting like **(int)** or **Convert.toInt**. In our case, what we are seeing is yet another Scala compiler magic called **implicits** is in play. Before throwing compiler error, Scala compiler looks for any method that can convert _String_ to _Int_ and in our case that method is called **scoreToInt**. [Implicits](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html) is a broad topic & requires a blog post on its own.

#### Scorer class
---

```scala
class Scorer extends Actor {

  var queue = mutable.Queue[Frame]()
  var stack = mutable.Stack[Frame]()

  def shouldContinue: Unit = {
    stack.size match {
      case 10 => {
        println(s"Final Score : [${stack.head.x}][${stack.head.y}][${stack.head.total}]")
        sender() ! Stop
      }
      case 0 => sender() ! Continue
      case _ => {
        println(s"[${stack.head.x}][${stack.head.y}][${stack.head.total}]")
        sender() ! Continue
      }
    }
  }

  def updateScore(frame: Frame): Unit = {
    stack.headOption.isDefined match {
      case true => {
        frame.total += stack.head.total
        stack.push(frame)
      }
      case false => {
        stack.push(frame)
      }
    }
  }

  def enqueueFrame(frame: Frame): Unit = {
    frame.waitForMoves match {
      case x if (x > 0) => queue.enqueue(frame)
      case _ => updateScore(frame)
    }
  }

  def processQueue(points: Int): Unit = {
    val tempFrame = queue.dequeue()
    tempFrame.total = tempFrame.points + points
    updateScore(tempFrame)
  }

  def updateFrames(frame: Frame): Unit = {
    if (queue.headOption.isDefined) {

      (queue.head.waitForMoves, frame.movesPlayed) match {
        case (1, 1) => processQueue(frame.points)
        case (1, 2) => processQueue(frame.x)
        case (2, 1) if (queue.length == 2) => processQueue(queue.tail.head.points + frame.points)
        case (2, 2) if (queue.length == 1) => processQueue(frame.points)
        case (2, 2) if (queue.length == 2) => {
          processQueue(queue.tail.head.points + frame.x)
          processQueue(frame.points)
        }
        case _ => {}
      }
    }

    enqueueFrame(frame)
    shouldContinue
  }

  override def receive: Receive = {
    case Score(x, y) => {
      (x, y) match {
        case (10, _) => updateFrames(Frame(10, 0, 10, 0, 1, 2))
        case (x, y) if (x + y == 10) => updateFrames(Frame(x, y, 10, 0, 2, 1))
        case _ => updateFrames(Frame(x, y , (x + y), (x + y), 2, 0))
      }
    }
  }
}
```

**Scorer** actor class contains bulk of the game logic. It's _receive_ method accepts the score & handles it dependening upon whether the frame is Strike, Spare, Miss or regular strikes. It communicates with **Driver** actor via sending **Continue** & receiving **Score** message. After it's done with 10 frames, it signals **Stop** message asking **Driver** to stop the game. **Scorer** uses two mutable collections namely **Stack** & **Queue** for maintaining process & in-process frames. 

> Note : Pressing ctrl+c is not the right way to stop the application. Like I mentioned before, Actors have definite life cycle & there are explicit events & messages that can be used for stopping Actors & ActorSystem. Actor lifecycle is a topic for another blog post. For now, just press ctrl+c & stop the game.

### Summary
---

* Use of actors allows clear segregation of responsibilities
* Message passing between actors eases application complexity & makes the code easy to understand
* Scala's pattern matching makes the code concise & easy to understand
* Scala's case classes, objects, implicits etc adds to overall succinctness of code
* Communication between actors like getting started with actor based programming. Akka framework is quiet broad & there is a lot that you can do with actors like routing, persistence, remote communication etc. For more, refer the official wiki [here](http://doc.akka.io/docs/akka/2.4/scala.html).