---
layout: single
title: Hive & Ldap Authentication
tags: [Hive]
excerpt: In this post, I will cover the steps required to properly configure Ldap & corresponding group level authentication in [hive](https://hive.apache.org/).
---
{% include base_path %}
{% include toc %}

In this post, I will cover the steps required to properly configure Ldap authentication & corresponding group level filtering in [hive](https://hive.apache.org/). I was recently trying to implement group level authentication & the information available on [hive](https://hive.apache.org/) [wiki](https://cwiki.apache.org/confluence/display/Hive/User+and+Group+Filter+Support+with+LDAP+Atn+Provider+in+HiveServer2) wasn't sufficient enough. Thats when I decided to clone the hive [repo](https://github.com/apache/hive/tree/master/service/src/java/org/apache/hive/service/auth/ldap) & go through the code myself. The information presented in this post is derived directly from the actual [hive](https://hive.apache.org/) codebase. 

Although there are multiple API's available for working with LDAP, [hive](https://hive.apache.org/) is using [JNDI](https://docs.oracle.com/javase/tutorial/jndi/ldap/jndi.html) Ldap api which comes bundled with the JDK. There is plenty of information available on internet on JNDI & corresponding Ldap api.

#### Basic Ldap Authentication
---

The very first thing we have to do in order to enable Ldap authentication in [hive](https://hive.apache.org/) is to set the *hive.server2.authentication* property in *hive-site.xml* to *LDAP*. 

```xml
<property>
    <name>hive.server2.authentication</name>
    <value>LDAP</value>
</property>
``` 

This is the bare-minimum amount of setting that is required to enable ldap authentication. This will allow users to authenticate themselves against the directory service via their AD account. Another helpful property that goes along with the previous property is *hive.server2.authentication.ldap.Domain". Setting this property allows users to skip the domain part when entering their usernames.

```xml
<property>
    <name>hive.server2.authentication.ldap.Domain</name>
    <value>amazing.com</value>
</property>
```

After we set _hive.server2.authentication_ to _LDAP_, internally [hive](https://hive.apache.org/) authenticates the provided credentials against AD server & uses it to create what is called _DirContext_. 

```java
private static DirContext createDirContext(HiveConf conf, String principal, String password)
      throws NamingException {
    Hashtable<String, Object> env = new Hashtable<String, Object>();
    String ldapUrl = conf.getVar(HiveConf.ConfVars.HIVE_SERVER2_PLAIN_LDAP_URL);
    env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
    env.put(Context.PROVIDER_URL, ldapUrl);
    env.put(Context.SECURITY_AUTHENTICATION, "simple");
    env.put(Context.SECURITY_CREDENTIALS, password);
    env.put(Context.SECURITY_PRINCIPAL, principal);
    LOG.debug("Connecting using principal {} to ldap url {}", principal, ldapUrl);
    return new InitialDirContext(env);
  }
```

_ldap_ url is controlled via hive-site property *hive.server2.authentication.ldap.url*. 

```xml
<property>
    <name>hive.server2.authentication.ldap.url</name>
    <value>ldaps://hello-world.amazing.com:636</value>
</property>
``` 

#### Group Filter
---

Ldap authentication along with group level restrictions is implemented as two step process in [hive](https://hive.apache.org/).

* Validate Ldap credentials & setup DirContext
* Apply filters

The first step is what we saw in previous section *Basic Authentication*. The first step determines whether the provided credentials are valid or not. If not then it throw *AuthenticationException*. 

If credentials are valid & group level filters are configured in _hive-site.xml_ then hive applies filters in following order:

```java
private static final List<FilterFactory> FILTER_FACTORIES = ImmutableList.<FilterFactory>of(
    new CustomQueryFilterFactory(),
    new ChainFilterFactory(new UserSearchFilterFactory(), new UserFilterFactory(),
        new GroupFilterFactory())
);

private static Filter resolveFilter(HiveConf conf) {
    for (FilterFactory filterProvider : FILTER_FACTORIES) {
        Filter filter = filterProvider.getInstance(conf);
        if (filter != null) {
        return filter;
        }
    }
    return null;
}

private void applyFilter(DirSearch client, String user) throws AuthenticationException {
    if (filter != null) {
        if (LdapUtils.hasDomain(user)) {
        filter.apply(client, LdapUtils.extractUserName(user));
        } else {
        filter.apply(client, user);
        }
    }
}
```

Filters are grouped into two categories : Custom filter and sequence of user search & group level filter. From the _resolveFilter_ code its clear that the first not-null filter is returned & it gets applied against the provided credentials. 

The nullability of individual filter is determined by the corresponding _hive-site.xml_ property setting. Following table describes the filters & the properties that enable/disable them.

|Filter|Property|
|----|----|
|CustomQueryFilter|hive.server2.authentication.ldap.customLDAPQuery|
|UserSearchFilter|hive.server2.authentication.ldap.groupFilter & hive.server2.authentication.ldap.userFilter|
|UserFilter|hive.server2.authentication.ldap.userFilter|
|GroupFilter|hive.server2.authentication.ldap.groupFilter & hive.server2.authentication.ldap.userMembershipKey|
 
##### CustomQueryFilter
---

Custom query filter is controlled via _hive.server2.authentication.ldap.customLDAPQuery_ property. [hive](https://hive.apache.org/) executes the query specified in the property & checks for the provided username within the returned resultset of the query. E.g.

```xml
<property>
  <name>hive.server2.authentication.ldap.customLDAPQuery</name>
  <value><![CDATA[(&(objectClass=person)(|(memberOf=CN=Domain Admins,CN=Users,DC=apache,DC=org)(memberOf=CN=Administrators,CN=Builtin,DC=apache,DC=org)))]]>
  </value>
</property>
```

Above query returns all users belonging to _Domain Admins_ or _Administrators_ group. Internally hive will search for entered username in the returned list of users. Custom query filter option is nice but it has downside of returning too many values which in-turn can negatively impact the search performance.

##### UserSearchFilter
---

_UserSearchFilter_ is controlled via _hive.server2.authentication.ldap.groupFilter_ & _hive.server2.authentication.ldap.userFilter_ properties. If either of these properties are defined then _UserSearchFilter_ will be applied. _UserSearchFilter_ tries to find the user's DN on the basis of values mentioned in _userFilter_ or _groupFilter_ and _hive.server2.authentication.ldap.userDNPattern_ property. Consider the following property definition:

```xml
<property>
    <name>hive.server2.authentication.ldap.userDNPattern</name>
    <value>sAMAccountname=%s,OU=Fax,OU=Users,DC=amazing,DC=com:sAMAccountname=%s,OU=Printer,OU=Users,DC=amazing,DC=com</value>
</property>
```

[hive](https://hive.apache.org/) uses _UserSearchFilter_ option to search for user's *DN* based on entered username. Username often maps to _sAMAccountName_ attribute in AD. In the above property definition, we have provided two DN patterns separated by colon. [hive](https://hive.apache.org/) will substitute _%s_ with provided username & it will attempt to find the user DN. This is not necessarily group level authentication but more like an additional layer of check before applying group filtering. Internally hive executes the following query against the base DN's mentioned in the property. In our case it's: *OU=Fax,OU=Users,DC=amazing,DC=com* & *OU=Printer,OU=Users,DC=amazing,DC=com*.

```sql
(&
    (|
        (objectClass=person)
        (objectClass=user)
        (objectClass=inetOrgPerson)
    )
    (|
        (uid=johndoe)
        (sAMAccountname=johndow)
    )
)
```

If it find more than one ldap name then it throws _AuthenticationException_ with message : _Expected exactly one user result for the user: {}, but got {}. Returning null_

##### UserFilter
---

_UserFilter_ is straight forward. After _UserSearchFilter_ has successfully found the user's DN, _UserFilter_ simply checks for provided usernames against the hard coded lists of user's provided in the _hive.server2.authentication.ldap.userFilter_ property. E.g.

```xml
<property>
  <name>hive.server2.authentication.ldap.userFilter</name>
  <value>johndoe,john,doe,jd</value>
</property>
```

Internally [hive](https://hive.apache.org/) creates a HashMap based on the list of users provided in the property & filters out any user that is not part of the list.

```scala
private final Set<String> userFilter = new HashSet<>();

UserFilter(Collection<String> userFilter) {
        for (String userFilterItem : userFilter) {
        this.userFilter.add(userFilterItem.toLowerCase());
    }
}

@Override
public void apply(DirSearch ldap, String user) throws AuthenticationException {
        LOG.info("Authenticating user '{}' using user filter", user);
        String userName = LdapUtils.extractUserName(user).toLowerCase();
        if (!userFilter.contains(userName)) {
        LOG.info("Authentication failed based on user membership");
        throw new AuthenticationException("Authentication failed: "
            + "User not a member of specified list");
    }
}
```

##### GroupFilter
---

First let's list down the various properties that comes into play when applying _GroupFilter_.

* hive.server2.authentication.ldap.userMembershipKey
* hive.server2.authentication.ldap.groupDNPattern
* hive.server2.authentication.ldap.groupFilter

_GroupFilter_ can be applied in two ways:

1) For a given user identify all the groups the user is part of. Often this information is available under _memberOf_ attribute within user's AD profile.
2) Given a group, identify all the users that are part of that group. Catch here is that a group can have other sub-groups. So in order to build a super list of all users, we will have to recursively iterate through all sub-groups. Within group level profile, list of users is available under _member_ attribute. 

If _hive.server2.authentication.ldap.userMembershipKey_ property is set then option 1 is used else option 2. E.g.

```xml
<property>
  <name>hive.server2.authentication.ldap.userMembershipKey</name>
  <value>memberOf</value>
</property>
```

Next, if our potential users are distributed across multiple groups then we can list those groups with the help of groupDNPattern & groupFilter property. E.g.

```xml
<property>
    <name>hive.server2.authentication.ldap.groupDNPattern</name>
    <value>OU=%s,OU=Users,DC=amazing,DC=com:OU=%s,OU=Users,DC=amazing,DC=com</value>
</property>
<property>
    <name>hive.server2.authentication.ldap.groupFilter</name>
    <value>Fax,Printer</value>
</property>
``` 

Hive internally substitutes _%s_ with group names listed in _groupFilter_ property & uses the substituted value for group filtering. 

When searching for groups belonging to a user, hive executes the following query:

```scala
public Query findGroupsForUser(String userName, String userDn) {
    return Query.builder()
        .filter("(&(objectClass=<groupClassAttr>)(|(<groupMembershipAttr>=<userDn>)"
            + "(<groupMembershipAttr>=<userName>)))")
        .map("groupClassAttr", groupClassAttr)
        .map("groupMembershipAttr", groupMembershipAttr)
        .map("userName", userName)
        .map("userDn", userDn)
        .build();
  }
```

**groupClassAttr** & **groupMembershipAttr** are controlled via hive-site.xml properties _hive.server2.authentication.ldap.groupClassKey_ & _hive.server2.authentication.ldap.groupMembershipKey_ respectively. You can set these properties to value of your choice in order to make the query work.

Similarly, hive executes the following code for determining if the user belongs to a particular grpoup or not?

```scala
public Query isUserMemberOfGroup(String userId, String groupDn) {
    Preconditions.checkState(!Strings.isNullOrEmpty(userMembershipAttr),
        "hive.server2.authentication.ldap.userMembershipKey is not configured.");
    return Query.builder()
        .filter("(&(|<classes:{ class |(objectClass=<class>)}>)" +
            "(<userMembershipAttr>=<groupDn>)(<guidAttr>=<userId>))")
        .map("classes", USER_OBJECT_CLASSES)
        .map("guidAttr", guidAttr)
        .map("userMembershipAttr", userMembershipAttr)
        .map("userId", userId)
        .map("groupDn", groupDn)
        .limit(2)
        .build();
  }
```

**guidAttr** & **userMembershipAttr** are controlled via _hive.server2.authentication.ldap.guidKey_ & _hive.server2.authentication.ldap.userMembershipKey_ properties respectively. Adjust these property values in order to make your queries work.

> If you are curious to know what query Hive is generating internally then you can set *property.hive.log.level* property to *DEBUG* in /usr/lib/hive/conf/hive-log4j2.properties. Remember to restart the hiver-server2 service. You can access the hive logs by going to url : <hostname>:10002.
> You can test the generated queries against AD server with the help of IDE's like [Apache Directory Studio](http://directory.apache.org/studio/)

#### Working Example
---

Below is the ldap related configuration from my hive-site.xml file.

```xml
<property>
    <name>hive.server2.authentication.ldap.groupDNPattern</name>
    <value>CN=%s,OU=Zooland,DC=amazing,DC=com</value>
</property>
<property>
    <name>hive.server2.authentication.ldap.groupFilter</name>
    <value>Fax,Printer</value>
</property>
<property>
  <name>hive.server2.authentication.ldap.userMembershipKey</name>
  <value>memberOf</value>
</property>
<property>
    <name>hive.server2.authentication.ldap.userDNPattern</name>
    <value>sAMAccountname=%s,OU=Zooland,OU=Accounts,DC=amazing,DC=com</value>
</property>
<property>
    <name>hive.server2.authentication.ldap.guidKey</name>
    <value>sAMAccountname</value>
</property>
<property>
    <name>hive.server2.authentication.ldap.groupClassKey</name>
    <value>group</value>
</property>
```

In the end, if you are wondering why ldap group level filtering is not working then just look into the code & tweak your hive-site.xml property values.













