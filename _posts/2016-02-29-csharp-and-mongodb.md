---
layout: single
title: Working with MongoDB using F# & C#
---

In this blog post I am going to show you how you can access and perform CRUD operation from C# based application against [MongoDb](https://www.mongodb.org/). In our application, we are going to persist & read feed data from underlying [mongodb](https://www.mongodb.org/) database. Feeds are used by websites to publish the frequently updated information. Many websites publish their feed url. We can subscribe to those feeds via online feed readers and keep our self up to date with latest changes. In our application we are going to do the following :

*   Read a Feed Url
*   Parse the feed Xml into strongly typed entity
*   Persist the entity into mongodb database
*   Provide methods for performing CRUD operations on the underlying database data

The feed url we are going to use in our application is : [http://www.geeksforgeeks.org/feed/](http://www.geeksforgeeks.org/feed/ "http://www.geeksforgeeks.org/feed/")

### Parse feed xml into strongly typed entity  
---

We will make use of F# type providers capability for converting feed xml into strongly typed entity. Below is a sample feed xml documents :

```xml
<?xml version="1.0" encoding="UTF-8"?>  
<rss version="2.0"  
    xmlns:content="http://purl.org/rss/1.0/modules/content/"  
    xmlns:wfw="http://wellformedweb.org/CommentAPI/"  
    xmlns:dc="http://purl.org/dc/elements/1.1/"  
    xmlns:atom="http://www.w3.org/2005/Atom"  
    xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"  
    xmlns:slash="http://purl.org/rss/1.0/modules/slash/"  
    >  
    <channel>  
<title>GeeksforGeeks</title>  
<atom:link href="http://www.geeksforgeeks.org/feed/" rel="self" type="application/rss+xml" />  
<link>http://www.geeksforgeeks.org</link>  
<description>A computer science portal for geeks</description>  
<lastBuildDate>Sun, 28 Feb 2016 16:49:21 +0000</lastBuildDate>  
<language>en-US</language>  
<sy:updatePeriod>hourly</sy:updatePeriod>  
<sy:updateFrequency>1</sy:updateFrequency>  
<generator>http://wordpress.org/?v=4.2.7</generator>  
<item>  
    <title>Applications of Catalan Numbers</title>  
    <link>http://www.geeksforgeeks.org/applications-of-catalan-numbers/</link>  
    <comments>http://www.geeksforgeeks.org/applications-of-catalan-numbers/#comments</comments>  
    <pubDate>Sun, 28 Feb 2016 16:07:45 +0000</pubDate>  
    <dc:creator>  
        <![CDATA[geeks forgeeks]]>  
    </dc:creator>  
    <category>  
        <![CDATA[Mathematical]]>  
    </category>  
    <guid isPermaLink="false">http://www.geeksforgeeks.org/?p=137070</guid>  
    <description>  
        <![CDATA[<p>Background : Catalan numbers are defined using below formula: Catalan numbers can also be defined using following recursive formula. The first few Catalan numbers for n = 0, 1, 2, 3, … are 1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, … Refer this for implementation of n&#8217;th Catalan Number. Applications : Number… <span class="read-more"><a href="http://www.geeksforgeeks.org/applications-of-catalan-numbers/">Read More &#187;</a></span></p><p>The post <a rel="nofollow" href="http://www.geeksforgeeks.org/applications-of-catalan-numbers/">Applications of Catalan Numbers</a> appeared first on <a rel="nofollow" href="http://www.geeksforgeeks.org">GeeksforGeeks</a>.</p>  
]]>  
    </description>  
    <wfw:commentRss>http://www.geeksforgeeks.org/applications-of-catalan-numbers/feed/</wfw:commentRss>  
    <slash:comments>0</slash:comments>  
</item>  
<item>  
    <title>Randomized Algorithms &#124; Set 3 (1/2 Approximate Median)</title>  
    <link>http://www.geeksforgeeks.org/randomized-algorithms-set-3-12-approximate-median/</link>  
    <comments>http://www.geeksforgeeks.org/randomized-algorithms-set-3-12-approximate-median/#comments</comments>  
    <pubDate>Sun, 28 Feb 2016 10:52:09 +0000</pubDate>  
    <dc:creator>  
        <![CDATA[geeks forgeeks]]>  
    </dc:creator>  
    <category>  
        <![CDATA[Randomized]]>  
    </category>  
    <guid isPermaLink="false">http://www.geeksforgeeks.org/?p=137068</guid>  
    <description>  
        <![CDATA[<p>We strongly recommend to refer below articles as a prerequisite of this. Randomized Algorithms &#124; Set 1 (Introduction and Analysis) Randomized Algorithms &#124; Set 2 (Classification and Applications) In this post, a Monte Carlo algorithm is discussed. Problem Statement : Given an unsorted array A[] of n numbers and &#949; &#62; 0, compute an element… <span class="read-more"><a href="http://www.geeksforgeeks.org/randomized-algorithms-set-3-12-approximate-median/">Read More &#187;</a></span></p><p>The post <a rel="nofollow" href="http://www.geeksforgeeks.org/randomized-algorithms-set-3-12-approximate-median/">Randomized Algorithms | Set 3 (1/2 Approximate Median)</a> appeared first on <a rel="nofollow" href="http://www.geeksforgeeks.org">GeeksforGeeks</a>.</p>  
]]>  
    </description>  
    <wfw:commentRss>http://www.geeksforgeeks.org/randomized-algorithms-set-3-12-approximate-median/feed/</wfw:commentRss>  
    <slash:comments>0</slash:comments>  
</item>  
</channel>  
</rss>
```

In general the xml structure looks something like below :

* Rss
  * Channel
      * Item
          * Title
          * Link
          * Description

Lets get started. Create a new Visual Studio blank solution called “Feedr”. Add to it a new F# library project called “**FeedParser**”. Remove the default files created by the project template. Add a new file to the project called “**Parser.fs**”. Next before we can get started with our code, we need to add the **FSharp.Data** nuget dependency. You can add the FSharp.Data version 2.2.5 via Nuget Package Manager. Once you have added the dependency, you will find a packages.config file with following entry:

```
<?xml version="1.0" encoding="utf-8"?>  
<packages>  
 <package id="FSharp.Data" version="2.2.5" targetFramework="net452" />  
</packages>
```

Next open up the “Parser.fs” file and add the following code.

```
module Parser  

open System.Net  
open System.Web  
open FSharp.Data  

type BaseFeed = XmlProvider<"http://www.geeksforgeeks.org/feed/">  

type Article = { Title:string; Link:string; Description:string; Uid:string}  

let parseFeed (url:string) =   
        let data = BaseFeed.Load url  
        let items = data.Channel.Items  
        let record = items |> Array.map (fun x -> {Title = x.Title; Link = x.Link; Description = x.Description; Uid = x.Guid.Value})  
        record  

```

That’s it. In just 7 lines(ignoring the open & module statement) we have converted our feed xml into strongly typed entity called “**Article**”. You can read more about the F# Xml type provider here : [http://fsharp.github.io/FSharp.Data/library/XmlProvider.html](http://fsharp.github.io/FSharp.Data/library/XmlProvider.html "http://fsharp.github.io/FSharp.Data/library/XmlProvider.html")

In the above code, we have created a type provider called “**BaseFeed**”. Used that to parse feed data represented via incoming url in “parseFeed” method. Once parsed, we iterate over the items collection and convert it into strongly typed entity called “Article” which is basically a Record type in F#. This completes our F# implementation. Lets switch over to C# side & start some mongodb related activity.

### MongoDb Setup
---

Before we can start [mongodb](https://www.mongodb.org/) related development, we need to setup [mongodb](https://www.mongodb.org/) in our machine. Luckily the steps involved in installing MongoDb aren’t that difficult. Download and install [MongoDb](https://www.mongodb.org/) from here : [https://www.mongodb.org](https://www.mongodb.org/). You can choose either the msi based installer or the zip format. Install or unzip the content in any directory of your choice say C:/mongo. Add to system path, the mongodb’s bin directory path i.e. C:\mongo\bin. Next, at the bin directory level, create two new folders i.e. db & log. And inside db folder, create another folder called data. The data folder will contain our database related files. Finally, we need to install [mongodb](https://www.mongodb.org/) as service. For that, lets first create a configuration file inside C:\mongo directory and call it as mongod.cfg. Add following lines to the config file :

```yaml
systemLog:  
    destination: file  
    path: c:\mongo\log\mongod.log  
storage:  
    dbPath: c:\mongo\db\data
```

Next for installing mongodb as service, issue the following command. You can read more about it here :[https://docs.mongodb.org/manual/tutorial/install-mongodb-on-windows/](https://docs.mongodb.org/manual/tutorial/install-mongodb-on-windows/)

```
"C:\mongo\bin\mongod.exe" --config "C:\mongo\mongod.cfg" --install
```

Ensure that mongodb is installed and up & running as service in services.msc. It’s time to get started with C# development.

With [mongodb](https://www.mongodb.org/) installed, go ahead and add another C# library project to our previously created “**Feedr**” solution. Call this project “**FeerdInfrastructure**”. Add to this project as reference the F# project “**FeedParser**” from our solution. In order for us to interact with mongodb from C# code, we have to first install the latest mongodb C# drivers. The latest drivers are available via nuget package. Search for MongoDB.Driver v2.2.3(latest driver) in Nuget Package manager. MongoDB.Driver will also install other dependencies namely **MongoDB.Bson** & **MongoDB.Driver.Core**.

Unlike other databases, mongodb doesn’t require us to first create the database. If the target database is not present then it will automatically create the database on the very first request. But in order to interact with any database we need two things : database name & connection string. And in case of mongodb we also need one more thing which is “collection name”. Mongodb is a document type database where everything is stored in form of document grouped under collection. A collection is basically a group of documents. For our application lets define these three things in config file :

```xml
<configuration>  
  <connectionStrings>  
    <add name="FeedrConnectionString" connectionString="mongodb://localhost:27017/" />  
  </connectionStrings>  
  <appSettings>  
    <add key="FeedrDatabaseName" value="feedr" />  
    <add key="FeedrCollectionName" value="feedCollection" />  
  </appSettings>  
</configuration>
```

By default mongodb listens on port number 27017\. Next we will create a context class similar to how we define context class when working with ORM frameworks. Lets call our context class “**FeedrContext**”.

```csharp
namespace FeedrInfrastructure  
{  
    /// <summary>  
    /// Context class for creating <see cref="MongoClient"/> instance and accessing <see cref="IMongoDatabase"/> instance  
    /// </summary>  
    public class FeedrContext  
    {  
        private IMongoDatabase _database;  

        /// <summary>  
        /// Default constructor  
        /// </summary>  
        public FeedrContext()  
        {  
            var client = new MongoClient(ConfigurationManager.ConnectionStrings["FeedrConnectionString"].ConnectionString);  
            _database = client.GetDatabase(ConfigurationManager.AppSettings["FeedrDatabaseName"]);  
        }  

        /// <summary>  
        /// <see cref="IMongoDatabase"/> instance initialized via <see cref="MongoClient"/>  
        /// </summary>  
        public IMongoDatabase Database  
        {  
            get { return _database; }  
        }  

        /// <summary>  
        /// Property for accessing underlying feed collection in database  
        /// </summary>  
        public IMongoCollection<FeedDocument> Feeds  
        {  
            get { return _database.GetCollection<FeedDocument>(ConfigurationManager.AppSettings["FeedrCollectionName"]); }  
        }  
    }  
}
```

This completes our [mongodb](https://www.mongodb.org/) setup related code. Next we will define some model classes & a service layer class for performing CRUD operations.

### Model & Service Classes
---

In our **FeedrInfrastructure** project create a new folder called “Model”. Inside this folder, create two new classes “**FeedDocument.cs**” and “**FeedItem.cs**”. We will use these model class for representing the feed structure defined earlier in the post. In FeedDocument.cs class add the following code.

```csharp
namespace FeedrInfrastructure.Model  
{  
    /// <summary>  
    /// Document model representing a feed  
    /// </summary>  
    public class FeedDocument  
    {   
        public FeedDocument(string name, string url)  
        {  
            Name = name;  
            FeedUrl = url;  
            FeedItems = new List<FeedItem>();  
        }  

        [BsonRepresentation(MongoDB.Bson.BsonType.ObjectId)]  
        [BsonId]  
        public string FeedId { get; set; }  

        /// <summary>  
        /// Name of the site  
        /// </summary>  
        public string Name { get; set; }  

        /// <summary>  
        /// Default feed url.   
        /// </summary>  
        public string FeedUrl { get; set; }  

        /// <summary>  
        /// Collection of <see cref="FeedItem"/>  
        /// </summary>  
        public List<FeedItem> FeedItems { get; set; }  
    }  
}
```

And in FeedItem.cs class add the following code:

```csharp
namespace FeedrInfrastructure.Model  
{  
    /// <summary>  
    /// Class for representing individual Feed item  
    /// </summary>  
    public class FeedItem  
    {  
        public FeedItem(Article feed)  
        {  
            Link = feed.Link;  
            Description = feed.Description;  
            Title = feed.Title;  
            Uid = feed.Uid;  
        }  

        /// <summary>  
        /// Default Constructor  
        /// </summary>  
        public FeedItem()  
        {  

        }  

        /// <summary>  
        /// Article link  
        /// </summary>  
        public string Link { get; set; }  

        /// <summary>  
        /// Article title  
        /// </summary>  
        public string Title { get; set; }  

        /// <summary>  
        /// Article description  
        /// </summary>  
        public string Description { get; set; }  

        /// <summary>  
        /// Unique id of the article  
        /// </summary>  
        public string Uid { get; set; }  
    }  
}
```

As its clear we are going to use the FeedDocument class to represent our underlying document in mongodb database. Lets move onto our service class and add some methods for interacting with our database.

Create a new folder called “**Service**” in **FeedrInfrastructure** project and add to it class called “**FeedService.cs**” class. Add following code to the “**FeedService.cs**” class.

```csharp
namespace FeedrInfrastructure.Service  
{  
    public class FeedService  
    {  
        private readonly FeedrContext _context = new FeedrContext();  

        /// <summary>  
        /// Get all the <see cref="FeedDocument"/> present in the database  
        /// </summary>  
        /// <returns></returns>  
        public IEnumerable<FeedDocument> GetFeeds()  
        {  
            var feedDocuments = _context.Feeds.Find(_context => true).ToList();  
            return feedDocuments;  
        }  

        /// <summary>  
        /// Save the <paramref name="feed"/> in underlying database. Add the feed if it is not present in the database.  
        /// </summary>  
        /// <param name="feed"></param>  
        public async void SaveFeed(Feed feed)  
        {  
            var result = _context.Feeds.Find(x => x.Name.Equals(feed.name)).ToList().FirstOrDefault();  
            if (result != null) return;  

            FeedDocument feedDocument = new FeedDocument(feed.name, feed.feedUrl);  
            await _context.Feeds.InsertOneAsync(feedDocument);  
        }  

        /// <summary>  
        /// Returns list of <see cref="FeedItem"/> which are not present in the database  
        /// </summary>  
        /// <param name="feedName">Name of the <see cref="Feed"/></param>  
        /// <param name="index">Pagination index</param>  
        /// <returns>Collection of <see cref="FeedItem"/></returns>  
        public IEnumerable<FeedItem> GetFeeds(string feedName)  
        {  
            List<FeedItem> feedItems = new List<FeedItem>();  
            var result = _context.Feeds.Find(x => x.Name.Equals(feedName)).ToList().FirstOrDefault();  
            if(result != null)  
            {  
                var latestArticles = Parser.parseFeed(result.FeedUrl);  
                foreach(var article in latestArticles)  
                {  
                    if (!result.FeedItems.Any(x => x.Uid.Equals(article.Uid)))  
                    {  
                        var feedItem = new FeedItem(article);  
                        result.FeedItems.Add(feedItem);  
                        feedItems.Add(feedItem);  
                    }  
                }  

                _context.Feeds.ReplaceOne<FeedDocument>(x => x.Name == result.Name, result);  
            }  

            return feedItems;  
        }  

        /// <summary>  
        /// Saved input <see cref="FeedItem"/> in the <see cref="FeedDocument"/> with name <paramref name="feedName"/>  
        /// </summary>  
        /// <param name="feedName">Name of the feed</param>  
        /// <param name="feedItem"><see cref="FeedItem"/> to be saved</param>  
        public async void SaveFeedItem(string feedName, FeedItem feedItem)  
        {  
            var result = _context.Feeds.Find(x => x.Name.Equals(feedName)).ToList().FirstOrDefault();  
            if(result != null)  
            {  
                result.FeedItems.Add(feedItem);  
                await _context.Feeds.ReplaceOneAsync<FeedDocument>(x => x.Name == result.Name, result);  
            }  
        }  

        /// <summary>  
        /// Get all <see cref="FeedItem"/> present in database for given <paramref name="feedName"/>  
        /// </summary>  
        /// <param name="feedName"></param>  
        /// <returns></returns>  
        public FeedDocument GetFeedItems(string feedName)  
        {  
            return _context.Feeds.Find(x => x.Name.Equals(feedName)).ToList().FirstOrDefault();  
        }  
    }  
}
```

We have methods for getting all the feed documents, getting single feed document, get latest feeds for a given feed and updating status of given FeedItem. Notice carefully that almost all of the api methods provided by the mongodb driver are marked async. You can find the latest mongodb C# driver documentation here : [http://mongodb.github.io/mongo-csharp-driver/2.2/reference/](http://mongodb.github.io/mongo-csharp-driver/2.2/reference/ "http://mongodb.github.io/mongo-csharp-driver/2.2/reference/")

I am going to limit the content of this blog post till here. In the next post, I will build upon this infrastructure and add a web api layer on top of. Going further we will work on building a thin web client for interacting with the application. Our own mini feed reader.