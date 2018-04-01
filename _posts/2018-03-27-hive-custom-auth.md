---
title: Hive - How to easily test custom auth Jar?
tags: [Hive]
excerpt: In this post, I will share the steps you can take to easily test your custom hive authentication implementation.
---

In this post, I will share the steps you can take to easily test your custom hive authentication implementation. Say you have hive configured to run in cluster in your organization & you want to test your custom hive authentication implementation then you can do it by following the steps given below:

#### Steps
---

* Assuming the custom hive authentication jar is named : *custom-hive-auth.jar*
* Copy the jar into _/usr/lib/hive/auxlib/_ directory in the server
* Stop the hive-server2 service : *sudo stop hive-server2*
* Add the following section in hive-site.xml file available under : _/usr/lib/hive/conf/hive-site.xml_:

```xml
<property>
    <name>hive.server2.authentication</name>
    <value>LDAP</value>
</property>
<property>
    <name>hive.server2.custom.authentication.class</name>
    <value><full path of the class> e.g. com.foo.bar.hive.MyCustomAuthenticator</value>
</property>
```  
* Start the hive-server2 service : *sudo start hive-server2 &*

These changes will replace the default hive authentication with your custom hive authentication implementation. 

