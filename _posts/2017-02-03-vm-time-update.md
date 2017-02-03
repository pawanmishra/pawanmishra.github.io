---
layout: splash
title: Setting date & time in Linux VM
tags: [Random]
excerpt: In this blog post, I will provide you steps for setting date & time in Linux VM through command prompt.
---
{% include base_path %}

This one is going to be a quick & small post.

I am running Linux based VM in my local & running **date** command wasn't returning correct date & time value. Ideally VM should configure date & time value automatically from host machine but running **date** command returned different values. E.g. below is the output from host machine:

```shell
~ date
Thu Feb 02 21:56:39 CST 2017
```

and output from VM:

```shell
[root@sandbox ~]# date
Sun Jan 22 02:17:21 UTC 2017
```

Updating date from command line is simple. Just run **date -s <date>** command. In my case, I ran the below command:

```shell
[root@sandbox ~]# date -s 'Thu Feb  2 21:56:39 CST 2017'
Fri Feb  3 03:56:39 UTC 2017
```

Well something happened. But definitly not what I expected. Running of date command did update the date & time value but also changed the timezone. Next, lets see how we can fix timezone. Fixing timezone will take care of date & time as well.

Current timezone is represented via file called **localtime** present under _**/etc/**_ directory. Ideally **localtime** is supposed to be a symbolic link file pointing to another directory(_**/usr/shaper/zoneInfo**_) containing specific timezone. Output from my machine:

```shell
~ ls -ltr /etc/
lrwxr-xr-x   1 root  wheel             35 Jan  8 17:52 localtime -> /usr/share/zoneinfo/America/Chicago
```

Inside our VM, all we have to do is fix localtime file to point to correct timezone. If the file is present but not a symbolic link, then go ahead & remove the file.

```shell
~ rm /etc/localtime
```

Next re-create the file with correct symbolic link.

```shell
~ ln -sfn /usr/share/zoneinfo/US/Central localtime
```

Thats it. Running date command should return correct value now.

```shell
~ date
Thu Feb 02 21:56:39 CST 2017
```

Thanks.