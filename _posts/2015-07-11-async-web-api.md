---
layout: single
title: Async Web Api Performance
tags: [C#]
---
In one of my recent WPF project, we made extensive use of **async-await** pattern. Async-await pattern greatly simplified the call-back and continuation based code required for keeping the UI responsive. In WPF, the pattern for implementing async-await is to invoke the IO/CPU intensive code in a background thread and attach the continuation logic on the main UI thread. In WPF, since we have a dedicated UI thread that controls all of the UI elements, using async-await is really helpful in keeping the UI responsive without having to write complicated call-back based code.

Coming to the world of WebApi, the abstract base class “ApiController” implements an interface called “IHttpController” which contains the following method signature:

```csharp
// Summary:
//     Represents an HTTP controller.
public interface IHttpController
{
    // Summary:
    //     Executes the controller for synchronization.
    //
    // Parameters:
    //   controllerContext:
    //     The current context for a test controller.
    //
    //   cancellationToken:
    //     The notification that cancels the operation.
    //
    // Returns:
    //     The controller.
    Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(HttpControllerContext controllerContext, CancellationToken cancellationToken);
}
```

Its the responsibility of the ExecuteAsync method to invoke the appropriate action method. Now we all know that in case of web, there is no concept of thread affinity i.e. every new incoming request would most likely be handled by an entirely new thread. Thus the concept of attaching continuation is not really possible. Then what is the real advantage of having asynchronous controller actions? Lets try to answer the question with the help of running code:

I am using VS 2013 community edition and start by creating a new WebApi project. By default, the project template will create a default “ValuesController” class with empty Get and Post method. What we are going to do in this post is to try and download the [msdn](https://msdn.microsoft.com/en-us/default.aspx) home page asynchronously and synchronously. First, I will present the synchronous version of the Get() action method:

```csharp
string url = @"https://msdn.microsoft.com/en-us/default.aspx";

public HttpResponseMessage Get(int id)
{
    HttpClient client = new HttpClient();
    string threadData = String.Format("IsThreadPoolThread : {0}, ThreadId : {1}", Thread.CurrentThread.IsThreadPoolThread, Thread.CurrentThread.ManagedThreadId);
    string result = client.GetStringAsync(url).Result;
    HttpResponseMessage response = new HttpResponseMessage();
    response.Content = new StringContent(string.Format("Request: {0} - Result : {1}, {2}", id, id * result.Length, threadData));
    return response;
}
```

In the above code, although we are invoking the GetStringAsync method(which is the async version of the GetString) method, calling the “Result” property of the result of the method immediately basically blocks the current thread. So when the request arrives, the thread which calls the GetStringAsync() method gets blocked because the Result property is immediately invoked. Rest of the code is straight forward. Along with the content data, I am also returning the details of the thread which handled/processed the request. Async version of the above code looks very much similar :

```csharp
public async Task<HttpResponseMessage> Get(int id)
{
    HttpClient client = new HttpClient();
    string threadData = String.Format("IsThreadPoolThread : {0}, ThreadId : {1}", Thread.CurrentThread.IsThreadPoolThread, Thread.CurrentThread.ManagedThreadId);
    string result = await client.GetStringAsync(url);
    HttpResponseMessage response = new HttpResponseMessage();
    response.Content = new StringContent(string.Format("Request: {0} - Result : {1}, {2}", id, id * result.Length, threadData));
    return response;
}
```

Notice that I have changed the method return type and added the await keyword in front of the GetStringAsync() method call. In case of async, the thread which received the request, returns immediately after  executing the await statement. Remaining code gets executed by another thread in more like a call-back fashion.

Now that we have the async and non-async action methods in place, lets put in place some code which invoked these action methods.

```csharp
HttpClient client = new HttpClient();
string path = "http://localhost:52013/api/values/";
ConcurrentBag<string> lst = new ConcurrentBag<string>();
for(int i = 0; i < 100; i++)
{
    client.GetStringAsync(path + i).ContinueWith(result => lst.Add(result.Result));
}
while(lst.Count != 100) { Thread.Sleep(500); }
lst.Select(x => Int32.Parse(x.Substring(x.LastIndexOf(':') + 1).Trim())).Distinct().Dump();
```

I have used LinqPad to run the above code. All that the above code does is, invokes the previously defined action methods in quick successions i.e. 100 times. Every time the api is invoked, we have attached a continuation to capture the returned result. Also, I have made use of ConcurrentBag so as to avoid any kind of locking issues while the result is getting accumulated. The returned result looks something likes below:

> Request: 92 - Result : 2532484, IsThreadPoolThread : True, ThreadId : 45

After we have received the results of all of the api calls, I extract the “ManagedThreadId” value from the response and print the distinct values. Following is the screenshot of managed threadIds in case of asynchronous method call:

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/034e30f28b77_118A4/image_thumb.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/034e30f28b77_118A4/image_2.png)

And for the synchronous method call, following are the managed thread ids.

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/034e30f28b77_118A4/image_thumb_1.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/034e30f28b77_118A4/image_4.png)

I ran the experiment multiple times and almost every time the number of threads required to process the request in case of asynchronous version was almost 50% less that the number of threads required to process using the synchronous version.

If you have carefully looked at the response message, then you would have noticed that I am also printing the type of thread i.e. if the thread is threadpool thread or not. In both the cases i.e. sync and async, threads used for processing the request are threadpool thread. Now its important to note that the number of threadpool threads are limited. In case of sync version, the threads are getting blocked waiting for the response. And while they are waiting more requests are coming in. Thus CLR keeps adding more number of threads to the threadpool. That’s why we see more number of threads in case of sync version. Now having more number of threads doing nothing but waiting is not good. It creates contentions, memory pressure and causes unnecessary context switches. In case of async version, threads aren’t blocked i.e. they return immediately to pool after executing the await statement. Thus same thread is able to handle more number of incoming request. Take away is that, if you are doing heavy CPU or I/O bound activity in your action methods, then its best to make use of async-await pattern. It would increase the throughput of your server.