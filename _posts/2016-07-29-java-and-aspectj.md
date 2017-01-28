---
layout: splash
title: AOP in Java
tags: [Java, AspectJ]
excerpt: In this blog post, I am going to use an open source library called [**jcabi-aspects**](http://aspects.jcabi.com/index.html) for implementing ***loggable*** aspect.   
---
{% include toc %}
Have you ever found yourself in situation wherein your application is not behaving as expected in staging or production? If it's the case in your local, you can easily debug the code but debugging a remotly running application is not easy & definitly not recommened. In such situation, the very first thing that comes to our mind is **logging**.

Logging is simple & easy to implement. You want to log something, just go ahead & add the log statement in your code. The only issue with logging is that it's dependent upon the person adding the log statement. For some it's a good thing to have, for other's don't add unless it's really required. But once things start to go wrong in production, the very first thing we say to ourself is .. uhh I should have logged the method call. This is where [AOP](https://en.wikipedia.org/wiki/Aspect-oriented_programming)(Aspect Oriented Programming) comes into picture. The idea behind **AOP** is simple, you annotate your code & the AOP library replaces those annotations with appropriate runtime code. **AOP** is two step process :

* Language compiler compiles the code
* AOP library goes through the compiled class files & replaces the AOP specific annotations. This process is called [weaving](https://en.wikipedia.org/wiki/Aspect_weaver).

In this blog post, I am going to use an open source library called [**jcabi-aspects**](http://aspects.jcabi.com/index.html) for implementing ***loggable*** aspect.

Before we can see AOP in action, we will have to get following things done :

* Create new maven project
* Add dependency for
  * [**logback**](http://logback.qos.ch) library for logging
  * [**jcabi-aspects**](http://aspects.jcabi.com/index.html)
* SetUp logback logging framework
* Create relevant class & methods for AOP demo

So go ahead & create a new maven project & give it a name of your choice.

### Maven Dependencies
---
You can copy paste the content below in your pom.xml file & if you have enabled auto-import, then maven will download the relevant dependencies for you.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <dependencies>
        <dependency>
            <groupId>com.jcabi</groupId>
            <artifactId>jcabi-aspects</artifactId>
            <version>0.22.5</version>
        </dependency>
        <dependency>
            <groupId>org.aspectj</groupId>
            <artifactId>aspectjrt</artifactId>
            <version>1.8.9</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.codehaus.groovy</groupId>
            <artifactId>groovy-all</artifactId>
            <version>2.4.0</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
            <version>1.7.10</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-ext</artifactId>
            <version>1.7.10</version>
        </dependency>
        <dependency>
            <groupId>javax.mail</groupId>
            <artifactId>mail</artifactId>
            <version>1.5.0-b01</version>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-core</artifactId>
            <version>1.1.2</version>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
            <version>1.0.13</version>
            <exclusions>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-log4j12</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>log4j</groupId>
                    <artifactId>log4j</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>commons-logging</groupId>
                    <artifactId>commons-logging</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>log4j-bridge</artifactId>
            <version>0.9.7</version>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.5.1</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <artifactId>maven-dependency-plugin</artifactId>
                <executions>
                    <execution>
                        <phase>process-sources</phase>
                        <goals>
                            <goal>copy-dependencies</goal>
                        </goals>
                        <configuration>
                            <outputDirectory>target/lib</outputDirectory>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```
In the above pom files, we have included following dependencies :

* **aspectjrt** is the AOP library & jcabi-aspects contains the annotations that we are going to use in our application
* **logback** & dependent slf4j library dependencies for adding logging support
* **groovy-all** for parsing the logback.groovy file which in turn will contain our log configuration
* In the build section, I have included maven compiler plugin & configuration for copying dependency jars in ***target/lib*** directory

### logback configuration
---
Normally log configuration is done via xml file but we are going to use groovy script file. Add a file called **logback.groovy** at ~/src/main level and in that file add the following content :

```
import ch.qos.logback.classic.encoder.PatternLayoutEncoder
import ch.qos.logback.core.ConsoleAppender
import ch.qos.logback.core.rolling.RollingFileAppender
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy

import static ch.qos.logback.classic.Level.INFO

appender("console", ConsoleAppender) {
    encoder(PatternLayoutEncoder) {
        pattern = "%d %-8X{name} version=%-15X{version} loglevel=%-6p category=%-40.40c{0} message=%m%n"
    }
}

root(INFO, ["console"])
```
Unlike file based logging, we are going to log everything in console. Lets test if logging is working fine or not.

Add **Main.java** file at ***~src/main/java*** level and add the following content :

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Created by mishrapaw on 7/25/16.
 */
public class Main
{
    public static void main(String[] args) {
        Logger logger = LoggerFactory.getLogger(Main.class);
        logger.info("Starting main");
    }
}
```

Next we have to compile & run the code. For compilation run the following commands via command line :

```
mvn clean install
mvn compile
```

If compilation is successful, then we can go ahead & run the **main** method in Main.java class file via command :

```
/usr/local/java18/bin/java -cp target/classes/:target/lib/* Main
```
The code will run & it will print the following :

```
21:52:44.965 [main] INFO  Main - Starting main
```
With this we are done with our logging related work. Lets go ahead & experience AOP awasomness.

### AOP Annotations
In order to test, AOP in action, we are going to create a new class say Weaving.java & add some public methods to it. Next we will annotate that class & methods to see the AOP loggable behavior in action. Go ahead & add a class called **Weaving.java** with following code at ~/src/main/java level.

```java
import com.jcabi.aspects.Loggable;

@Loggable
public class Weaving
{
    public void printWeaving()
    {
        System.out.println("Printing waeving!!");
    }

    public void printWeavingMessage(String message)
    {
        System.out.println("Print message : " + message);
    }

    public String printAndReturnWeavingMessage(String message)
    {
        System.out.println("Print return message : " + message.toUpperCase());
        return message.toUpperCase();
    }

    public void printAnotherWeavingMessage()
    {
        System.out.println("Another waving message");
    }

    private void testMethod()
    {

    }
}
```
Notice that I have annotated the class with **@Loggable** annotation. Next in Main.java main method, add following lines :

```java
public static void main(String[] args) {
        Weaving weaving = new Weaving();
        weaving.printWeaving();
        weaving.printWeavingMessage("From main");
        weaving.printAndReturnWeavingMessage("fromMain");
    }
```

Next same old steps : 

```
$ mvn clean install
$ mvn compile
$ /usr/local/java18/bin/java -cp target/classes/:target/lib/* Main
```
The code will run fine but it print the following output, which though seems correct is not what we wanted. Did we forget something?

```
Printing waeving!!
Print message : From main
Print return message : FROMMAIN
```
In the beginning of the article, I mentioned about how AOP library weaves the class files & replaces the annotations with appropriate code. In our case, our code compiled fine but weaving didn't happen. You can confrm this by checking the **mvn compile** console log statements. In order to fix this just add the following plugin xml content in pom.xml file under <build><plugins> tag.

```xml
<plugin>
    <groupId>com.jcabi</groupId>
    <artifactId>jcabi-maven-plugin</artifactId>
    <version>0.9</version>
    <executions>
        <execution>
            <goals>
                <goal>ajc</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```
Next go ahead and run **mvn clean** followed by **mvn install** command. This time in console, you will see aspectj related log statements :

```
[INFO] --- jcabi-maven-plugin:0.9:ajc (default) @ aspectj-weaving ---
log4j:WARN No appenders could be found for logger (org.jboss.logging).
log4j:WARN Please initialize the log4j system properly.
log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
[INFO] JSR-303 validator org.hibernate.validator.internal.engine.ValidatorImpl instantiated by jcabi-aspects 0.10/7ee832c
[INFO] jcabi-aspects 0.10/7ee832c started new daemon thread jcabi-loggable for watching of @Loggable annotated methods
[INFO] jcabi-aspects 0.10/7ee832c started new daemon thread jcabi-cacheable for automated cleaning of expired @Cacheable values
AspectJ Internal Error: unable to add stackmap attributes. null
[WARNING] advice defined in com.jcabi.aspects.aj.ExceptionsLogger has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.Repeater has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.MethodValidator has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.SingleException has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.MethodInterrupter has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.QuietExceptionsLogger has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.Parallelizer has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.MethodAsyncRunner has not been applied [Xlint:adviceDidNotMatch]
[WARNING] advice defined in com.jcabi.aspects.aj.MethodCacher has not been applied [Xlint:adviceDidNotMatch]
[INFO] ajc result: 6 file(s) processed, 4 pointcut(s) woven, 0 error(s), 12 warning(s)
```
Inore the warning for now. The very last line says **ajc result: 6 file(s) processed, 4 pointcut(s) woven, 0 error(s), 12 warning(s)**. So now aspectjrt has weaved our class files. It's time to run our application.

```
/usr/local/java18/bin/java -cp target/classes/:target/lib/*  Main
```
But now you will get another crazy error :

```java
Exception in thread "main" java.lang.VerifyError: Expecting a stackmap frame at branch target 52
Exception Details:
  Location:
    WeavingTest/Weaving.printWeaving()V @15: ifne
  Reason:
    Expected stackmap frame at this location.
  Bytecode:
    0x0000000: b200 422a 2ab8 0048 4cb2 0067 b600 6d9a
    0x0000010: 0025 b800 5d05 bd00 0e4d 2c03 2a53 2c04
    0x0000020: 2b53 bb00 4d59 2cb7 0050 1251 b600 57b6
    0x0000030: 0061 57b1 2a2b b800 63b1       
        at Main.main(Main.java:13)
```
Well fixing this error is easy(discussing though is not, may be some other time). Just add **-noverify** flag to our previous statement :

```
/usr/local/java18/bin/java -cp target/classes/:target/lib/* -noverify Main
```
And this time the magic happens :

```
22:18:41.729 [main] INFO  com.jcabi.aspects.aj.NamedThreads - jcabi-aspects 0.22.5/4a18718 started new daemon thread jcabi-loggable for watching of @Loggable annotated methods
Printing waeving!!
22:18:41.754 [main] INFO  WeavingTest.Weaving - #printWeaving(): in 1.01ms
Print message : From main
22:18:41.756 [main] INFO  WeavingTest.Weaving - #printWeavingMessage('From main'): in 70.50µs
Print return message : FROMMAIN
22:18:41.757 [main] INFO  WeavingTest.Weaving - #printAndReturnWeavingMessage('fromMain'): 'FROMMAIN' in 55.11µs

```

As we can see from above, just by adding **@Loggable** annotation, the framework is logging for us the input & return values along with the total running time of the method.

### Update
---
The above mentioned error : "Expecting a stackmap frame at branch target 52" was happening because I was using old version of ***jcabi-maven-plugin***. Migrating to latest version(0.14) solves the problem. With the stackmap error gone, we won't require the **-noverify** flag as well.

### Summary
---
This is just the basic usage of **@Loggable** annotation. The annotation can be overloaded with additional flags and there are other annotations too that you can try & use as per your convinience. You can read more about it [here](http://aspects.jcabi.com/index.html).