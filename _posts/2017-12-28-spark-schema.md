---
title: Working with schema in SparkSQL
tags: [Scala, Spark]
excerpt: In this blog post, we will see how to apply schema to SparkSQL DataFrames. We will also see, how to use Scala's implicits for converting DataFrame into strongly typed entities.
---
{% include base_path %}
{% include toc %}

In one of my previous [post]({% post_url 2017-12-23-spark-sql-part-1 %}) on [SparkSQL](http://spark.apache.org/sql/), we saw how [SparkSQL](http://spark.apache.org/sql/) can be used to run SQL queries against csv files. For ease of reference, I have copied the code snippet below :

> You can find the working code in my personal github repository here : [SparkPlayGround](https://github.com/pawanmishra/SparkPlayGround)

```scala
def main(args: Array[String]) {
    // setup SparkSession instance  
    val spark = SparkSession
      .builder()
      .appName("SparkSQL For Csv")
      .master("local[*]")
      .getOrCreate()

    import spark.implicits._

    // Read csv file
    val df = spark.read.option("header","true").option("delimiter",",").csv("/path/to/file/Person_csv.csv")

    // Registers the DataFrame in form of view
    df.createOrReplaceTempView("person")

    // Actual SparkSQL query
    val sqlPersonDF = spark.sql(
      """
        |SELECT
        |              PersonID AS PersonKey,
        |                'XYZ' AS IdentifierName,
        |                PersonIndex AS Extension,
        |                'A' AS Status
        |              FROM person
        |              WHERE
        |                PersonID IS NOT NULL AND PersonIndex IS NOT NULL
        |              UNION
        |              SELECT
        |                PersonID AS PersonKey,
        |                'ABC' AS IdentifierName,
        |                RecordNumber AS Extension,
        |                'A' AS RecordStatus
        |              FROM person
        |              WHERE
        |                PersonID IS NOT NULL AND RecordNumber IS NOT NULL
        |              UNION
        |              SELECT
        |                PersonID AS PersonKey,
        |                'MNO' AS IdentifierName,
        |                SSN AS Extension,
        |                'A' AS RecordStatus
        |              FROM person
        |              WHERE
        |                PersonID IS NOT NULL AND SSN IS NOT NULL
      """.stripMargin)

      // Print the result. See output below
      sqlPersonDF.show(50)
  }
```

Sample output from calling _sqlPersonDF.show()_.

```
+-------------+--------------+---------+------------+
|PersonKey|IdentifierName|Extension|RecordStatus|
+-------------+--------------+---------+------------+
|           17|           SSN| 74741646|           A|
|            7|          EMPI|       24|           A|
|           16|           SSN| 52389497|           A|
|            7|           SSN| 84645646|           A|
|            9|           MRN|925348562|           A|
.....
```

**sqlPersonDF** is of type [DataFrame](http://spark.apache.org/docs/latest/sql-programming-guide.html#datasets-and-dataframes). Calling _printSchema_ on **sqlPersonDF** prints the following :

```json
root
 |-- PersonKey: string (nullable = true)
 |-- IdentifierName: string (nullable = false)
 |-- Extension: string (nullable = true)
 |-- RecordStatus: string (nullable = false)
``` 

Notice how [SparkSQL](http://spark.apache.org/sql/) inferred all of the columns of type **string**. **IdentifierName** & **RecordStatus** are not-nullable probably because the columns had hard-coded values & [SparkSQL](http://spark.apache.org/sql/) used that for determining null-ability of columns. 

However from the sample data, its clear that PersonKey & Extension should be of type **int** instead of **string**. It would make sense to first convert the [DataFrame](http://spark.apache.org/docs/latest/sql-programming-guide.html#datasets-and-dataframes) in appropriate schema, before utilizing it further.

### Applying Schema via StructType
---

One way of applying schema to [DataFrame](http://spark.apache.org/docs/latest/sql-programming-guide.html#datasets-and-dataframes) is to construct an instance of [StructType](https://spark.apache.org/docs/1.5.0/api/java/org/apache/spark/sql/types/StructType.html) & create new [DataFrame](http://spark.apache.org/docs/latest/sql-programming-guide.html#datasets-and-dataframes) from existing one by passing [StructType](https://spark.apache.org/docs/1.5.0/api/java/org/apache/spark/sql/types/StructType.html) instance to [SparkSession](https://spark.apache.org/docs/2.0.1/api/java/org/apache/spark/sql/SparkSession.html)'s **map** method's overload which accepts custom schema as input parameter. Lets see this approach in action. I have copied the updated code below :

```scala
def main(args: Array[String]) {
    // setup SparkSession instance  
    val spark = SparkSession
      .builder()
      .appName("SparkSQL For Csv")
      .master("local[*]")
      .getOrCreate()

    import spark.implicits._

    // Read csv file
    val df = spark.read.option("header","true").option("delimiter",",").csv("/path/to/file/Person_csv.csv")

    /**
        BooleanType, ByteType, ShortType, IntegerType, LongType,
        FloatType, DoubleType, DecimalType, TimestampType, DateType,
        StringType, BinaryType
    */
    val schema = StructType(Seq(
      StructField("PersonKey", IntegerType, false),
      StructField("IdentifierName", StringType, false),
      StructField("Extension", IntegerType, false),
      StructField("RecordStatus", StringType, false)))

    // Registers the DataFrame in form of view
    df.createOrReplaceTempView("person")

    // Actual SparkSQL query
    val sqlPersonDF = spark.sql(
      """
        |SELECT
        |              PersonID AS PersonKey,
        |                'XYZ' AS IdentifierName,
        |                PersonIndex AS Extension,
        |                'A' AS Status
        |              FROM person
        |              WHERE
        |                PersonID IS NOT NULL AND PersonIndex IS NOT NULL
        |              UNION
        |              SELECT
        |                PersonID AS PersonKey,
        |                'ABC' AS IdentifierName,
        |                RecordNumber AS Extension,
        |                'A' AS RecordStatus
        |              FROM person
        |              WHERE
        |                PersonID IS NOT NULL AND RecordNumber IS NOT NULL
        |              UNION
        |              SELECT
        |                PersonID AS PersonKey,
        |                'MNO' AS IdentifierName,
        |                SSN AS Extension,
        |                'A' AS RecordStatus
        |              FROM person
        |              WHERE
        |                PersonID IS NOT NULL AND SSN IS NOT NULL
      """.stripMargin)

      // Print the result. See output below
      sqlPersonDF.show(50)

      // apply the schema
      val patientRdd = sqlPatientDF.map(x => Row(x(0).toString.toInt, x(1), x(2).toString.toInt, x(3)))(RowEncoder(schema))
    
      // print the schema
      patientRdd.printSchema()
```

Lets break down the code :

* First we have created instance of [StructType](https://spark.apache.org/docs/1.5.0/api/java/org/apache/spark/sql/types/StructType.html) instance by defining column names along with their expected column types. 
* Before we apply the schema, we have to ensure that incoming data is in sync with expected schema. Thus, in our map function, we are explicitly calling **toInt** method on fields we want to be of type int.
* Finally we pass the schema as additional parameter to **map** function.

Calling _printSchema_ on **patientRdd** prints the following :

```
root
 |-- PersonKey: integer (nullable = false)
 |-- IdentifierName: string (nullable = true)
 |-- Extension: integer (nullable = false)
 |-- RecordStatus: string (nullable = true)
```

We have successfully converted our input **sqlPatientDF** [DataFrame](http://spark.apache.org/docs/latest/sql-programming-guide.html#datasets-and-dataframes) into strongly typed **patientRdd** [DataFrame](http://spark.apache.org/docs/latest/sql-programming-guide.html#datasets-and-dataframes). However there is just one small problem or I should say inconvenience. Working with **patientRdd** will require us to work with internal [Spark](http://spark.apache.org) datatype called [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html). And if we have to intercept any of the row fields then we will have to use index positions e.g. Row(x(0), x(1)...) etc. Wouldn't it be nice, if we can somehow convert the raw [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html) datatype into something more presentable like an instance of below mentioned **PatientInfo** class?

```scala
case class PatientInfo(Key: Int, Identifier: String, Extension: Int, Status: String)
```

Converting raw data in an instance of **PatientInfo** is quiet simple and only requires minor changes in the above code. I have copied the modified code below & for brevity purpose, removed some pieces of it.

```scala
case class PatientInfo(Key: Int, Identifier: String, Extension: Int, Status: String)

object SchemaInPlay {

  implicit def rowToPatient(row: Row): PatientInfo = {
    PatientInfo(row.getInt(0), row.getString(1), row.getInt(2), row.getString(3))
  }

  def main(args: Array[String]) {
    val spark = SparkSession
      .builder()
      .appName("SparkSQL For Csv")
      .master("local[*]")
      .getOrCreate()

    import spark.implicits._
    ........
    ........
    sqlPatientDF.printSchema()

    val patientRdd = sqlPatientDF.map(x => Row(x(0).toString.toInt, x(1), x(2).toString.toInt, x(3)))(RowEncoder(schema))

    patientRdd.printSchema()
    patientRdd.foreach(printPatients(_))
    spark.stop()
  }

  def printPatients(patient: PatientInfo): Unit = {
    println(s"${patient.Key} - ${patient.Extension}")
  }
}
```

Let's go through all of the changes that we have introduced in the above code snippet :

* Defined **PatientInfo** case class. Later in code, we will map every row of **patientRdd** into an instance of **PatientInfo** class.
* Defined function _printPatients_ which accepts instance of **PatientInfo** and prints something on console. 
* We have defined _rowToPatient_ method which accepts instance of [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html) and converts it into instance of **PatientInfo**.
* We are calling _printPatients_ on **patientRdd**'s _foreach_ method. But where exactly are we converting **patientRdd** [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html) into **PatientInfo**?

Conversion from [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html) into **PatientInfo** happens behind the screen via Scala's support for [implicits](http://docs.scala-lang.org/tutorials/tour/implicit-parameters.html). Implicits are yet another advanced & quiet fascinating capability of Scala. Implicits are Scala's way of giving another try to resolve the runtime problem before giving up & throwing exception. In languages like C# or Java, the above code will not compile. No way, C# or Java compiler will convert [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html) into **PatientInfo** for us. Scala compiler on the other hand, looks for any method which can do the required conversion & luckily it finds our _rowToPatient_ method. If you have noticed, we marked _rowToPatient_ as **implicit**, telling Scala compiler to keep an eye for [Row](https://spark.apache.org/docs/latest/api/java/index.html?org/apache/spark/sql/Row.html) to **PatientInfo** conversion & if not explicitly invoked, then go ahead and insert the method call on your own.

[Implicits](http://docs.scala-lang.org/tutorials/tour/implicit-parameters.html) are quiet broad & advanced topics. I strongly encourage you to learn & try to use it in your scala code.

Once again, you can find the complete code in my [SparkPlayGround](https://github.com/pawanmishra/SparkPlayGround) github repository.
 
