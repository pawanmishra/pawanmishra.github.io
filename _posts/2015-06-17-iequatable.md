---
title: IEquatable Interface
tags: [C#]
---
Consider the following generic method :

```csharp
public static bool AreEqual<T>(T instance1, T instance2)
{
    return instance1.Equals(instance2);
}
```

If we invoke the above method using following statement and look at the generated IL code

```csharp
Console.WriteLine(AreEqual<int>(5,5));

IL Code

AreEqual:
IL_0000:  nop         
IL_0001:  ldarga.s    00 
IL_0003:  ldarg.1     
IL_0004:  box         01 00 00 1B 
IL_0009:  constrained. 01 00 00 1B 
IL_000F:  callvirt    System.Object.Equals
IL_0014:  stloc.0     // CS$1$0000
IL_0015:  br.s        IL_0017
IL_0017:  ldloc.0     // CS$1$0000
IL_0018:  ret  
```

In the IL code we can see that the call to method equal is getting redirected to Object’s equals method and the input parameters are getting boxed. Imagine if this method is getting invoked for multiple value types and the kind of negative performance impact it have on application performance because of the “box” operation.

In order to avoid the boxing operation, we can add an explicit constraint on the type parameter wherein the parameter is of type [IEquatable<T>](https://msdn.microsoft.com/en-us/library/ms131187%28v=vs.110%29.aspx). What this constraint tells to the compiler is that, use the “[IEquatable<T>.equals](https://msdn.microsoft.com/en-us/library/ms131190%28v=vs.110%29.aspx)” method provided by this interface, instead of going all the way up to the Object class. So if we redefine our method by adding the constraint and invoke it once again with value type parameters, then we can see that there are no more box operation.

```csharp
public static bool AreEqual<T>(T instance1, T instance2) where T : IEquatable<T>
{
    return instance1.Equals(instance2);
}

Console.WriteLine(AreEqual<int>(5, 5));

AreEqual:
IL_0000:  nop         
IL_0001:  ldarga.s    00 
IL_0003:  ldarg.1     
IL_0004:  constrained. 02 00 00 1B 
IL_000A:  callvirt    12 00 00 0A 
IL_000F:  stloc.0     // CS$1$0000
IL_0010:  br.s        IL_0012
IL_0012:  ldloc.0     // CS$1$0000
IL_0013:  ret 
```

As we can see that by constraining the type parameter to be of type IEquatable, we have avoided the boxing operation. So does that mean generic collections like List<T>, HashSet<T> etc. too have IEquatable constraint on their type parameter? Answer is **No**. Constraining the type parameter to be of type IEquatable would severely limit their capabilities. Just ask yourself, how many times have you implemented IEquatable interface? In the case of generic collections, when it comes to the invocation of “[equals](https://msdn.microsoft.com/en-us/library/ms131190%28v=vs.110%29.aspx)” method, we have an abstraction layer in between implemented via [EqualityComparer<T>](https://msdn.microsoft.com/en-us/library/ms132151%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396). This abstraction layer decides whether to invoke IEquatable based equals method or to make use of the Object’s equals method.