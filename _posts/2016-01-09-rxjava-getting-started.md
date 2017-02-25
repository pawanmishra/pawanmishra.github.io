---
layout: single
title: RxJava - Getting Started
tags: [RxJava, Java]
excerpt: In this blog post, I am going to explain you the basics of [RxJava](https://github.com/ReactiveX/rxjava) by walking you through one of the sample application that I have built using [RxJava](https://github.com/ReactiveX/rxjava) framework. 
---
{% include toc %}
In this blog post, I am going to explain you the basics of [RxJava](https://github.com/ReactiveX/rxjava) by walking you through one of the sample application that I have built using [RxJava](https://github.com/ReactiveX/rxjava) framework. All that the application does is reads line from files, does some pre-processing with the read lines and then prints the output to the console. I will not get into the basics of [RxJava](https://github.com/ReactiveX/rxjava) or in general reactive programming fundamentals. If you are not familiar with the “**_Hello World”_** of reactive programming using [RxJava](https://github.com/ReactiveX/rxjava) then this might not be the suitable place for you to start. However if you know how to create an [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable) and subscribe to it, then you will find this article not too difficult.

### SetUp

If you would like to follow along then go ahead and create a new maven project in IntelliJIDEA and include [RxJava](https://github.com/ReactiveX/rxjava) as dependency in the pom file. **Note : RxJava latest stable build is versioned 1.1.0.**

```
<dependency>  
    <groupId>io.reactivex</groupId>  
    <artifactId>rxjava</artifactId>  
    <version>1.1.0</version>  
</dependency>
```

#### Entities
---

Create following files:

*   **Main.java** : contains our main method. Entry point of the application.
*   **RxObserver.java** : file for defining our Observable
*   **RxSubscriber.java** : file for attaching Subscriber to our previously defined Observable

Next we need a sample file for our application. Contents of the file doesn't matter. It could be a plain csv file with 50000+ records. You can name the file as **trial.txt**.

Lets start by adding some code in files listed above. In the first iteration all we are going to do is to have an [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable) in place and subscribe to it. All of the observation + subscription stuff happens on the main thread.

### Observer Class

In **RxObserver.java** class, add the following code snippet:

```java
public class RxObserver {  
public Observable<String> getObservable(String fileName) throws IOException, URISyntaxException {  
    return Observable.create(subscribe -> {  
            try {  
                InputStream in = new FileInputStream(fileName);  
                BufferedReader reader = new BufferedReader(new InputStreamReader(in));  
                String line = null;  

                while ((line = reader.readLine()) != null) {  
                    subscribe.onNext(line);  
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

In the above code, we are returning an [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable) using **_Observable.create()_** method. In the subscription code, we are reading lines from the file and every time we read a line, we invoke the **_onNext()_** method on the subscribed entity. Once all of the lines are read, then **_onCompleted()_** call is made. In case of any exception **_onError()_** method is invoked. Things to remember :

*   onNext method can be invoked 0 to N number of times
*   onCompleted() and onError() calls can only be made once

Now that we have our [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable), its time to define our Observer in **RxSubscribe.java** class.

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
	            .subscribe(x -> System.out.println(x), // onNext() handler  
	                       t -> System.out.println(t.getStackTrace()), // onError() handler  
	                       () -> System.out.println("Completed")); // onCompleted() handler  
	}  
}
```

Things can't get anymore simpler than this. We get our [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable) and to that we subscribe by providing callback handlers for the onNext(), onError() & onCompleted() events. Finally to wire things up, lets complete our **Main.java** class:

```java
public class Main   
{   
    static String targetPath = "<base_path_of_the_directory_where_file_is_present>";   

    public static void main(String[] args) throws InterruptedException, IOException, URISyntaxException   
    {   
        RxSubscriber subscriber = new RxSubscriber();   
        System.out.println("Main method started");   
        subscriber.processData(targetPath + "/" + "trial.txt"); System.out.println("Main method complete");   
    }   
}
```

Lets try running our code and see what happens. Output:

```
Main method started ..   

Line 1 from file ..   
Line 2 from file ..   
Line 3 from file ..   
Completed Main method complete
```

From the output its clear that all of the code is executed synchronously on the main thread. For our demo application it is not an issue but for any real time application this is not an ideal thing to do. What we really want to happen is that the [Observable](https://github.com/ReactiveX/RxJava/wiki/Observable) & the Observer code should run on different thread and our main thread should remain free to process any other application specific requests. Let's make some changes to the code and set our main thread free.

### SubscribeOn vs ObserveOn

Lets re-run our code by specifying [subscribeOn](http://reactivex.io/documentation/operators/subscribeon.html) handler in **RxSubscriber.java** class.

> **Note** : subscribeOn() and observeOn() are two essential components that require special > attention and proper understanding in order to make best use of [RxJava](https://github.com/ReactiveX/rxjava). I will cover these topics later in another blog post.

```
public void processData(String fileName) throws IOException, URISyntaxException   
{   
    observer.getObservable(fileName)  
    .subscribeOn(Schedulers.io())   
    .subscribe(x -> System.out.println(x),   
                t -> System.out.println(t.getStackTrace()),   
                () -> System.out.println("Completed"));   
}
```

The output this time is going to be very much different and I must say unpredictable. Reason is setting subscribeOn() causes a new thread to be created and the entire **RxObserver.java** code gets executed on the newly created thread. Thus as soon as the main thread has executed **subscribeOn()** line, it returns back in the Main method in **Main.java** class. Thus following are sample outputs:

```
Main method started ..   
Line 1 from file ..   
Line 2 from file ..   
Line 3 from file ..   
Completed Main method complete  

--  

Main method started   
Main method complete ..   
Line 1 from file ..   
Line 2 from file ..   
Line 3 from file ..   
Completed  

--  

Main method started   
Main method complete ..   
Line 1 from file ..   
Line 2 from file ..   
Line 3 from file ..
```

Thus we would have to prevent our main thread from completing while the background thread is still running. In other words, lets put our main thread run forever by putting in an infinite while loop. And while we are modifying our main method, lets also change the way our application is currently setup. Now we are going to have two directories : source & processed. **Source** directory will contain the file that needs to be processed. And **processed** directory contains the processed files. Main thread sleeps for 5 seconds if it cannot find any new files for processing. This is just to ensure that the main thread doesn't eats up all of the CPU in an infinite loop.

```
public class Main {  

static String sourcePath = "<some_path>/source";  
static String targetPath = "<some_path>/processed";  

    public static void main(String[] args) throws InterruptedException, IOException, URISyntaxException {  

        System.out.println("Main method started");  

        while(true)  
        {  
            File file = new File(sourcePath);  

            File[] files = file.listFiles(new FilenameFilter() {  
                public boolean accept(File dir, String name) {  
                    return name.toLowerCase().endsWith(".txt");  
                }  
            });  

            if (file.isDirectory() && files.length <= 0) {  
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

### Summary
---

And with the small change of leaving our main thread to run forever resolved our previously mentioned issue. We have now developed a small application using [RxJava](https://github.com/ReactiveX/rxjava) which does file processing in an asynchronous manner without even writing any explicit manual thread handling code. The scope of [RxJava](https://github.com/ReactiveX/rxjava) is much more than this simple file processing application. But I hope that you will agree with me that there is so much more that we can do with [RxJava](https://github.com/ReactiveX/rxjava).