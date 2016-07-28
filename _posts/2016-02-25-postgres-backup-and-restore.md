---
layout: single
title: Postgres - BackUp & Restore
---
In this blog post, I am going to share with you all the commands required for taking database back-up & restoring database from those back-up files. I am working with [Postgres](http://www.postgresql.org/) database and I am using Navicat IDE. Now taking back-up & restoring database is possible with Navicat but for some reason in my case I was experiencing large delays in database restore. Thus I decided to switch back to the proven approach of taking database back-up & restore via command line. Lets get started.

> Note: The commands listed below in the post are available in official documentation page. This post is more like a book keeping exercise for me so that I can easily look-up the command & setup information in future.

### Psql command
---

The very first thing we need is the **psql** shell command. I am having a mac book and the [Postgres](http://www.postgresql.org/) database is running inside a Ubuntu VM. I need a way to connect to the [Postgres](http://www.postgresql.org/) instance hosted inside VM from my OSX operating system. So if you are like me and you don’t have [Postgres](http://www.postgresql.org/) installed locally then go ahead and download **postgres.app** toolset from [here](http://postgresapp.com/). Run the app after installing it. It will open up a console pointing to the bin directory of the app containing various Unix executable files along with the psql binary. The path would look like this : **/Applications/Postgres.app/Contents/Versions/9.5/bin**

Next thing we need to do is to add this path to our machines system path. Run the following command :

> export PATH=$PATH:/Applications/Postgres.app/Contents/Versions/9.5/bin

Now you will be able to invoke the psql shell command from anywhere in your machine.

### Taking database dump : pg_dump  
---

The command for taking database dump is :

> pg_dump -h <host_name> -p 5432 -U postgres -F c -b -v -f  "<path>/<file_name>" <database_name>

Like me if your [Postgres](http://www.postgresql.org/) database is hosted in other machine or inside VM then provide the ip address of the machine where host_name is required. The command assumes that [Postgres](http://www.postgresql.org/) is listening on post 5432 and “postgres” is the database user name. You can read about the additional command line arguments here : [http://www.postgresql.org/docs/9.5/static/app-pgdump.html](http://www.postgresql.org/docs/9.5/static/app-pgdump.html "http://www.postgresql.org/docs/9.5/static/app-pgdump.html")

### Restoring database from dump file : pg_restore
---

The command for restoring database from dump file is :

> pg_restore -h <host_name> -p 5432 -U postgres -d <database_name> -v "<file_path>”

The argument names are self explanatory. Ensure that you have first created the database before restoring it. You can more details about the pg_restore command here : [http://www.postgresql.org/docs/9.5/static/app-pgrestore.html](http://www.postgresql.org/docs/9.5/static/app-pgrestore.html "http://www.postgresql.org/docs/9.5/static/app-pgrestore.html")