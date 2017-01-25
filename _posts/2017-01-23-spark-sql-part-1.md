---
layout: single
title: SparkSQL Getting Started
tags: [Scala, Spark]
excerpt: In this blog post, I am going to explain you the difference between covariance & contra-variance. If you are not familiar with these terms then let me tell you that its related to the way type parameters are handled(more on this) when defining generic types or methods.
---
{% include base_path %}
{% include toc %}

We can run spark applications in our dev machines either directly in IDE(e.g. IntelliJ) or by submitting the application via **spark-submit** shell script. 

> Spark requires Java runtime. Ensure that you have Java downloaded & configured in your machine. I have Java 1.8 configured in my machine. You can check Java version by running following command.

```shell
➜  ~ java -version
java version "1.8.0_60"
Java(TM) SE Runtime Environment (build 1.8.0_60-b27)
Java HotSpot(TM) 64-Bit Server VM (build 25.60-b23, mixed mode)
``` 

### Configuring Spark in local
---

First download Spark binaries from here : [download](http://spark.apache.org/downloads.html). Do not change any of the selected values & do not worry about **hadoop** binaries included in downloaded artifacts. You can very well run Spark applications in your local even if you do not have **hadoop** configured in your machine.

Since Spark framework is in active development mode & new releases are shipped very frequently, we will have to configure Spark in such a way that maintaining Spark across versions doesn't require too many changes in paths, directory structure & environment variables.

Inside your user home directory(/home/<user>), create new directory called _bin_. And inside _bin_ directory, create _sparks_ directory.

```shell
~ mkdir bin
~ cd bin
~ mkdir sparks
```

Next, unzip & copy the downloaded Spark binaries inside **~/bin/sparks/** directory. I have two versions of Spark downloaded in my machine. Running **ls -ltr** command returns the following:

```shell
➜  bin ls -ltr sparks
total 0
drwxr-xr-x@ 17 Users  578 Dec 10 00:59 spark-2.0.2-bin-hadoop2.7
drwxr-xr-x@ 17 Users  578 Dec 10 01:06 spark-2.0.0-bin-hadoop2.7
```
Next we will create a symbolic link that will point to the version of spark, we want to treat as default for our machine. Run the following command from inside **bin** directory:

```shell
~ ln -s sparks/spark-2.0.2-bin-hadoop2.7 spark
```

Running **ls -ltr** command should return the following:

```shell
drwxr-xr-x  4 136 Dec 10 00:58 sparks
lrwxr-xr-x  1 32 Dec 10 01:00 spark -> sparks/spark-2.0.0-bin-hadoop2.7
```
Next, lets configure Spark environment variable. Copy & paste the following lines in either of the files : .profile, .bashrc or .zshrc.

I am using zsh in my machine, so I had to update .zshrc file. If you are using bash shell then use **.bashrc**. Or better just create **.profile** file & add the lines there.

```shell
# SPARK Configuration
export SPARK_HOME=/Users/<username>/bin/spark
export PATH=$PATH:$SPARK_HOME/bin
```

Lets validate our installation process by starting **spark-shell**. If everything we have done till now is correct, then running **sparks-shell** command should start the Spark Shell.

```shell
➜  ~ spark-shell
17/01/24 09:43:05 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
17/01/24 09:43:06 WARN SparkContext: Use an existing SparkContext, some configuration may not take effect.
Spark context Web UI available at http://10.35.40.118:4040
Spark context available as 'sc' (master = local[*], app id = local-1485272586191).
Spark session available as 'spark'.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 2.0.0
      /_/

Using Scala version 2.11.8 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_60)
Type in expressions to have them evaluated.
Type :help for more information.

scala> :q

~
```

One last thing before we move onto to IntelliJ configuration. We should change Spark's default logging level to only log **WARN** messages instead of **INFO**. This prevents Spark from over-populating the console from log statements. 

```shell
~ cd $SPARK_HOME/conf/
~ cp log4j.properties.template log4j.properties
~ nano log4j.properties
~ # Set everything to be logged to the console
log4j.rootCategory=WARN, console <<-- Change INFO to WARN
log4j.appender.console=org.apache.log4j.ConsoleAppender
~ close nano editor & save the file
```

### Configuring IntelliJ
---

Download latest IntelliJ community edition from here : [download](https://www.jetbrains.com/idea/download/). Once downloaded, start IntelliJ & install Scala plugin via **IntelliJ IDEA -> Preferences -> Plugins -> Search for _Scala_**. Install the latest version. This is all that is required for configuring IntelliJ. In the next section, I will implement sample SparkSQL program in IntelliJ & show you how to configure Spark specific dependencies & run your Spark program directly from IntelliJ.

### SparkSQL Demo
---

Start IntelliJ and create new **Scala** project via _File -> New Project -> Scala -> Enter_ **SparkSqlRunner** in project name field and click finish.

> Before you click finish, ensure that project sdk is set to Java 1.0 & Scala sdk is set to 2.11.7

Next, lets add Spark dependencies. We will be adding following Spark dependencies to our project:

* org.scala-lang:scala-library:2.11.8
* org.apache.spark:spark-core_2.11:2.0.0
* org.apache.spark:spark-sql_2.11:2.0.0

Open up **Project Structure** window(File -> Project Structure) and add above mentioned dependencies by searching & adding them in _**Module -> dependencies**_ tab. Screenshot below.

{% include figure image_path="/assets/images/IntelliJ_Dependencies.png" alt="IntelliJ Dependencies" caption="Spark Dependencies" %}





