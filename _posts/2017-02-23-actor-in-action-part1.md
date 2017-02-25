---
layout: splash
title: Unhandled & Dead Messages in Akka  
tags: [Akka, Scala]
excerpt: In this blog post, we are going to look into two special cases of message delivery & its handling by the akka framework. First case involves sending invalid message & second case involves sending messages to dead actors. 
---
{% include base_path %}
{% include toc %}

In the previous [post]({% post_url 2017-02-06-actors-in-scala %}), we saw [Actor](http://doc.akka.io/docs/akka/current/scala/actors.html) based code in action. At the core of actor based programming lies the fact that all of the communication between actors happens via sharing of immutables messages. We can think of these messages as dialects of actors and an actor will only respond to messages it understands. In this post, we will look into following special cases of actors & messages :

* **Invalid message** : actor receives message it's not capable of handling aka UnhandledMessage
* **Late message** : actor receives message after it has died aka DeadLetter

## Unhandled Message
---

I wrote the following code snippet for illustrating our first use-case. 

```scala
case object Message
case object InValidMessage

object ActorsInAction {
  def main(args: Array[String]): Unit = {
    val system = ActorSystem("ActorSystem")
    val driverActor = system.actorOf(Props[MainActor], "mainActor")

    driverActor ! Message
    driverActor ! InValidMessage
    driverActor ! Message
  }
}

class MainActor extends Actor {
  def receive = {
    case Message => {
      println("Message Received")
    }
  }
}
```

* Case classes(Message & InValidMessage) represent our messages
* **driverActor** is [ActorRef](http://doc.akka.io/api/akka/2.0/akka/actor/ActorRef.html) of our **MainActor** actor class which can handle messages of type **Message**
* In main method, in between two valid **Message**, we have passed an invalid message(InValidMessage) to our **MainActor**

Running the app prints the following output:

```console
Message Received
Message Received
```

Nothing surprising in the output. We know InValidMessage was not handled but question is what happened to the message itself? Was it even delivered to the **MainActor**? Answer is yes. Message was indeed delivered to **MainActor**. But to better understand what happens to message after [Actor](http://doc.akka.io/docs/akka/current/scala/actors.html) receives it, we will have to look into [Actor](http://doc.akka.io/docs/akka/current/scala/actors.html) code itself. 

If you attach debugger & debug inside [Actor](http://doc.akka.io/docs/akka/current/scala/actors.html) code, then call to method **receive** will end up at :

```scala
/**
   * INTERNAL API.
   *
   * Can be overridden to intercept calls to this actor's current behavior.
   *
   * @param receive current behavior.
   * @param msg current message.
   */
  protected[akka] def aroundReceive(receive: Actor.Receive, msg: Any): Unit = {
    // optimization: avoid allocation of lambda
    if (receive.applyOrElse(msg, Actor.notHandledFun).asInstanceOf[AnyRef] eq Actor.NotHandled) {
      unhandled(msg)
    }
  }
```

Without going into too much details, we can see from the above if condition that if **receive** method is not capable of handling incoming message then it returns **Actor.notHandledFun** thus causing if condition to evaluate to true. **unhandled** method implementation is quiet straightforward :

```scala
/**
   * User overridable callback.
   * <p/>
   * Is called when a message isn't handled by the current behavior of the actor
   * by default it fails with either a [[akka.actor.DeathPactException]] (in
   * case of an unhandled [[akka.actor.Terminated]] message) or publishes an [[akka.actor.UnhandledMessage]]
   * to the actor's system's [[akka.event.EventStream]]
   */
  def unhandled(message: Any): Unit = {
    message match {
      case Terminated(dead) ⇒ throw new DeathPactException(dead)
      case _                ⇒ context.system.eventStream.publish(UnhandledMessage(message, sender(), self))
    }
  }
```

Inside **unhandled** method, since the incoming message is not of type **Terminated**, our InValidMessage is published onto the eventStream in form of **UnhandledMessage**. Can we handle **UnhandledMessage**? Yes we can. In the below code, we have created another actor meant specifically for handling **UnhandledMessage** and attached it as listener to the eventStream.

```scala
case object Message
case object InValidMessage

object ActorsInAction {
  def main(args: Array[String]): Unit = {
    val system = ActorSystem("ActorSystem")
    val driverActor = system.actorOf(Props[MainActor], "mainActor")
    val listener = system.actorOf(Props[DeadActorListener], "deadActor")
    system.eventStream.subscribe(listener, classOf[UnhandledMessage])

    driverActor ! Message
    driverActor ! InValidMessage
    driverActor ! Message
  }
}

class MainActor extends Actor {
  def receive = {
    case Message => {
      println("Message Received")
    }
  }
}

class DeadActorListener extends Actor {
  def receive = {
    case u: UnhandledMessage => println("Unhandled message " + u.message)
  }
}
```

Output :

```
Message Received
Message Received
Unhandled message InValidMessage
```

## DeadLetter Message
---

Lets extend our already running code snippet to highlight the scenario of late message i.e. message arriving while actor is shutting down or already dead.

```
case object Message
case object InValidMessage

object ActorsInAction {
  def main(args: Array[String]): Unit = {
    val system = ActorSystem("ActorSystem")
    val driverActor = system.actorOf(Props[MainActor], "mainActor")
    val listener = system.actorOf(Props[DeadActorListener], "deadActor")
    system.eventStream.subscribe(listener, classOf[UnhandledMessage])

    driverActor ! Message
    driverActor ! InValidMessage
    driverActor ! Message
    driverActor ! PoisonPill
    driverActor ! Message
  }
}

class MainActor extends Actor {
  def receive = {
    case Message => {
      println("Message Received")
    }
  }
}

class DeadActorListener extends Actor {
  def receive = {
    case u: UnhandledMessage => println("Unhandled message " + u.message)
  }
}
```

You kill an actor either by sending **PoisonPill** or by calling **system.stop(driverActor)**. [PoisonPill](http://doc.akka.io/docs/akka/current/scala/actors.html#PoisonPill) is a special kind of message which is automatically handled by [Akka](http://doc.akka.io/docs/akka/current/scala.html) framework. Other special messages include : _Kill, Terminated, Identify, ActorSelection etc_. Following code from **Actor.scala** class handles these special message types :

```scala
def autoReceiveMessage(msg: Envelope): Unit = {
    if (system.settings.DebugAutoReceive)
      publish(Debug(self.path.toString, clazz(actor), "received AutoReceiveMessage " + msg))

    msg.message match {
      case t: Terminated              ⇒ receivedTerminated(t)
      case AddressTerminated(address) ⇒ addressTerminated(address)
      case Kill                       ⇒ throw new ActorKilledException("Kill")
      case PoisonPill                 ⇒ self.stop()
      case sel: ActorSelectionMessage ⇒ receiveSelection(sel)
      case Identify(messageId)        ⇒ sender() ! ActorIdentity(messageId, Some(self))
    }
  }
```

Calling **stop()** causes the actor to shutdown itself & stop the message queue. Any message arriving in [MailBox](http://doc.akka.io/docs/akka/current/scala/mailboxes.html) of an actor after its marked dead, is treated as special case of what is called [DeadLetter](http://doc.akka.io/docs/akka/current/general/message-delivery-reliability.html). In our code, we can extend our listener actor to also listen for [DeadLetter]() messages.

```scala
case object Message
case object InValidMessage

object ActorsInAction {
  def main(args: Array[String]): Unit = {
    val system = ActorSystem("ActorSystem")
    val driverActor = system.actorOf(Props[MainActor], "mainActor")
    val listener = system.actorOf(Props[DeadActorListener], "deadActor")
    system.eventStream.subscribe(listener, classOf[UnhandledMessage])
    system.eventStream.subscribe(listener, classOf[DeadLetter])

    driverActor ! Message
    driverActor ! InValidMessage
    driverActor ! Message
    driverActor ! PoisonPill
    driverActor ! Message
  }
}

class MainActor extends Actor {
  def receive = {
    case Message => {
      println("Message Received")
    }
  }
}

class DeadActorListener extends Actor {
  def receive = {
    case u: UnhandledMessage => println("Unhandled message " + u.message)
    case d: DeadLetter => println("dead message " + d.message)
  }
}
```

Output :

```
Message Received
Message Received
Unhandled message InValidMessage
dead message Message
```

