---
layout: splash
title: Logback for Beginners
tags: [Java, Logback]
excerpt: In this blog post, I am going to explain two key concepts of logging - ***log levels*** & ***logger hierarchy*** using [**logback**](http://logback.qos.ch) logging framework. 
---
{% include toc %}
In this blog post, I am going to explain two key concepts of logging : ***log levels*** & ***logger hierarchy*** using [**logback**](http://logback.qos.ch) logging framework. 

> Note: If you have time & patience then go through the official documentation of [logback](http://logback.qos.ch) framework. It does an excellent job of explaining the topics that are covered in this blog post. Concepts presented in this post are influenced by the material present in the official documentation.

### Outline
---
This post is divided into following sections:

* SetUp
* Explaing log level
* Explaining log hierarchy

Let's get started.

### SetUp
---
Setup involved creating sample maven based java project & adding logback dependencies. Go ahead and create a new maven based project called **logback-tutorial**.

#### Adding logback dependencies
---
The very first thing that we have to do is add [**logback**](http://logback.qos.ch) related dependencies in ***pom.xml** file. Add the below markup in pom.xml file of your project:

```xml
<dependencies>
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
```

We have included following depenedencies in our project:

* **org.codehaus.groovy** : groovy compiler for parsing **logback.groovy** file. We will discuss more on this later in the post.
* **org.slf4j** : Includes the standard [slf4j](http://www.slf4j.org) api implemented by **logback** framework.
* **ch.qos.logback** : Included the two core components of **logback** framework namely: logback-core & logback-classic.
* **org.apache.maven.plugins** : maven compiler plugin. With the help of **maven-dependency-plugin** we are basically copying all of the dependency jar files into ***~/target/lib/** directory. This allows us to run the main method via command :

>  **/usr/local/java18/bin/java -cp src/main/:target/classes/:target/lib/* Main**


#### Testing logback dependencies
---
With dependencies in place, lets create a small java based application & test **logbacks** logging functionalities.

> Note: Since we haven't defined any logging configuration yet, the logback framework will use default option of console based logging.

In your project, add **Main.java** file & add following code in the file:

```java
public class Main
{
  public static void main(String[] args) {
    Logger logger = LoggerFactory.getLogger(Main.class);
    logger.info("Starting main");
  }
}
```
Running the code will output following log statement in console:

```
22:02:55.751 [main] INFO  Main - Starting main
```
#### Adding logback.groovy configuration file
---
Normally logging configuration is done via xml files but with **logback** framework, we can do the log configuration via **logback.groovy** file. Go ahead and add **logback.groovy** with following content in your project at ***~/main/*** directory level.

```groovy
import ch.qos.logback.classic.encoder.PatternLayoutEncoder
import ch.qos.logback.core.ConsoleAppender
import ch.qos.logback.core.rolling.RollingFileAppender
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy

import static ch.qos.logback.classic.Level.INFO

appender("console", ConsoleAppender) {
    encoder(PatternLayoutEncoder) {
        pattern = "%d %level %logger - %msg%n"
    }
}

root(INFO, ["console"])
```
In the above configuration, we have defined a new **ConsoleAppender** and assigned it to **root** logger. **root** logger is the base logger from which all other loggers are derived. We will cover **root** logger in more detail when we will discuss logger levels. It's important to note that **logback** tries following steps when looking for **logback.groovy** file. Ensure that the **logback.groovy** file is present in the classpath:

>1. Logback tries to find a file called logback.groovy in the classpath.
2. If no such file is found, logback tries to find a file called logback-test.xml in the classpath.
3. If no such file is found, it checks for the file logback.xml in the classpath..
4. If neither file is found, logback configures itself automatically using the BasicConfigurator which will cause logging output to be directed to the console.

Running the code via command
> **/usr/local/java18/bin/java -cp src/main/:target/classes/:target/lib/* Main**

will result in following output:
```
2016-08-13 22:29:35,702 INFO ROOT - Starting main
```

This completes the setup. It's time to understand the concept of **log levels**.

### Log Levels
---
As mentioned before, logback is logging framework which provides implementation for logging api defined in slf4j framework. Following are the printing methods available in **Logger** interface:

```java
package org.slf4j; 
public interface Logger {

  // Printing methods: 
  public void trace(String message);
  public void debug(String message);
  public void info(String message); 
  public void warn(String message); 
  public void error(String message); 
}
```

In our code, we can invoke any of the above mentioned methods on **Logger** instance. So what is the difference between calling **logger.trace() vs logger.debug()**?

Calling trave vs debug makes no difference as far calling code is concerned. The difference lies with the **logger** i.e. ***whether the logger is configured to handle incoming messages of type trace or debug or not***?

#### Log level priorities
---

If we assign priorities to each levels, then logback framework treats these levels in following priority order:

> **TRACE < DEBUG < INFO < WARN < ERROR**

In our setup code, our root logger is set to handle messages of level INFO. Go ahead and change the calling code & replace logger.info() with logger.debug().

```java
public static void main(String[] args) {
    Logger logger = LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
    logger.debug("Starting main");
  }
```
Run the code and you will be surprised that nothing is printed. Next, replace **logger.debug()** with **logger.warn()**.

```java
public static void main(String[] args) {
    Logger logger = LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
    logger.warn("Starting main");
  }
```

And this time you will find that logger logs the statement. Idea here simple:

> **Important : Any logger with level X will be able to handle messages of level X or messages of level Y where Y >= X.**

You can read about the logger selection process [here](http://logback.qos.ch/manual/architecture.html#basic_selection).

It's such a minor but very important detail. I have personally experienced & seen others getting confused whether we should call logger.info() or logger.debug() methods. 

### Logger hierarchy
---

This is yet another important & interesting concept of configring loggers. Before we get to the theory, go ahead & replace **logback.groovy** file with following content.

```groovy
import ch.qos.logback.classic.encoder.PatternLayoutEncoder
import ch.qos.logback.core.ConsoleAppender
import ch.qos.logback.core.rolling.RollingFileAppender
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy

import static ch.qos.logback.classic.Level.DEBUG
import static ch.qos.logback.classic.Level.INFO
import static ch.qos.logback.classic.Level.WARN

appender("console1", ConsoleAppender) {
    encoder(PatternLayoutEncoder) {
        pattern = "%d %-8X{name} loglevel=%-6p category=%c message=%m%n"
    }
}

appender("console2", ConsoleAppender) {
    encoder(PatternLayoutEncoder) {
        pattern = "%d %-8X{name} loglevel=%-6p category=%c message=%m%n"
    }
}

logger("com.pawan.logger", INFO, ["console1"])
logger("com.pawan.logger.test", INFO, ["console2"])
```

In the above configuration, I have created two loggers **com.pawan.logger** and **com.pawan.logger.test** and each of the these loggers have been assigned a different appender namely console1 & console2. Next, go ahead and replace existing java code with following & run the program:

```java
  public static void main(String[] args) {
    Logger logger = LoggerFactory.getLogger("com.pawan.logger");
    logger.info("Starting main!!");
    System.out.println("*******************");
    logger = LoggerFactory.getLogger("com.pawan.logger.test");
    logger.info("Starting main again!!");
  }
```

Running the above code with new **logback.groovy** file config generates the following output:

```
2016-08-14 00:05:22,736          loglevel=INFO   category=com.pawan.logger message=Starting main!!
*******************
2016-08-14 00:05:22,739          loglevel=INFO   category=com.pawan.logger.test message=Starting main again!!
2016-08-14 00:05:22,739          loglevel=INFO   category=com.pawan.logger.test message=Starting main again!!
```

When logger.info() was called for **com.pawan.logger** only one log statement was printed but when invoked for **com.pawan.logger.test** then twice. ***Confused?*** This is because of **logger hierarchy** is in play here. 

> **Important: What logger hierarchy means is that a logger(X.Y) is automatically considered parent of all loggers named(X.Y.*). If parent logger is defined in configuration, then any log messages directed to child logger will also be handled by parent logger.**

In our case, **com.pawan.logger** is parent logger of **com.pawan.logger.test** logger. When we tried to log via **com.pawan.logger.test** then as per log hierarchy rules, the parent level logger also handled the request & logged the message. Once again go the official documentation [here](http://logback.qos.ch/manual/architecture.html#effectiveLevel) & make sure that you clearly understand the concept of logger hierarchy.

### Summary
---
Logging though often ignored is one of the most crucial component of any & all running applications out there. Having a solid understanding of how logging & logging framework works, is crucial in setting up efficient logging mechanism. In this post, I tried to cover the two most common but extremely important concept of logging. In future posts, I will concentrate on other aspects of logging like appenders or pattern layout.





