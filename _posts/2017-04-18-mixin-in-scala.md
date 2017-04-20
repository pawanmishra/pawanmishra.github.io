---
layout: single
title: Mixin in Scala
tags: [Scala]
excerpt: In this blog post, we will look into how Scala provides support for mixins via traits. Mixin allow classes to provide functionalities to other classes without making the other classes inherit from them.
---
{% include base_path %}

Wikipedia defines mixin as :

> In object-oriented programming languages, a mixin is a class that contains methods for use by other classes without having to be the parent class of those other classes. How those other classes gain access to the mixin's methods depends on the language. Mixins are sometimes described as being "included" rather than "inherited". 

The definition sounds similar to decorator pattern but the key words to note here are : "included" rather than "inherited". I will not go into the details of decorator pattern but understanding of decorator pattern will help you in appreciating the ease of use of mixins. You can read more about decorator pattern [here](https://en.wikipedia.org/wiki/Decorator_pattern).

### Mixin in Action
---

Consider the following **DBConn** class in action, which returns well formatted connection string based on input parameters.

```scala
class DBConn {
  def getConnectionString(server: String, database: String, username : String, password : String): String = {
    s"server=$server;database=$database;username=$username;password=$password"
  }
}

val dbConn = new DBConn
println(dbConn.getConnectionString("test", "testDB", "myUser", "password"))

## OutPut
server=test;database=testDB;username=myUser;password=password
```

From the output, it's clear that although the code is working fine, it's lacking in security aspects. **DBConn** is returning password in raw text format. In some situation having password in raw text format is fine like when running app in local machine or while debugging database connection issues. And in all other cases, we would like the password to be encrypted before being used in connection string. Before we look at any solution, we do have to keep in mind other futuristic requirements like logging of connection string etc. We have following choices :

* Add encrypt functionality inside getConnectionString method & control its usage via flag. Using flag to control business logic is convoluted & with more requirements in future(e.g. log connection string) this will soon lead to highly convoluted codebase.
* Create new class which encrypts password & then invokes **DBConn** getConnectionString method. Basically a decorator class. This is clean but with new requirements like add logging support, logging & encryption support etc. Using decorators will cause flooding of decorator classes. 
* Use mixin. Well this is what is post is about. From the wikipedia definition of mixin, we know that it involves "include" instead of "inherit". What we are looking for is standard encryption functionality provided by some class that can be included in **DBConn** class i.e. mix encryption in **DBConn** class.

Mixin in Scala is provided with the help of traits. Consider the following trait :

```scala
trait Encrypto {
  def encrypt(value : String) : String = value.foldLeft(0)((a,b) => a + b.toInt).toString
}
```

**Encrypto** provides a method called _encrypt_ which takes any string & encrypts it. Thus this trait can be used anywhere in our codebase. Let's see how we can use **Encrypto** to encrypt password.

```scala
val securedDBConn = new DBConn with Encrypto {
  override def getConnectionString(server: String, database: String, username: String, password: String): String = {
    val encryptedPassword = encrypt(password)
    super.getConnectionString(server, database, username, encryptedPassword)
  }
}

## Output
server=test;database=testDB;username=myUser;password=883
```

Notice how without even modifying the code of **DBConn** class, we have mixed the encryption functionality. To mixin traits, we use the with keyword. Mixins are not limited to just one trait. We can add other traits using additional with keywords. For e.g. if we want to add logging support along with encryption then we can do the following :

```scala
trait Logger {
  def log(value : String) : Unit = println("Logged : " + value)
}

val securedLoggedDBConn = new DBConn with Encrypto with Logger {
  override def getConnectionString(server: String, database: String, username: String, password: String): String = {
    val encryptedPassword = encrypt(password)
    val connectionString = super.getConnectionString(server, database, username, encryptedPassword)
    log(connectionString)
    connectionString
  }
}

## Output
server=test;database=testDB;username=myUser;password=883
Logged : server=test;database=testDB;username=myUser;password=883
```

From the above code, it's clear that the Logger & Encrypto traits can be mixed with other classes & thus mixins increases code reusability. It prevents or helps in bypassing the limitation of multiple inheritance & also helps in avoiding creation of stand alone decorator style classes. 

