---
layout: splash
title: Kafka - Getting Started
tags: [Kafka, Java]
excerpt: In this blog post, I am going to outline the steps required for setting up Kafka in your local development machine.
---
{% include toc %}
In this blog post, I am going to outline the steps required for setting up Kafka in your local development machine. Kafka is high-scalable distributed commit log management system. It allows multiple producers & consumers to simultaneously publish & consume messages. Kafka is at the core of todays massive streaming data architecture which powers companies like Netflix, AirBnB etc.

### Components

*   Zookeeper setup & startup
*   Kafka setup
*   [Kafka](http://kafka.apache.org) Brokers setup & startup
*   [Kafka](http://kafka.apache.org) Topic configuration
*   [Producers](http://kafka.apache.org/documentation.html#producerapi) & [Consumers](http://kafka.apache.org/documentation.html#consumerapi)

#### Zookeeper

* * *

[Zookeeper](http://zookeeper.apache.org) acts as centralized configuration & metadata management system. Kafka brokers persist cluster specific configuration with Zookeeper. Similarly consumers persist information like consumer offset with Zookeeper. Setting up Zookeeper involves :

*   Download Zookeeper binaries from here : [http://zookeeper.apache.org](http://zookeeper.apache.org "http://zookeeper.apache.org")
*   Unzip the content in directory of your choice. Once unzipped, navigate to the ~/zookeeper/conf/ directory.
*   Inside conf/ directory, create file called : zoo.cfg and add following content to it. You can most of the content inside zoo_sample.cfg inside the ~/conf/ directory.

```
# The number of milliseconds of each tick  
tickTime=2000  
# The number of ticks that the initial  
# synchronization phase can take  
initLimit=10  
# The number of ticks that can pass between  
# sending a request and getting an acknowledgement  
syncLimit=5  
# the directory where the snapshot is stored.  
# do not use /tmp for storage, /tmp here is just  
# example sakes.  
dataDir=/Users/pawan/Documents/mykafka/zookeeper_log  
# the port at which the clients will connect  
clientPort=2181  
# the maximum number of client connections.  
# increase this if you need to handle more clients  
#maxClientCnxns=60  
#  
# Be sure to read the maintenance section of the  
# administrator guide before turning on autopurge.  
#  
# http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance  
#  
# The number of snapshots to retain in dataDir  
#autopurge.snapRetainCount=3  
# Purge task interval in hours  
# Set to "0" to disable auto purge feature  
#autopurge.purgeInterval=1
```
Other than “dataDir” most of the values are default values. You can specify “dataDir” path as per your choice. Ensure that the path exists. Next, navigate to the dataDir path & inside the dataDir folder create a file called “**myid**”. The “myid” contains one integer number & that number could be anything. I have set it to 1.

It’s time to start zookeeper server & verify that things are working fine. Execute the command : **~/path of zookeeper/bin/zkServer.sh start**

You should expect following output :

```
ZooKeeper JMX enabled by default  
Using config: /Users/mishrapaw/Documents/mykafka/zookeeper-3.4.8/bin/../conf/zoo.cfg  
Starting zookeeper ... STARTED
```

Next in command prompt, enter command : **$ telnet localhost 2181.** Once prompter for further command type : **$ srvr .** Expected output

```
pawan:$ telnet localhost 2181  
Trying ::1...  
Connected to localhost.  
Escape character is '^]'.  
srvr  
Zookeeper version: 3.4.8--1, built on 02/06/2016 03:18 GMT  
Latency min/avg/max: 0/0/0  
Received: 1  
Sent: 0  
Connections: 1  
Outstanding: 0  
Zxid: 0x7c8  
Mode: standalone  
Node count: 163  
Connection closed by foreign host.
```

This confirms that our zookeeper is up & running and is accessible for other services at **localhost:2181.**

### Kafka Setup

* * *

[Kafka](http://kafka.apache.org) setup similar to zookeeper involves downloading small compressed binaries from [here](http://kafka.apache.org) & unzipping it in location of your choice. Once unzipped, the root directory will contain following items :

```
MishraPaw-01-MBR:kafka_2.11-0.9.0.1 mishrapaw$ ls  
LICENSE        NOTICE        bin        config        libs        logs        site-docs
```

We are mostly going to focus on bin & config directory.

Bin directory consist of multiple shell script files which can be used for starting/stopping broker, configuring topics, running console producer & consumer and other advanced stuffs like configuring topics(post creation) & mirror making etc. Kafka comes along with Zookeeper binaries & we could have used the same for setting up zookeeper instead of following the steps mentioned above. But it’s generally good practice to have independent setup for Zookeeper.

Config directory contains various configuration related properties file. The file we are interested in is **server.properties**. Every Kafka broker requires a server.properties file. We are going to spin up two brokers(later in post), so we are going to create another copy of server.properties file in same location and call it **server-2.properties**. At the same time, lets rename server.properties to server-1.properties file. Next lets setup & start two Kafka broker instances.

#### Kafka Brokers Setup & Start

Setting up broker involves creating server.properties file & initializing some of the essential configuration options. If you need more that one broker, simply create another copy of server.properties file & modify the configuration parameters. Lets look at server-1.properties file. The properties file is really large. I have only listed the properties that we are going to change for our example:

##### server-1.properties

```
# The id of the broker. This must be set to a unique integer for each broker.  
broker.id=1  

listeners=PLAINTEXT://:9092  

# The port the socket server listens on  
port=9092  

# Hostname the broker will bind to. If not set, the server will bind to all interfaces  
host.name=localhost  

# Hostname the broker will advertise to producers and consumers. If not set, it uses the  
# value for "host.name" if configured.  Otherwise, it will use the value returned from  
# java.net.InetAddress.getCanonicalHostName().  
advertised.host.name=localhost  

# A comma seperated list of directories under which to store log files  
log.dirs=/Users/mishrapaw/Documents/mykafka/kafka-log-1
```

Broker.id, port, listeners & log.dirs values must be unique for every broker instance. Ensure that log.dirs must exist & must be unique for every broker instance.

##### server-2.properties

```
# The id of the broker. This must be set to a unique integer for each broker.  
broker.id=2  
listeners=PLAINTEXT://:9091  

# The port the socket server listens on  
port=9091  

# Hostname the broker will bind to. If not set, the server will bind to all interfaces  
host.name=localhost  

# Hostname the broker will advertise to producers and consumers. If not set, it uses the  
# value for "host.name" if configured.  Otherwise, it will use the value returned from  
# java.net.InetAddress.getCanonicalHostName().  
advertised.host.name=localhost  
# A comma seperated list of directories under which to store log files  
log.dirs=/Users/mishrapaw/Documents/mykafka/kafka-log-2
```

The properties file also contains zookeeper information. By default zookeeper.connect property is set to localhost:2181\. Since our local zookeeper instance is listening on localhost:2181, we don’t have to update zookeeper information.

> Important: Before starting the brokers, ensure that the log.dirs path is correct & is unique per kafka broker instance. If two kafka brokers are assigned one common path by mistake then it can cause instances to fail.

Once properties files are ready, then we can start the broker instances. From command line, execute the following command for starting two broker instances:

```
# bin directory is the one which contains various kakfa shell scripts  
$./bin/kafka-server-start.sh config/server-1.properties &  
$./bin/kafka-server-start.sh config/server-2.properties &
```

With Kafka brokers running fine, its time to setup topics & partitions.

### Topic & Partitions
---

In Kafka, messages produced by consumer are written to what is known as topics. Topics are similar to queues in rabbitmq. Topics provide granularity or partitioning based on the type of data. Say for e.g. if you are setting up system for processing college related information, then you can defined one topic for students related data, one for teachers related data etc. Once you have created a topic, you then define number of partitions for that topic. By default topic will have one partition but you can increase the number of partitions. Partitions help you in controlling/segregating data coming from different producers.  If for e.g. you have two producers producing data for a given topic then you can assign one producer to write data to one partition & make the other producer write data to another. Let’s go ahead & create a topic with two partitions. Run the following command for creating topic :

```
mishrapaw$ ./bin/kafka-topics.sh --create --topic blogTest --partitions 2 --zookeeper localhost:2181 --replication-factor 1
```

The above command creates a topic called “blogTest” with two partition. I have avoided any replication related activity by setting replication-factor to 1\. Replication-factor is must for any production level setup & you can read more about it in official kafka page. If you run the following command, you can get details about the topic :

```
mishrapaw$ ./bin/kafka-topics.sh --describe --topic blogTest --zookeeper localhost:2181
```

#### Output
---
```
Topic:blogTest    PartitionCount:2    ReplicationFactor:1    Configs:  
    Topic: blogTest    Partition: 0    Leader: 1    Replicas: 1    Isr: 1  
    Topic: blogTest    Partition: 1    Leader: 2    Replicas: 2    Isr: 2
```

### Producer & Consumer

* * *

So our kafka brokers are running, we have created topic & corresponding partitions. All of this is great but it’s of no use if we do not have data. Just like any producer, consumer app, Kafka too has the concept of producers & consumers. Producer produce data for a given topic & consumers consume data from topic. For our producer & consumer setup, we are going to do the following :

*   Create two producers writing to same topic. Normally its possible to make producer write to a specific partition within a topic but since we are going to use console based producer, it doesn’t support this functionality.
*   We will setup only one consumer, which will read data from both the partitions.

You can create producers & consumers programmatically via Java API but for this blog I am going to use Kafka provided console based producers & consumers.

Start the console consumer in a new console window with the following command & leave the consumer running.

```
mishrapaw$ ./bin/kafka-console-consumer.sh --topic blogTest --zookeeper localhost:2181
```

Since we are writing nothing to the topic, we will see nothing once the consumer starts. It’s time to create our producers & start producing data. Create two producers in different console windows using following command :

```
Console-1  
mishrapaw$ ./bin/kafka-console-producer.sh --broker-list localhost:9091,localhost:9092 --topic blogTest  

Console-2  
mishrapaw$ ./bin/kafka-console-producer.sh --broker-list localhost:9091,localhost:9092 --topic blogTest
```

Once the producers are running, you can start writing messages in the console and you will notice that those messages are getting consumed by the consumer.

### Summary
---
What I have outlined in this blog post is simple, get-started approach with Kafka. You can do a lot more number of things with Kafka. For e.g. :

*   Add replication functionality. This provides fault-tolerance support & is much needed requirement for any production level app.
*   Since consumers don’t delete data from topic, you can start, stop consumers as an when you want. You can even create new consumers & make them listen to an existing topic.
*   Consumers work in so called consumer groups. By adding new consumers within a group, you can provide horizontal scalability functionality to your system.
*   Topic & partitions within a topic can be used to model data granularity. This can in-turn help you in modeling the application.