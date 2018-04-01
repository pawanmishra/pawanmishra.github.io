---
title: Scala Topics - Covariance & Contravariance
tags: [Scala]
excerpt: In this blog post, I am going to explain you the difference between covariance & contra-variance. If you are not familiar with these terms then let me tell you that its related to the way type parameters are handled(more on this) when defining generic types or methods.
---
{% include toc %}

In this blog post, I am going to explain you the difference between covariance & contra-variance. If you are not familiar with these terms then let me tell you that its related to the way type parameters are handled(more on this) when defining generic types or methods.

The concept of variance is not specific to Scala. In fact the most clear & simple definition of these terms I have found is in excelled book called [**CLR via C#**](https://www.amazon.com/CLR-via-4th-Developer-Reference/dp/0735667454/ref=sr_1_1?ie=UTF8&qid=1483557398&sr=8-1&keywords=clr+via+c)

Before we dive into the code, lets go through the definition of variance from **CLR via C#**:

* **Invariant** : Meaning that the generic type parameter cannot be changed. 
* **Contra-variant** : Meaning that the generic type parameter can change from a _**class to a class derived from it**_. In C#, you indicate contra-variant generic type parameters with the **in** keyword. Contra-variant generic type parameters can appear only in input positions such as a method’s argument. In Scala you indicate contra-variant type parameter with **-** keyword.
* **Covariant** : Meaning that the generic type argument can change from a _**class to one of its base classes**_. In C#, you indicate covariant generic type parameters with the **out** keyword. Covariant generic type parameters can appear only in output positions such as a method’s return type. In Scala you indicate covariant type parameter with **+** keyword.

If you find the definitions too complex, then lets go through the code below. In the below code, I have defined an abstract class called **Person** from which **Manager** class is derived & from **Manager**, **Employee** class is derived. Next, I have created **Promotion** class which accepts input argument of type **Person** and calls method **promote**.

```scala
abstract class Person {
  def role() : String
}

class Manager extends Person {
  override def role = "Manager"
  def isManager = true
}

class Employee extends Manager {
  override def role = "Employee"
  override def isManager = false
}


class Promotion[A <: Person](arg: A) {
  def promote() = println(arg.role + " promoted")
}
```
> Notice the **<:** symbol. This symbol is used to denote what is called upper bound type. You can read more about it [here](http://docs.scala-lang.org/tutorials/tour/upper-type-bounds).

Next we will create instances of each of these classes.

```scala
val employee = new Employee
val manager = new Manager

var employeePromotion = new Promotion(employee)
employeePromotion.promote

var managerPromotion = new Promotion(manager)
managerPromotion.promote
```

Notice I have declared the employee & manager instance using **val** keyword & promotion related instances using **var** keyword. With **val**, once initialized, you cannot reassign the variable. I have purposefully declared the promotion instances with var keyword because I will reassign the instances to explain the concept of variance.

### Invariant
---

In the case of **promotion** class declaration, the type parameter is defined without any **+** or **-** sign. These types are called **Invariant** types. Types declared with invariant type parameters cannot be assigned to child or super class instances. For e.g. trying to the following will result in error :

```scala
employeePromotion = managerPromotion
Or
managerPromotion = employeePromotion
```

I am sure in all of your generics related programming, you wouldn't have thought about type parameters in terms of variance etc. Defining **invariant** types is perfectly fine but when you need more control on your type parameters thats when you get into the world of covariance & contra-variance.

### Covariance(+)
---

Lets redefine the **Promotion** with a plus(+) sign before type parameter A.

```scala
class Promotion[+A <: Person](arg: A) {
  def promote() = println(arg.role + " promoted")
}
```

Attempting to assign **employeePromotion** to **managerPromotion** works but vice-versa fails.

```scala
// This works
managerPromotion = employeePromotion
managerPromotion.promote()

// This doesn't
employeePromotion = managerPromotion
employeePromotion.promote()
```
From the definition of Covariance, the generic type argument can change from a class to its base class. In our case, employeePromotion instance type parameter **Employee** is inherits from **Manager**. Thus the assignment works but the opposite doesn't. 

### Contra-variance(-)
---

Lets redefine the **Promotion** with a minus(-) sign before type parameter A.

```scala
class Promotion[-A <: Person](arg: A) {
  def promote() = println(arg.role + " promoted")
}
```

Attempting to assign **managerPromotion** to **employeePromotion** works but vice-versa fails.

```scala
// This doesn't
managerPromotion = employeePromotion
managerPromotion.promote()

// This does
employeePromotion = managerPromotion
employeePromotion.promote()
```
From the definition of contra-variance, the generic type argument can change from a class to its derived class. In our case, employeePromotion instance type parameter **Employee** is descends from **Manager**. Thus the assignment works but the opposite doesn't. 

### Use Case
---

Consider the [Function1](http://www.scala-lang.org/api/2.9.2/scala/Function1.html) trait in Scala. As per its definition(given below), the input parameter T1 is marked as contra-variant & output parameter R is marked as covariant.

```scala
trait Function1[-T1, +R] extends AnyRef
```

Now consider the below function definition:

```scala
val isManager: Function1[Manager, Boolean] = input => input.isManager
isManager(manager)
```

isManager function accepts manager instance & invokes the input.isManager on manager instance. Return value as expected is **true**. Next lets assign the isManager function to another variable but of type **Function1[Employee, Boolean]**.

```scala
val isEmployeeManager: Function1[Employee, Boolean] = isManager
isEmployeeManager(employee)
```

Since Employee is derived from Manager & the function definition is contra-variant on input parameter i.e. it allows derived types, the above code works fine & prints **false**.

Finally we will assign the isManager instance to another variable of type **Function1[Person,Boolean]**.

```scala
val isPersonManager: Function1[Person, Boolean] = isManager
```

Since Person is not a manager, the above code throws compilation exception.

As you can see, covariance & contra-variance allows required flexibility in code while avoiding improper type assignments. If **Function1** wouldn't have been defined in terms of variance i.e. no + or - then the assignments would have failed & we would have been required to create new types for every input combination.




