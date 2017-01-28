---
layout: splash
title: RxJava - SubscribeOn & ObserveOn
tags: [RxJava, Java]
excerpt: In this blog post we will cover the two most important aspect of RxJava programming which is configuring observeOn & subscribeOn listeners.
---
{% include toc %}
In one of my previous [post](https://weblogs.asp.net/pawanmishra/rxjava-part1), I have covered the basics of setting up RxJava based file processing application. In this blog post we will cover the two most important aspect of RxJava programming which is configuring **observeOn** & **subscribeOn** listeners. Before we get into the technical discussion of these concepts, lets quickly review the sample code snippet that we will be using for our discussion.

First we have the RxObserver.java class which returns an [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable).

### Observer Class
---

```java
public class RxObserver {  
    public Observable<String> getObservable(String fileName) throws IOException, URISyntaxException {  
        return Observable.create(subscribe -> {  
                try {  
                    InputStream in = new FileInputStream(fileName);  
                    BufferedReader reader = new BufferedReader(new InputStreamReader(in));  
                    String line = null;  
                    Integer count = 0;  

                    while ((line = reader.readLine()) != null && count != 5) {  
                        System.out.println("RxObserver running on ThreadId : " + Thread.currentThread().getId());  
                        subscribe.onNext("rec-" + (count+1));  
                        count++;  
                    }  

                    if(count == 5)  
                    {  
                        subscribe.onCompleted();  
                    }  

                    if(line == null)  
                    {  
                        subscribe.onCompleted();  
                    }  
                } catch (IOException e) {  
                    subscribe.onError(e);  
                }  
        });  
    }  
}
```

Given a file path, the above code creates an Observable and calls the onNext method on the subscribed instance every time it reads a line from the file. Once all of the lines are read then it calls onCompleted() and in case of exceptions it invokes onError. Next we have the RxSubscriber.java class.

### Subscriber Class
---

```java
public class RxSubscriber {   

    RxObserver observer = null;  
    public RxSubscriber()  
    {  
        observer = new RxObserver();  
    }  

    public void processData(String fileName) throws IOException, URISyntaxException {  
        observer.getObservable(fileName)  
                .subscribe(x -> {  
                                System.out.println("RxSubscriber running on ThreadId : " + Thread.currentThread().getId());  
                                System.out.println("Processing record : " + x);  
                            },  
                            t -> System.out.println(t.getStackTrace()),  
                            () -> System.out.println("Completed")  
                );  
    }  
}
```

RxSubscriber class subscribes to the previously created Observable instance and provides the callback handlers for the onNext, onError & onCompleted method. Finally we have our main method :

```java
public class Main {  

    static String sourcePath = "<path>/classes/source";  
    static String targetPath = "<path>/cleansed";  

    public static void main(String[] args) throws InterruptedException, IOException, URISyntaxException {  

        System.out.println("Main method started");  
        System.out.println("Main thread Id : " + Thread.currentThread().getId());  

        while(true)  
        {  
            File file = new File(sourcePath);  

            File[] files = file.listFiles(new FilenameFilter() {  
                public boolean accept(File dir, String name) {  
                    return name.toLowerCase().endsWith(".txt");  
                }  
            });  

            if (file.isDirectory() && files.length <= 0) {  
                System.out.println("Main method sleeping");  
                Thread.sleep(5000);  
                continue;  
            }  

            for(File f : files)  
            {  
                Files.move(Paths.get(sourcePath + "/" + f.getName()), Paths.get(targetPath + "/" + f.getName()));  
                RxSubscriber subscriber = new RxSubscriber();  
                subscriber.processData(targetPath + "/" + f.getName());  
            }  
        }  
    }  
}  

```

Our main method runs for ever. It periodically checks for file in source directory. If any file is present, it moves that file in processed directory. Creates an instance of **RxSubscriber** class and hands over the moved file path for processing. If no files are present then our main thread sleeps for 5 seconds. For reference I have added some thread-Id related logging statements in all of the above code snippets. This would help us in identifying the behavior. Let’s run the code in its current form and analyze the output.

```
Main method started  
Main thread Id : 1  
RxObserver running on ThreadId : 1  
RxSubscriber running on ThreadId : 1  
Processing record : rec-1  
RxObserver running on ThreadId : 1  
RxSubscriber running on ThreadId : 1  
Processing record : rec-2  
RxObserver running on ThreadId : 1  
RxSubscriber running on ThreadId : 1  
Processing record : rec-3  
RxObserver running on ThreadId : 1  
RxSubscriber running on ThreadId : 1  
Processing record : rec-4  
RxObserver running on ThreadId : 1  
RxSubscriber running on ThreadId : 1  
Processing record : rec-5  
Completed
```

The output is simple to understand. Since we haven’t specified the subscribeOn or observeOn schedulers, the entire code is going to run on the only available thread which in this case is our main thread. Another interesting thing to notice is that the main thread never went into sleep mode. As soon as it moved the file and instantiated the RxSubscriber class, it immediately went into the processing mode and got occupied with RxObserver & RxSubscriber related execution.

> Take away : If you do not specify subscribeOn and observeOn schedulers on your Observable then by default all of your code will execute on the main thread. By main thread I mean the thread which instantiate your Observable.

#### Enable subscribeOn on Observable
---

Alright lets change our RxSubscriber code this time by adding subscribeOn scheduler. Modify the RxSubscriber.java class as given below.

```java
public class RxSubscriber {   

    RxObserver observer = null;  
    public RxSubscriber()  
    {  
        observer = new RxObserver();  
    }  

    public void processData(String fileName) throws IOException, URISyntaxException {  
        observer.getObservable(fileName)  
                .subscribeOn(Schedulers.io())  
                .subscribe(x -> {  
                                System.out.println("RxSubscriber running on ThreadId : " + Thread.currentThread().getId());  
                                System.out.println("Processing record : " + x);  
                            },  
                            t -> System.out.println(t.getStackTrace()),  
                            () -> System.out.println("Completed")  
                );  
    }  
}
```

**Output**

```
Main method started  
Main thread Id : 1  
RxObserver running on ThreadId : 13  
Main method sleeping  
RxSubscriber running on ThreadId : 13  
Processing record : rec-1  
RxObserver running on ThreadId : 13  
RxSubscriber running on ThreadId : 13  
Processing record : rec-2  
RxObserver running on ThreadId : 13  
RxSubscriber running on ThreadId : 13  
Processing record : rec-3  
RxObserver running on ThreadId : 13  
RxSubscriber running on ThreadId : 13  
Processing record : rec-4  
RxObserver running on ThreadId : 13  
RxSubscriber running on ThreadId : 13  
Processing record : rec-5  
Completed
```

Lets carefully analyze the output. As before, the main method starts and its threadId is 1\. But after that what we notice is that the **RxObserver** & **RxSubscriber** code is all running on ThreadId 13\. What happens here is that as soon as main thread finds the “**subscribeOn**” statement, it immediately creates a new thread and returns. It schedules the entire logic of Observable & the subscription to run on this new thread.

Now what would have happened if we haven’t kept our main thread in a infinite loop? Answer is simple. Main method would return after seeing **subscribeOn** statement. And since there would be nothing left for it to do, it would simply die and our application will stop running. The background thread created by main thread too would die a silent death in background.

> Take away : If you only specify subscribeOn, then the entire logic of Observable & the subscription runs on one thread. The thread which gets created via main thread when it encounters the “**subscribeOn**” statement.

#### Enable observeOn on Observable
---

Next instead of subscribeOn lets enable observeOn on our Observable.

```java
public class RxSubscriber {   

    RxObserver observer = null;  
    public RxSubscriber()  
    {  
        observer = new RxObserver();  
    }  

    public void processData(String fileName) throws IOException, URISyntaxException {  
        observer.getObservable(fileName)  
                .observeOn(Schedulers.io())  
                .subscribe(x -> {  
                                System.out.println("RxSubscriber running on ThreadId : " + Thread.currentThread().getId());  
                                System.out.println("Processing record : " + x);  
                            },  
                            t -> System.out.println(t.getStackTrace()),  
                            () -> System.out.println("Completed")  
                );  
    }  
}
```

**Output**

```
Main method started  
Main thread Id : 1  
RxObserver running on ThreadId : 1  
RxObserver running on ThreadId : 1  
RxObserver running on ThreadId : 1  
RxObserver running on ThreadId : 1  
RxObserver running on ThreadId : 1  
Main method sleeping  
RxSubscriber running on ThreadId : 15  
Processing record : rec-1  
RxSubscriber running on ThreadId : 15  
Processing record : rec-2  
RxSubscriber running on ThreadId : 15  
Processing record : rec-3  
RxSubscriber running on ThreadId : 15  
Processing record : rec-4  
RxSubscriber running on ThreadId : 15  
Processing record : rec-5  
Completed
```

And what a change this time. With “observeOn” in place its only the callback handlers defined in our RxObserver class that runs on different thread. The subscription logic defined in the **RxObserver.java** class still runs of the main thread. This is very important to understand. Changing of one line altered the entire flow of our code. Lets make one final change and set both the properties i.e. subscribeOn & observeOn.

#### Enable subscribeOn & observeOn

* * *

```java
public class RxSubscriber {   

    RxObserver observer = null;  
    public RxSubscriber()  
    {  
        observer = new RxObserver();  
    }  

    public void processData(String fileName) throws IOException, URISyntaxException {  
        observer.getObservable(fileName)  
                .observeOn(Schedulers.io())  
                .subscribeOn(Schedulers.io())  
                .subscribe(x -> {  
                                System.out.println("RxSubscriber running on ThreadId : " + Thread.currentThread().getId());  
                                System.out.println("Processing record : " + x);  
                            },  
                            t -> System.out.println(t.getStackTrace()),  
                            () -> System.out.println("Completed")  
                );  
    }  
}
```

**Output**

```
Main method started  
Main thread Id : 1  
Main method sleeping  
RxObserver running on ThreadId : 13  
RxObserver running on ThreadId : 13  
RxObserver running on ThreadId : 13  
RxObserver running on ThreadId : 13  
RxObserver running on ThreadId : 13  
RxSubscriber running on ThreadId : 16  
Processing record : rec-1  
RxSubscriber running on ThreadId : 16  
Processing record : rec-2  
RxSubscriber running on ThreadId : 16  
Processing record : rec-3  
RxSubscriber running on ThreadId : 16  
Processing record : rec-4  
RxSubscriber running on ThreadId : 16  
Processing record : rec-5  
Completed
```

As expected this time our subscription & the callback handler code ran on different threads.

As we have seen in this blog post how setting up subscribeOn and observeOn alters the behavior of our application. When designing your application, you should carefully think about what part of your code you would like to execute on which scheduler. By default [RxJava](https://github.com/ReactiveX/rxjava) comes with different flavors of [Schedulers](http://reactivex.io/documentation/scheduler.html). Understanding Schedulers is going to be another topic which I would cover in some later post.

### Summary
---

But what is really amazing here is that with minimal amount of code changes we have configured to run parts of our application on different threads. Our simple app is multi-threaded without having us to worry about all of the thread related complexities. The Observe & subscription model automatically takes care of handling of tasks between the threads. I hope that this very basic tutorial has helped you in understanding the not so obvious concept of [RxJava](https://github.com/ReactiveX/rxjava) programming.