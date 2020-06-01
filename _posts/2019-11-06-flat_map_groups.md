---
layout: post
title: Spark Patterns - FlatMapGroups
tags: [Scala, Spark]
excerpt: In this blog post, I am going to explain you with an example on how we can use the FlatMapGroups api for implementing complex logic against grouped datasets.
---
{% include base_path %}
{% include toc %}

This is the first post in the _**Spark Patterns**_ series. In this post, I am going to explain with an example as to how we can use the [_**FlatMapGroups**_](https://spark.apache.org/docs/2.2.1/api/java/org/apache/spark/sql/KeyValueGroupedDataset.html) api for implementing a relatively complex algorithm against grouped dataset. After you have understood the pattern, you should be able to use it in other places within your codebase.

### Dataset
---

For this blog post, I am going to use the sales dataset which you can download from here - [sales](http://eforexcel.com/wp/downloads-18-sample-csv-files-data-sets-for-testing-sales/). I have downloaded the 50K record dataset. Following code snippet, reads the downloaded csv file and prints the schema of the dataframe.

```scala
// load data
val sales = session.read.option("delimiter", ",").option("header", "true").option("inferSchema", "true").csv(s"/Users/pmishr43/dev/data/sales_records.csv")

// print schema
sales.printSchema()
```

**Output**
```
root
 |-- Region: string (nullable = true)
 |-- Country: string (nullable = true)
 |-- ItemType: string (nullable = true)
 |-- SalesChannel: string (nullable = true)
 |-- OrderPriority: string (nullable = true)
 |-- OrderDate: string (nullable = true)
 |-- OrderID: integer (nullable = true)
 |-- ShipDate: string (nullable = true)
 |-- UnitsSold: integer (nullable = true)
 |-- UnitPrice: double (nullable = true)
 |-- UnitCost: double (nullable = true)
 |-- TotalRevenue: double (nullable = true)
 |-- TotalCost: double (nullable = true)
 |-- TotalProfit: double (nullable = true)
```

* _**Region**_ - Large geographic area comprising of multiple countries e.g. Europe, Sub-Saharan Africa, etc
* _**ItemType**_ - Type of the item purchased e.g. Household, cosmetics, etc.
* _**SalesChannel**_ - Item bought online or offline
* _**OrderPriority**_ - Relative priority of the placed order. Values include - L(Low), M(Medium), H(High) & C(critical)

Rest of the columns and their purpose in the dataset is self explanatory.

### Problem Definition
---

In the sales dataset, for every region, sort the data by OrderDate, then roll-up the data using the below mentioned logic:

> Starting with the first record, roll-up all of the following records in one, if their OrderPriority is of same type. By roll-up, I meant, aggregate the UnitsSold value. If the OrderType is different between consecutive records, then emit them as separate output values.

**Example**

*Input*

|OrderPriority|UnitsSold|
|-------------|-----------|
|L|10|
|L|20|
|H|10|
|M|10|
|L|5|
|M|5|
|M|50|

*Output*

|OrderPriority|UnitsSold|
|-------------|-----------|
|L|30|
|H|10|
|M|10|
|L|5|
|M|55|

### Solution
---

Now there could be multiple ways in which we could solve this problem. But since this blog post is about [_**FlatMapGroups**_](https://spark.apache.org/docs/2.2.1/api/java/org/apache/spark/sql/KeyValueGroupedDataset.html), I am going to show you, how we can very easily implement the above mentioned moderatly complex roll-up logic in _Scala_ and use it along with Spark FlatMapGroups api. But first thing first, lets define few case classes. We need case classes for the input sales record and for the final output rolled up dataset.

```scala
// I have ommited few columns from the case class definition that are not required for this example
case class Sales(region: String, country: String, itemType: String, salesChannel: String, orderPriority: String, orderDate: java.sql.Date, unitsSold: Integer)

// We are only interested in the following columns in the final output
case class RolledUpSales(region: String, orderPriority: String, unitsSold: Integer)
```

Next, we should read the input csv and map it to the above case class definition:

```scala
// load data
val sales = session
    .read.option("delimiter", ",").option("header", "true").option("inferSchema", "true")
    .csv(s"/Users/pmishr43/dev/data/sales_records.csv")
    .select(
        $"Region".as("region"),
        $"Country".as("country"),
        $"ItemType".as("itemType"),
        $"SalesChannel".as("salesChannel"),
        $"OrderPriority".as("orderPriority"),
        to_date($"OrderDate", "MM/dd/yyyy").as("orderDate"),
        $"UnitsSold".as("unitsSold")).as[Sales]
```

Finally, it's time to implement the core roll-up logic using the [**FlatMapGroup**](https://spark.apache.org/docs/2.2.1/api/java/org/apache/spark/sql/KeyValueGroupedDataset.html) api.

```scala
package Demo

import org.apache.spark.sql.SparkSession

import scala.annotation.tailrec

object DemoWork {

  def main(args: Array[String]): Unit = {
    
    // 1
    val session = SparkSession.builder()
      .appName("Blog_Demo")
      .config("spark.sql.parquet.writeLegacyFormat", value = true)
      .getOrCreate()

    session.sparkContext.setLogLevel("WARN")

    import session.implicits._
    import org.apache.spark.sql.functions._

    // 2
    val sales = session
      .read.option("delimiter", ",").option("header", "true").option("inferSchema", "true")
      .csv(s"/Users/pmishr43/dev/data/sales_records.csv")
        .select(
          $"Region".as("region"),
          $"Country".as("country"),
          $"ItemType".as("itemType"),
          $"SalesChannel".as("salesChannel"),
          $"OrderPriority".as("orderPriority"),
          to_date($"OrderDate", "MM/dd/yyyy").as("orderDate"),
          $"UnitsSold".as("unitsSold")).as[Sales]

    // 3
    val output = sales.groupByKey(item => item.region).flatMapGroups(rollUpSales)
    output.show(false)
  }

  private def rollUpSales(region: String, sales: Iterator[Sales]): Seq[RolledUpSales] = {
    
    // 4
    val sortedDataset = sales.toSeq.sortWith((a, b) => a.orderDate.before(b.orderDate))

    // 5
    @tailrec
    def rollUp(items: List[Sales], accumulator: Seq[RolledUpSales]): Seq[RolledUpSales] = {
      items match {
        case x::xs =>
          val matchingPriority = xs.takeWhile(p => p.orderPriority.equalsIgnoreCase(x.orderPriority))
          val nonMatchingPriority = xs.dropWhile(p => p.orderPriority.equalsIgnoreCase(x.orderPriority))
          val record = RolledUpSales(region, x.orderPriority, matchingPriority.map(_.unitsSold).foldLeft(x.unitsSold)(_ + _))
          val rolledUpRecord = record +: accumulator
          rollUp(nonMatchingPriority, rolledUpRecord)
        case Nil => accumulator
      }
    }

    rollUp(sortedDataset.toList, Seq.empty).reverse
  }
}

case class Sales(region: String, country: String, itemType: String, salesChannel: String, orderPriority: String, orderDate: java.sql.Date, unitsSold: Integer)
case class RolledUpSales(region: String, orderPriority: String, unitsSold: Integer)
```

**Explanation**

**1** - I am using a bash script for invoking the spark-submit command. Most of the spark related configs are present in that bash script.

**2** - Read the csv files and limit the dataframe to columns that we are interested in(or present in the Sales case class).

**3** - Group the _Sales_ dataframe by the region key and then invoke the _**flatMapGroups**_ function against it. In the _**flatMapGroups**_ function, we are passing the group by key(region) and an iterator containing the records that belong to that key. The key could be anything i.e. simple variable or multi-field case class.

**4** - In the _**rollUpSales**_ function, we first sort the dataset by the _OrderDate_

**5** - Most of the magic happens in this function. We start with the first element. Divide the collection into two sets i.e. set containing similar OrderPriority and another set containing remaining elements. We create a case class called _**record**_ containing the output for the current iteration. Repeat the process until elements are present in the collection. Finally, return the accumlated resultset.

**Output**

As you can see in the below table, none of the OrderPriorities are repeated consecutively. Thus our roll-up functionality is working.  

```
+----------------------------+-------------+---------+
|region                      |orderPriority|unitsSold|
+----------------------------+-------------+---------+
|Middle East and North Africa|M            |1223     |
|Middle East and North Africa|H            |12902    |
|Middle East and North Africa|C            |29       |
|Middle East and North Africa|L            |459      |
|Middle East and North Africa|C            |7668     |
|Middle East and North Africa|H            |7603     |
|Middle East and North Africa|M            |1032     |
|Middle East and North Africa|L            |187      |
```

### Conclusion
---

As I have mentioned before, we could have solved this problem in multiple different ways. We could have used raw SQL constructs, pure Spark DataFrame API, etc. But having to implement complex roll-up logic against grouped datasets using pure SQL constructs could lead to very complex and hard-to-understand implementations. With _**FlatMapGroups**_, as we can see above, we can use Scala collections and it's rich api for solving the same problem in a much more clean and efficient manner. 





