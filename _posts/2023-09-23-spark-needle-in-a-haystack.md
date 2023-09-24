---
layout: post
title: Spark - Needle in a haystack story
tags: [Spark]
excerpt: In this short blog post, I will share an example of how executor logs helped us in narrowing down a malformed record that was causing our code to throw java.lang.ArithmeticException long overflow exception
---

I recently worked on upgrading an application running on Spark 2.2 to Spark 3.2. This was needed due to Spark 2.2 underlying dependencies having CVV 9.8 or above vulnerabilities. Given this was a major upgrade, we anticipated breaking changes and other upgrade related issues. But there was this one issue with datatime parsing that was incredibily difficult to narrow down but was really simple to fix. 

#### to_timestamp and long overflow exception
---

The underlying code was reading data from source Parquet files, applying some transformations, and persisting the output as Parquet. The source Parquet files had a few columns containing free text data, which the code was parsing and trying to convert to strongly typed output. For example, age was converted to an integer, and dates were identified by regex and parsed to a date type using the to_date or to_timestamp functions.

Unfortunately, due to the free text nature of the source data, it contained a few malformed records. In Spark 2.2, these malformed records did not cause any runtime issues and were simply resolved as null in the final output. However, with the Spark 3.2 upgrade, some underlying malformed date value caused the to_timestamp method call to throw an exception.

```scala
java.lang.ArithmeticException: long overflow
    at java.lang.Math.multiplyExact(Math.java:892)
    at org.apache.spark.sql.catalyst.util.DateTimeUtils$.millisToMicros(DateTimeUtils.scala:205)
    at org.apache.spark.sql.catalyst.util.DateTimeUtils$.fromJavaTimestamp(DateTimeUtils.scala:166)
    at org.apache.spark.sql.catalyst.CatalystTypeConverters$TimestampConverter$.toCatalystImpl(CatalystTypeConverters.scala:327)
```

The issue we were facing was quite similar to this one - [java.lang.ArithmeticException long overflow](https://stackoverflow.com/questions/69809656/why-do-year-and-month-functions-result-in-long-overflow-in-spark)

However, for us the challenge was, the source data contained millions of records, spread across hundreds of small parquet files. The driver log wasn't helpful because it didn't capture the data that resulted in the failure nor did it point to the exact line in our application code which eventually resulted in the above long overflow exception.

> I have tried replicating the issue in my local machine but somehow to_timestamp call with invalid date is resulting in null and not throwing an exception. I must be missing some spark configuration setting. I will update this post with an example as soon as I am able to replicate this long overflow issue.

#### Needle in the haystack
---

The team tried many things to fix the issue, including adding log statements, adding a try-catch block around the to_timestamp call, and so on, but nothing helped. The log message was always the same, and we were unable to narrow down and isolate the record that was causing the exception.

As mentioned earlier, the source data contained millions of records, spread across hundreds of Parquet files. We switched our focus from identifying the record to first identifying the underlying Parquet file that contained the malformed records.

Luckily, we were able to do this by looking at the executor logs in the Spark UI. In the Spark UI, the job details will tell you which job failed. Within the failed job, you can see which stage and which task within the stage failed. Let's say task ID 1000 failed. We then switched to the Spark UI's executors tab, picked the executor that had failed tasks, opened its stderr logs, and searched for the failed task ID (1000). As expected, in the logs, we found the specific Parquet file that was being read as part of this specific task. The log statement looked something like below:

```logs
23/01/01 23:10:10 INFO AsyncFileDownloader: TID: 1000 - Download file s3://........_part0.parquet
```

The log pinpointed the exact log file that contained the malformed record. To test our theory, we replicated the code that was causing the exception in an EMR notebook and tested it with just this single Parquet file. We were able to replicate the issue.

We successfully narrowed down the dataset from millions to a few hundred records. After this, identifying the malformed record and applying the fix took us less than an hour.

I have been working with Spark for more than five years now. For most of the time, we can figure out the issue with our Spark jobs with the help of the Spark UI and driver logs, but there are circumstances like the one mentioned in this post that tell us that executor logs are equally important.
