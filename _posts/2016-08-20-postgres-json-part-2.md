---
title: Postgres and Json - Part2
tags: [postgres, jsonb]
excerpt: In this blog post, we are going to explore some of the **json** related operators & functions specific to filtering & processing of json based data.
---
{% include toc %}

In the previous [post]({% post_url 2016-08-19-postgres-json-part-1 %}), we looked at functions which help in creation of json structured documents in postgres database. We were able to consolidate all of the customer related information in json format & we saved all the records in **customer_agg** table. 

### Functions & Operators
---
In this post, we are going to look into general json processing & filtering related functions & operators. 

#### json\_agg
---
Currently the **customer_agg** table contains 599 jsonb records. One for each customer. We can use **json\_agg** function to return all or few records in form of jsonb array. 

```sql
select json_agg(agg_data) from customer_agg;
```
The above query, combines all the records & return it form of json array. If running the above query is taking longer than expected then you can run the below query for sampling purpose.

```sql
select json_agg(agg_data) from 
(select * from customer_agg limit 2) agg_data;
```
***Result***

| json_agg |
| --- |
| [{"email": "jared.ely@sakilacustomer.org", "active": 1, "titles": ["Breaking Home", "Bucket Brotherhood", "Celebrity Horn", "Chasing Fight", "Clerks Angels", "Crooked Frogmen", "Expecations Natural", "Insects Stone", "Island Exorcist", "League Hellfighters", "Oz Liaisons", "Party Knock", "Reds Pocus", "Secrets Paradise", "Sleepless Monsoon", "Straight Hours", "Sweethearts Suspects", "Whale Bikini", "Wind Phantom"], "address": {"city": "Purwakarta", "postal": "25972", "country": "Indonesia", "address1": "1003 Qinhuangdao Street", "address2": "", "district": "West Java"}, "first_name": "Jared", "customer_id": 524}, {"email": "mary.smith@sakilacustomer.org", "active": 1, "titles": ["Adaptation Holes", "Amistad Midsummer", "Attacks Hate", "Bikini Borrowers", "Closer Bang", "Confidential Interview", "Dalmations Sweden", "Detective Vision", "Doors President", "Expecations Natural", "Ferris Mother", "Finding Anaconda", "Fire Wolves", "Fireball Philadelphia", "Fireball Philadelphia", "Frost Head", "Jeepers Wedding", "Jumanji Blade", "Luck Opus", "Minds Truman", "Musketeers Wait", "Patient Sister", "Patient Sister", "Racer Egg", "Saturday Lambs", "Savannah Town", "Snatch Slipper", "Talented Homicide", "Unforgiven Zoolander", "Usual Untouchables", "Women Dorado", "Youth Kick"], "address": {"city": "Sasebo", "postal": "35200", "country": "Japan", "address1": "1913 Hanoi Way", "address2": "", "district": "Nagasaki"}, "first_name": "Mary", "customer_id": 1}]|

#### -> vs ->>
---
Accessing individual properties within json record is quiet natuarlly one of the most obvious requirement from any library meant for json processing. In postgres, we can access individual properties via **->** and **->>** operator. But why two operator? Run the below query & see the output:

```sql
select agg_data ->> 'email' email, agg_data -> 'first_name' first_name 
from customer_agg limit 1;
```
***Result***

| email | first_name |
| --- | --- |
| jared.ely@sakilacustomer.org | "Jared" |

Notice how the email is plain text but first_name is wrapped in double quotes. In order to determine the actual data type, run the below query.

```sql
select pg_typeof(agg_data ->> 'email') email, pg_typeof(agg_data -> 'first_name') first_name 
from customer_agg limit 1;
```
***Result***

| email | first_name |
| --- | --- |
| text | jsonb |

As we can see, **->>** returns the text representation whereas **->** returns the actual data type i.e. jsonb or json.

We can also chain these operator to access nested json properties. For e.g. we can access city property which is nested inside address property via : **agg_data -> 'address' -> 'city'**

Following query prints consolidated list of cities to which our customers belong to.

```sql
select agg_data -> 'address' ->> 'city' city
from customer_agg;
```

#### jsonb\_array\_length
---
The above function is self-explanatory. It accepts **json** or **jsonb** array and prints the length of the array. Lets use this function to print, for every customer the number of titles rented by that individual.

```sql
select agg_data ->> 'first_name' first_name, jsonb_array_length(agg_data -> 'titles') titles
from customer_agg;
```

***Sample Result***

| first_name | titles |
| --- | --- |
| Jared | 19 |

We can use the same function for filtering purpose. Say if we only want list of customers who have rented more than 20 tiltes then we can run the following query:

```sql
select agg_data ->> 'first_name' first_name, jsonb_array_length(agg_data -> 'titles') titles
from customer_agg
where jsonb_array_length(agg_data -> 'titles') > 20;
```

#### jsonb\_to\_record
---

**jsonb\_to\_record**(and similar function for **json**) helps is de-constructing **jsonb** record back into relational format. Consider the below sql:

```sql
select *
from jsonb_to_record('{"email": "jared.ely@sakilacustomer.org", "active": 1, "titles": ["Breaking Home", "Bucket Brotherhood", "Celebrity Horn", "Chasing Fight", "Clerks Angels", "Crooked Frogmen", "Expecations Natural", "Insects Stone", "Island Exorcist", "League Hellfighters", "Oz Liaisons", "Party Knock", "Reds Pocus", "Secrets Paradise", "Sleepless Monsoon", "Straight Hours", "Sweethearts Suspects", "Whale Bikini", "Wind Phantom"], "address": {"city": "Purwakarta", "postal": "25972", "country": "Indonesia", "address1": "1003 Qinhuangdao Street", "address2": "", "district": "West Java"}, "first_name": "Jared", "customer_id": 524}')
as x(email text, active boolean, titles text, address jsonb, first_name text, customer_id int); 
```

Running the above sql returns the following result in relational aka tabular format:

***Result***

| email | active | titles | address | first_name | customer_id |
| --- | --- | --- | --- | --- | --- |
| jared.ely... | t | ["Breaking Home", ...] | {"city":... }| Jared| 524|

As we can see, the input json record is converted back into tabular format. It's important to note that we have to explicitly tell **jsonb\_to\_record** function the data types of properties of json record. From the above query:

> as x(email text, active boolean, titles text, address jsonb, first_name text, customer_id int)

Few things to note here:

* If we do not provide a mapping for a property say remove **email text** from above definition, the **json to record** function will skip that property & the output will not have the corresponding column.
* If we provide wrong data type, then postgres will complain. Try changing **email text** to **email int**. However postgres will try its best to map the record to expect data type via data type coercion.

What if instead of explicit json string, you want to reference a column of type **jsonb** or **json**. In that you will also have to provide the source table name in from clause. Example query:

```sql
select x.* from customer_agg ca, jsonb_to_record(ca.agg_data)
as x(email text, active boolean, titles text, address jsonb, first_name text, customer_id int)
limit 1;
```

Running the above query returns exactly the same result as previous one in which we provided the explicit jsonb string. As evident from above query, the tranformed resultset is referenced via alias **x**.

#### jsonb\_to_recordset
---
The previous function is capable of converting individual **jsonb** record into relational format. What if we have an array of **jsonb** records? What we are looking for is a way to convert array of **jsonb** records in individial rows of record in relational format. **jsonb to recordset** helps in achieving the desired result. Run the below query:

```sql
;with t0 as(select agg_data from customer_agg limit 2),
t1 as (select json_agg(agg_data) record
from t0)
select x.* from t1, json_to_recordset(t1.record)
as x(email text, active boolean, titles text, address jsonb, first_name text, customer_id int);
```

The above query might seem little complicated but I did it on purpose because I wanted to limit the resultset to two records. Running the above query returns the following result:

***Result***

| email | active | titles | address | first_name | customer_id |
| --- | --- | --- | --- | --- | --- |
| jared.ely... | t | ["Breaking Home", ...] | {"city":... }| Jared| 524|
| mary.smith... | t | ["Crazy Home", ...] | {"city":... }| Mary| 1|

As we can see, it's possible thought not very intutive to convert **jsonb** records back into relational format.

#### Contaiment operator : @>
---

Containment operator helps in determing if the jsonb record contains the given value. For e.g. if we want to filter out all the records where first_name is **Mary** then we can use containment operator as below:

```sql
select * from customer_agg where agg_data @> '{"first_name":"Mary"}'::jsonb
```

For every record, the query evaluates if the json contains **{"first_name" : "Mary"}**. We can thus use this operator for searching any kind of pattern. For e.g. we can filter out all records where city equals **Sasebo** given that city is contained within nested json via following query:

```sql
select * from customer_agg where agg_data @> '{"address": {"city":"Sasebo"}}'::jsonb
```

Like containment operator, there are other operators too. It's difficult to cover all of the operators in one blog post. You can find all those operators [here](https://www.postgresql.org/docs/9.4/static/functions-json.html)

### Summary
---

In the two part series, I have tried to cover the most important & frequently used functions & operators for handling jsonb related data in postgres. Working through the examples presented in this series has helped me a lot in understanding of json support in postgres database.


