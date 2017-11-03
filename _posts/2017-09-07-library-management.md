---
layout: single
title: Using Symbolic Links to Manage Libraries
tags: [Software]
excerpt: This post is quick tutorial on how you can easily manage & switch between different versions of programming libraries that you have configured in your machine with the help of symbolic links.
---

{% include base_path %}

This post is a quick tutorial on how you can easily manage & switch between different versions of libraries that you have configured in your machine with the help of symbolic links. I am currently working on Apache Spark based project & I have to download & configure not only spark but other libraries like hadoop, zeppelin & hive in my machine. These libraries are frequently released with major &minor updates. 

### SetUp
---

The idea here is to keep all the different versions of a given library in one place & create symbolic link against the version you want to use. Later, use that symbolic link in other places like .bash_profile or in custom scripts. In my machine, I have created a root level **_bin_** folder & inside that I have library specific directories. E.g. :

```shell
~ bin
~ bin/sparks/
~ bin/hdfs/
~ bin/zeppelins/
~ bin/hives/
```

Inside each of the library specific directory, I have the various version specific directory of that library. For e.g. inside ~/bin/sparks/, I have :

```shell
Dec 10  2016 spark-2.0.2-bin-hadoop2.7
Jan 29  2017 spark-2.0.0-bin-hadoop2.7
Feb 22  2017 spark-2.1.0-bin-hadoop2.7
Mar  2  2017 spark-1.6.1-bin-hadoop2.6
Sep  5 16:17 spark-2.2.0-bin-hadoop2.7
```

Next step is to create the symbolic link. I prefer to create symbolic links inside the _~/bin_ directory but outside any of the library specific directory. For e.g if I want to work with latest spark version, I will create symbolic link as :

```shell
➜  ln -snf ~/bin/sparks/spark-2.2.0-bin-hadoop2.7 ~/bin/spark
```

Once you have symbolic links in place, then you can easily switch it to point to another version e.g.

```
➜  ln -snf ~/bin/sparks/spark-2.0.2-bin-hadoop2.7 ~/bin/spark
```

Next, you can refer the symbolic link instead of actual library in places where you need the application reference. For e.g. I have the following *_HOME_* variables configured in my .zshrc file :

```
export SPARK_HOME=/Users/pawan/bin/spark
export PATH=$PATH:$SPARK_HOME/bin
```

This is it. With the help of symbolic link,s you can not only manage different versions of libraries, you can also seamlessly navigate across different versions of a given library. 