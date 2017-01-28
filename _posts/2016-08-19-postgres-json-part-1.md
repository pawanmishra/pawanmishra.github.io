---
layout: splash
title: Postgres and Json - Part1
tags: [postgres, jsonb]
excerpt: In this blog post, we are going to look into the various **json** related functions available in postgres database specific to json creation.
---
{% include toc %}

In this blog post, we are going to look into the various **jsonb** related functions available in postgres database. The support for json based data in postgres db has significantly improved in past few versions. And with the introduction of **jsonb** format, it has practically made postgres a viable option for storing json based data. 

Now supporting json as datatype will not be of much use, if developers manipulate json data easily. Thankfully, postgres contains various functions & operators which simplifies the task of document creation & manipulation. 

In this blog post, I am going to concentrate mainly on functions which help in document creation. In the next post, I will concentrate on functions & operators which help in filtering & processing of json based data.

> **Note**: For a quick overview of JSON functions & operators in Postgres, you can refer the official documentation [here](https://www.postgresql.org/docs/9.4/static/functions-json.html)

> **Note**: Postgres db has two different data types for json related data namely **json** & **jsonb**. It's quiet rare that you will ever use **json** data type in production. Thus 
most of the functions presented in this & the following post are in reference with **jsonb** data type. I will however use the term **json** irrespective of the data type.

### SetUp
---
Before we can proceed with our examples we need a database against which we are going to run our queries. I am making an assumption that you have [postgres 9.5](https://www.postgresql.org) database installed & up and running in your machine.

#### Restoring dvdrental database
---
For this post, we are going to use the [dvdrental](http://www.postgresqltutorial.com/postgresql-sample-database/) database. The command for restoring the downloaded file into a database is:

> pg\_restore -h {host_name} -p {port} -U postgres -d dvdrental "~/filepath/dvdrental.tar" -v

Some points to consider:

* pg_restore command accepts various arguments. You can find the necessary details [here](https://www.postgresql.org/docs/9.5/static/app-pgrestore.html)
* host_name & port are necessary if postgres db is running in vm or remote server
* Downloaded file is in zip format. You can convert it into tar format via command : **tar -xf dvdrental.zip dvdrental.tar**

#### dvdrental schema
---
**dvdrental** database contains following tables:

* **actor** – stores actors data including first name and last name.
* **film** – stores films data such as title, release year, length, rating, etc.
* **film_actor** – stores the relationships between films and actors.
* **category** – stores film’s categories data.
* **film_category** - stores the relationships between films and categories.
* **store** – contains the stores data including manager staff and address.
* **inventory** – stores inventory data.
* **rental** – stores rental data.
* **payment** – stores customer’s payments.
* **staff** – stores staff data.
* **customer** – stores customers data.
* **address** – stores address data for staff and customers
* **city** – stores the city names.
* **country** – stores the country names.

In this post, we will concentrate mostly on ***customer*** related information.

### Functions & Operators
--- 
With our database ready, we can start exploring the various ***json/jsonb*** related funtions & operators available in postgres database. 

In the current state, the customer information is denormalized & saved in different tables. It would be great if we can bring all of the customer related information & represent it in json format as given below:

```json
{
  "first_name": "Pawan",
  "last_name": "Mishra",
  "email": "test@test.com",
  "active": true,
  "address": {
    "address1": "47 MySakila Drive",
    "address2": "",
    "district": "travis",
    "city": "austin",
    "postal": "12345",
    "country": "USA"
  },
  "rented_films": "['Mystic Truman','Robbery Bright','Teen Apollo']"
}
```
With the help of ***jsonb*** based functions & operators, we are going to work on building the above json document. 

Lets get started!!

#### json\_build_object
---
First thing we are going to try is to construct the nested **address** json. Sql query for fetching address of given customer looks like below:

```sql
select cc.first_name, cc.last_name, a.address, a.address2, a.district, a.postal_code,
c.city, ct.country from address a
inner join city c on a.city_id = c.city_id
inner join country ct on ct.country_id = c.country_id
inner join customer cc on cc.address_id = a.address_id
```
***Sample result***

| first\_name | last_name | address1 | address2 | distict | postal | city | country |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Jared | Ely	 | 1003 Qinhuangdao Street | | West Java | 25972 | Purwakarta | Indonesia |

Let convert the above record into json format using **json\_build_object** function.

> **json\_build_object** : This function accepts an even number of arguments(of any type) and it convents each recurring pair into key-value format. 

Run the following query & you will notice how the above function converts the resultset into json document:

```sql
select json_build_object('address1', a.address, 'address2', a.address2, 'district', a.district, 'postal', 
a.postal_code, 'city', c.city, 'country', ct.country) as address from address a
inner join city c on a.city_id = c.city_id
inner join country ct on ct.country_id = c.country_id
inner join customer cc on cc.address_id = a.address_id;
```
As I mentioned in the note, the function converts each recurring pair(**'customer1'** & **a.address**) into key value pair wherein first value being the key & second the value. 

***Result***

```json
{"address1" : "1003 Qinhuangdao Street", "address2" : "", "district" : "West Java", "postal" : "25972", "city" : "Purwakarta", "country" : "Indonesia"}
```
Next lets look at how we can return the list of rented movies in array format.

#### array\_to_json
---
In order to get list of rented films for every customer, we have to basically use some sort of aggregate function. The below query uses **array_agg** for achieveing the desired result:

```sql
select c.customer_id, 
(select array_agg(aa.title) from 
(select f.title from rental r inner join inventory i on r.inventory_id = i.inventory_id
inner join film f on f.film_id = i.film_id where r.customer_id = c.customer_id) aa) as titles
from customer c;
```

***Sample result***

| customer\_id | titles |
| --- | --- |
| 121 | {"Breaking Home","Bucket Brotherhood",..} |

If you notice carefully then the value under **titles** column is not exactly an array. In order to determine the exact type we can use an additional function called : **pg_typeof()**.

Run the below query once again:

```sql
select c.customer_id, 
(select pg_typeof(array_agg(aa.title)) from 
(select f.title from rental r inner join inventory i on r.inventory_id = i.inventory_id
inner join film f on f.film_id = i.film_id where r.customer_id = c.customer_id) aa) as titles
from customer c;
```

This time the result will be:

| customer\_id | titles |
| --- | --- |
| 121 | character varying[] |

character varying[] aka text array. In order to convert it into json specific array, wrap the array_agg function in **array\_to\_json** function.

```sql
select c.customer_id, 
(select array_to_json(array_agg(aa.title)) from 
(select f.title from rental r inner join inventory i on r.inventory_id = i.inventory_id
inner join film f on f.film_id = i.film_id where r.customer_id = c.customer_id) aa) as titles
from customer c;
```
***Result*** 

| customer\_id | titles |
| --- | --- |
| 121 | ["Breaking Home","Bucket Brotherhood",..] |

With the above two functions, we have sorted out the two complex piece of our json i.e. nested json structure & array of items. It's time to generate the entire json document.

#### row\_to_json
---
In order to generate the json with complete customer information, I am going to make use of the previous queries. The final query which generates the json is not pretty i.e. it uses two nest sub-queries but overall logic is straight forward.

```sql
select row_to_json(record) from
(select c.customer_id, c.first_name, c.first_name, c.email, c.active,
	(select json_build_object('address1', a.address, 'address2', a.address2, 'district', a.district, 'postal', 
	a.postal_code, 'city', ci.city, 'country', ct.country) as address from address a
	inner join city ci on a.city_id = ci.city_id
	inner join country ct on ct.country_id = ci.country_id
	inner join customer cc on cc.address_id = a.address_id where cc.customer_id = c.customer_id) as address,
	(select array_to_json(array_agg(aa.title)) from 
	(select f.title from rental r inner join inventory i on r.inventory_id = i.inventory_id
	inner join film f on f.film_id = i.film_id where r.customer_id = c.customer_id) aa) as titles
from customer c) as record;
```
Trust me. The above query works. Calling **row\_to_json** as part of outermost query, converts the entire relational record into json document.

***Result***

```json
{"customer_id":524,"first_name":"Jared","first_name":"Jared","email":"jared.ely@sakilacustomer.org","active":1,"address":{"address1" : "1003 Qinhuangdao Street", "address2" : "", "district" : "West Java", "postal" : "25972", "city" : "Purwakarta", "country" : "Indonesia"},"titles":["Breaking Home","Bucket Brotherhood","Celebrity Horn","Chasing Fight","Clerks Angels","Crooked Frogmen","Expecations Natural","Insects Stone","Island Exorcist","League Hellfighters","Oz Liaisons","Party Knock","Reds Pocus","Secrets Paradise","Sleepless Monsoon","Straight Hours","Sweethearts Suspects","Whale Bikini","Wind Phantom"]}
```
Clearly viewing the above json is not easy. Luckily **row\_to_json** function accepts another parameter which when passed, converts the json into pretty-format.

```sql
select row_to_json(record, true) from
(select c.customer_id, c.first_name, c.first_name, c.email, c.active,
	(select json_build_object('address1', a.address, 'address2', a.address2, 'district', a.district, 'postal', 
	a.postal_code, 'city', ci.city, 'country', ct.country) as address from address a
	inner join city ci on a.city_id = ci.city_id
	inner join country ct on ct.country_id = ci.country_id
	inner join customer cc on cc.address_id = a.address_id where cc.customer_id = c.customer_id) as address,
	(select array_to_json(array_agg(aa.title)) from 
	(select f.title from rental r inner join inventory i on r.inventory_id = i.inventory_id
	inner join film f on f.film_id = i.film_id where r.customer_id = c.customer_id) aa) as titles
from customer c) as record;
```
***Pretty Result***

```json
{"customer_id":524,
 "first_name":"Jared",
 "first_name":"Jared",
 "email":"jared.ely@sakilacustomer.org",
 "active":1,
 "address":{"address1" : "1003 Qinhuangdao Street", "address2" : "", "district" : "West Java", "postal" : "25972", "city" : "Purwakarta", "country" : "Indonesia"},
 "titles":["Breaking Home","Bucket Brotherhood","Celebrity Horn","Chasing Fight","Clerks Angels","Crooked Frogmen","Expecations Natural","Insects Stone","Island Exorcist","League Hellfighters","Oz Liaisons","Party Knock","Reds Pocus","Secrets Paradise","Sleepless Monsoon","Straight Hours","Sweethearts Suspects","Whale Bikini","Wind Phantom"]}
```

### Data Aggregation
---
Before I complete this post, I would like to perform one additional step. I want to copy all of the aggregated customer json data into another table called **customer_agg**. Go ahead & run the below sql:

```sql
CREATE TABLE "public"."customer_agg" (
	"agg_data" jsonb
)
WITH (OIDS=FALSE);
ALTER TABLE "public"."customer_agg" OWNER TO "postgres";
```

Next run the below sql which will copy the generated json records in the new table.

```sql
insert into customer_agg(agg_data)
select row_to_json(record) from
(select c.customer_id, c.first_name, c.first_name, c.email, c.active,
	(select json_build_object('address1', a.address, 'address2', a.address2, 'district', a.district, 'postal', 
	a.postal_code, 'city', ci.city, 'country', ct.country) as address from address a
	inner join city ci on a.city_id = ci.city_id
	inner join country ct on ct.country_id = ci.country_id
	inner join customer cc on cc.address_id = a.address_id where cc.customer_id = c.customer_id) as address,
	(select array_to_json(array_agg(aa.title)) from 
	(select f.title from rental r inner join inventory i on r.inventory_id = i.inventory_id
	inner join film f on f.film_id = i.film_id where r.customer_id = c.customer_id) aa) as titles
from customer c) as record;
```

With this we have successfully copied all of the customer aggregated json data in new table. 

### Summary
---
In this post, we looked at the three main jsonb related functions which help in creating json based data. In the end we copied the aggregated json data into a new table. In the next [post]({% post_url 2016-08-20-postgres-json-part-2 %}), I will concentrate mainly on filtering & processing related functions. I hope you have enjoyed this post.