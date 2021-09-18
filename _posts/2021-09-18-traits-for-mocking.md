---
layout: post
title: Mock External Dependencies via Traits
tags: [Scala]
excerpt: In this short blog post, I will give an example wherein we will see how with the help of Scala trait's we can mock external dependencies.
---
{% include base_path %}
{% include toc %}

In my current Scala based project, we have code that interacts with external resources like writing data to AWS S3 bucket or extracting information from Oracle database, etc. Back During my .Net & Java programming days, we used dependency injection & mocking frameworks for mocking external dependencies in our unit tests. In the post, I will show you, how [traits](https://docs.scala-lang.org/overviews/scala-book/traits-abstract-mixins.html) can help us in mocking the external dependencies in our tests.

Consider the following class -

```scala
class MyClass {  
  /**
    * Persist method depends on an external resource like S3 or Relation database, etc.
    */
  def persist(data: Integer): Unit = {
  }
}
```

In our unit test class, it isn't going to be easy to mock the external dependency. With the help of [traits](https://docs.scala-lang.org/overviews/scala-book/traits-abstract-mixins.html), we can solve this problem. First step is to define a trait and move the functionality to inside the trait. 

```scala
trait SaveData {
  /**
    * Move the code that depends on external resource within the process method
    */
  def process(data: Integer): Unit = {
  }
}
```

Next, extend the class with the above trait and invoke the process method from inside the persist method.

```scala
class MyClass extends SaveData {
  def persist(data: Integer): Unit = {
    process(data)
  }
}
```

Now that the code that interacts with external resource has been migrated and encapsulated inside a trait, we can now easily mock the trait in our unit test class. See below -

```scala
val myClass = new MyClass with SaveData {
  override def process(data: Integer): Unit = {
    println(data)
    // we can assert or do other any computation here
  }
}
```

Idea here is to create an instance of MyClass class and apply the SaveData trait at instance level. Notice how we are overriding the process method and applying test specific logic. You can run this code in Scala repl. If I invoke myClass.persist(100) then the above code will print 100 on the console. 