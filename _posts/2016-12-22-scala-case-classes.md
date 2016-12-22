---
layout: single
title: Scala Topics - Case Classes
tags: [Scala]
excerpt: In this blog post, I am going to cover Scala's [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) class functionality. Scala being functional programming language, introduces new programming constructs like Case classes, traits & other features to support & enhance functional programming experience. 
---
{% include toc %}

In this blog post, I am going to cover Scala's [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) class functionality. Scala being functional programming language, introduces new programming constructs like Case classes, traits & other features to support & enhance functional programming experience.

Before we deep dive into [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) classes, lets spend sometime looking into Scala's [Product](http://www.scala-lang.org/api/2.12.x/scala/Product.html) traits.

### scala.Product
---
You can think of Product as non-resizable collection of heterogeneous elements. Since Product is defined as trait, we cannot use Product trait directly in our code for storing data. Scala defines set of Product traits(all the way from Product1 till Product22) and all of these traits derive from base Product trait. You can see the actual source code of Product & its derived traits [here](https://github.com/scala/legacy-svn-scala/tree/master/src/library/scala). 
From the official definition of Product trait, we can see that all of the Tuple & Case classes are derived from corresponding Product trait.

> Base trait for all products, which in the standard library include at least scala.Product1 through scala.Product22 and therefore also their subclasses scala.Tuple1 through scala.Tuple22. In addition, all case classes implement Product with synthetically generated methods.

As we will see below, Product trait adds helpful methods to our [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) classes like getting size(number of arguments) or accessing argument values via index positions. 

### Case Classes
---
For the examples given below, you can either use Scala REPL or IDE of your choice. I prefer to use IntelliJ Scala worksheet feature. It provides REPL like functionality with side by side viewing of actual code & generated output. In IntelliJ first create a new worksheet called **CaseClasses.sc**. And in that worksheet, go ahead and define the following [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) class:

```scala
case class Person(firstName: String, lastName: String)
```

As soon as you hit enter, in the right hand panel you will notice instant feedback message i.e. **defined class Person**

Scala does support regular classes i.e. classes which doesn't require Case keyword. And in-fact [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) class too are like regular classes. You can defined additional methods inside the class, extend other classes & implement traits. Only difference is that by appending Case keyword, Scala compiler treats the class definition differently & performs additional work for you in order to support following use-cases :

* Immutability
* Pattern Matching support
* Structural equality instead of referential

We will look into the above aspects in detail but before that lets go ahead & compile our **CaseClasses.sc** class using **scalac** compiler & see what the generated classes look like.

```
scalac CaseClasses.sc
```
This will generate two class files namely : Person.class & Person$.class. Lets look at the class definition of these two classes. We will use the **javap** for dis-assembling our class files.

```java
$ javap Person.class
Compiled from "CaseClasses.sc"
public class Person implements scala.Product,scala.Serializable {
  public static scala.Option<scala.Tuple2<java.lang.String, java.lang.String>> unapply(Person);
  public static Person apply(java.lang.String, java.lang.String);
  public static scala.Function1<scala.Tuple2<java.lang.String, java.lang.String>, Person> tupled();
  public static scala.Function1<java.lang.String, scala.Function1<java.lang.String, Person>> curried();
  public java.lang.String firstName();
  public java.lang.String lastName();
  public Person copy(java.lang.String, java.lang.String);
  public java.lang.String copy$default$1();
  public java.lang.String copy$default$2();
  public java.lang.String productPrefix();
  public int productArity();
  public java.lang.Object productElement(int);
  public scala.collection.Iterator<java.lang.Object> productIterator();
  public boolean canEqual(java.lang.Object);
  public int hashCode();
  public java.lang.String toString();
  public boolean equals(java.lang.Object);
  public Person(java.lang.String, java.lang.String);
}

$ javap Person$.class
Compiled from "CaseClasses.sc"
public final class Person$ extends scala.runtime.AbstractFunction2<java.lang.String, java.lang.String, Person> implements scala.Serializable {
  public static final Person$ MODULE$;
  public static {};
  public final java.lang.String toString();
  public Person apply(java.lang.String, java.lang.String);
  public scala.Option<scala.Tuple2<java.lang.String, java.lang.String>> unapply(Person);
  public java.lang.Object apply(java.lang.Object, java.lang.Object);
}
```
So our one liner class definition has been transformed into two underlying classes with almost 20 different methods. In the following section, I will try to explain the methods with help of sample examples.

> Note : Person$.class is special kind of class called companion object. You can read more about the companion objects [here](http://docs.scala-lang.org/tutorials/tour/singleton-objects.html).

#### Apply vs UnApply
---

Apply & UnApply are special kind of methods available in Scala classes. Following is the implementation of apply & unapply method.

```scala
public Option<Tuple2<String, String>> unapply(Person x$0)
  {
    return x$0 == null ? None..MODULE$ : new Some(new Tuple2(x$0.firstName(), x$0.lastName()));
  }
  
  public Person apply(String firstName, String lastName)
  {
    return new Person(firstName, lastName);
  }
```
* Apply method as we can see is used to create new instance of Person class. 
* UnApply method on other hand is used to breakdown the Person instance into individual elements & return the result in the form of Tuple. 

Lets see the apply method in action.

```scala
val p1 = new Person("Pawan", "Mishra")
val p2 = Person("Pawan", "Mishra")
val p3 = Person.apply("Pawan", "Mishra")
```
In the above code block, we have created three instance of Person class. p1 is created using "new" keyword similar to Java & C# object instantiation approach. With [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) classes, "new" keyword is optional which is what we have used in case of p2. p3 on the other hand explicitly calls the apply method. In day to day programming, with case classes, you are going to use the 2nd(p2) approach. Scala compiler takes care of transforming your code & invoking the apply method. Next lets look at unapply methods magic.

```scala
val extract1 = Person.unapply(p2)
>> extract1: Option[(String, String)] = Some((Pawan,Mishra))
val Person(fName, lName) = p2
>> fName : Pawan
>> lName : Mishra
p2 match {
  case Person(f1, l1) => println("Hi " + f1 + " " + l1)
}
>> Hi Pawan Mishra
```
From the above code snippet, we are using unapply methods magic to deconstruct the person instance into its individual data elements. As we can see calling unapply method explicitly returns **Option[(String, String)]**. When used in assignment operations, then individual data elements from right hand side are mapped to corresponding elements on left hand side e.g. fName & lName values.
But the most important use case of unapply method is when used in pattern matching. This is one of the most important benefits of using [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) classes i.e. its support for pattern matching capabilities.

#### productArity, productElement & productIterator
---
These methods are rather simple. 

* productArity returns the number of arguments of Case class
* productElement allows accessing of arguments via index positions
* productIterator returns an iterator which can be used for going over arguments

Lets see the three methods in action.

```scala
p2.productArity
>> res1: Int = 2
p2.productElement(1)
>> res2: Any = Mishra
p2.productElement(0)
>> res2: Any = Pawan
val personIterator = p2.productIterator
personIterator.mkString("&")
>> res2: String = Pawan&Mishra
```

#### curreid
---

Currying is when you break down a function that takes multiple arguments into a series of functions that take part of the arguments. Below is the internal implementation of curried function.

```java
public static Function1<String, Function1<String, Person>> curried()
  {
    return Person..MODULE$.curried();
  }
```
Important thing to note here is the return value. Calling curried, returns a function which accepts a string parameter & that in-turn returns another function. Lets see the curried function in action.

```scala
val p4 = Person.curried("Trial")
>> p4: String => Person = scala.Function2$$Lambda$1259/716450481@2c1a7a0e
val p5 = p4("User")
>> p5: Person = Person(Trial,User)
```
When invoked with just one argument, then the return value is of type **scala.Function** which accepts another string as input parameter & returns **Person** instance. Later we invoke p4 function & provide another string argument. Finally p5 is just like any other Person instance. 

Function currying is really helpful in scenario wherein you want to control some part of the input arguments & leave other arguments open for consumers of your function.  For e.g. consider the below case class:

```scala
case class Connection(hostName: String, port: String)
```
Say you want to restrict the hostName to single value and only want users to provide port details, then you can do the following.

```scala
val portConnection = Connection.curried("127.0.0.1")
```
And now we can invoke portConnection with just port information & create new connection instance.

#### tuples
---

Tupled is relatively simple. It accepts tuple values as input parameters & returns the actual instance value.

```scala
val p7 = Person.tupled("Hello", "World")
>> p7: Person = Person(Hello,World)
```

#### Immutability
---

By default the arguments of Case classes are immutable. You cannot change the values once assigned. 

```scala
p2.lastName = "Bond" 
>> Error : reassignment to val
```
If required, we can change the constructor definition of case class and make the parameter mutable by appending **var** keyword.

```scala
case class Person(firstName: String, var lastName: String)
p2.lastName = "M"
>> p2.lastName: String = M
p2
>> res4: Person = Person(Pawan,M)
```
Similarly calling copy method creates new instance. 

```java
public Person copy(String firstName, String lastName)
  {
    return new Person(firstName, lastName);
  }
```
```scala
val p8 = p2.copy()
>> p8: Person = Person(Pawan,M)
p8.lastName = "T"
>> p8.lastName: String = T
p8
>> res5: Person = Person(Pawan,T)
p2
>> res5: Person = Person(Pawan,M)
```

### Conclusion
---
Immutability, pattern matching support & ease of instantiation make [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) classes great candidate for creating dto or model classes. If you have gone through the pain of implementing those placeholder classes with just getters & setters then the good news for you in the world of Scala is that you can get all of that done with just single line of [Case](http://docs.scala-lang.org/tutorials/tour/case-classes) class definition.  

