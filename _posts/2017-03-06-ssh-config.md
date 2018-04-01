---
title: SSH Config
tags: [Programming]
---
{% include base_path %}

This post is for those(like me) who have to regularly use *ssh* or *scp* against remote servers & are used too of typing verbose ssh command.

> ssh -i .ssh/my_very_own.pem myuser@my-personal-domain-in-cloud

Luckily we can save lots of our time by making use of ssh config files & minimize the amount of effort required in typing the above command. All we have to do is create config file under *_.ssh_* directory & add the following lines:

```
Host mydomain
     HostName my-personal-domain-in-cloud
     User myuser
     IdentityFile ~/.ssh/my_very_own.pem
```

And thats it. Once the above configuration is in place then we can either ssh or scp by simply doing saying _ssh mydomain_ or _scp mydomain_.