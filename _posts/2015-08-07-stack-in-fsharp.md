---
layout: single
title: Going Functional - Stack Implementation in F#
tags: [F#, Algorithms]
---
In this blog post, I will port linked list based Stack ADT code in C# to F#. Given below is the C# implementation. It’s inspired from the Java based implementation provided in the [Algorithms 4th Edition](http://algs4.cs.princeton.edu/home/) book by Robert Sedgewick and Kevin Wayne. The Stack ADT class is called LLStack because .Net framework itself contains Stack data structure.

```java
public class LLStack<T>                         // Generic Class
{
    private Node first;
    private int N;                                 // Mutable Field

    private class Node                             // Inner Class
    {
        public T value { get; set; }               // Getter, Setter Properties
        public Node next { get; set; }
    }

    public bool IsEmpty { get { return first == null; }} 
    public int Size { get { return N; }}

    public void Push(T item) 
    {
        Node oldFirst = first;
        first = new Node();        
        first.value = item;
        first.next = oldFirst;
        N++;
    }

    public T Pop()
    {
        T value = first.value;
        first = first.next;
        N--;
        return value;
    }

    public override string ToString()
    {
        Node temp = first;
        while(temp != null)
        {
            Console.Write(temp.value + " ");
            temp = temp.next;
        }
        Console.WriteLine();
        return "End";
    }
}
```

I have annotated some lines with text which describes the functionality of that code snippet. While implementing F# code, we will learn on how to implement the same functionality in F#.

Next I will present the complete F# code. Later in the blog post, I will break down the F# code and I will try to explain the implemented concepts.

```
type Node<'T> = { Value : 'T; Next : Node<'T> option }         // 1

type LLStack<'T>() =
    inherit System.Object()                                 // 2

    let mutable First : Node<'T> option = None                 // 3
    let mutable N = 0

    member x.Push item =
        let oldFirst = First
        First <- Some { Value = item; Next = oldFirst }     // 4
        N <- N + 1
        () 

    member x.Pop() =
        match First with                                     // 5
        | Some x -> 
            First <- x.Next
            N <- N - 1
            ()
        | None -> ()

    member x.IsEmpty                                         // 6
        with get() = match First with
                     | Some _ -> false
                     | None -> true

    member x.Size with get() = N

    override x.ToString() =
        let oldFirst = First
        let rec Print (node: Node<'T> option) =                // 7
            match node with
            | Some x -> 
                printf "%A " x.Value
                Print x.Next
                ()
            | None -> ()
        Print oldFirst                                         // 8
        base.ToString()
```

If you are thinking that F# code is too complex even to look at then I agree with you. But F# code complexity comes due to one big reason which is not present/handled in the C# code which is handling of NULL values. For e.g. consider the following code snippet:

```
let st = LLStack<int>()
st.Pop()
st.Push(1)
st.Push(2)
st.Push(3)
st.Push(4)
st.ToString() |> ignore
st.Pop()
st.ToString() |> ignore
printf "%A " st.IsEmpty
```

After creating the LLStack instance, I have invoked the Pop() method. In case of F# the code runs fine without throwing any error whereas in C# the code breaks with “NullReferenceException” error.

Also in the F# code, I have annotated some of the code lines with numbers. Next I will explain for each number what that line actually does.

1.  Line 1 could be a blog post in itself. In Line-1 what we have declared is called [Record Type](https://msdn.microsoft.com/en-us/library/dd233184.aspx?f=255&MSPPError=-2147217396). Records are like class but usually kept limited to just field declarations. In our case, we have used it to represent the Node class. Also notice that the Node record type is declared as [generic](https://msdn.microsoft.com/en-us/library/dd233215.aspx). Almost all of the rules of C# generics applies and works the same as in F#. Another very important construct used in Record type declaration is the [option](https://msdn.microsoft.com/en-us/library/dd233245.aspx) keyword. Options are F# way of handling null values. For e.g. a node’s Next value will either point to some other node or will be null. I request you to read more about options in F# msdn page.
2.  Explicitly inheriting from Object() class seems strange. Agree. But if you look into the ToString() method, I have invoked the base.ToString() method. In F# “base” keyword is only available when the class is explicitly derived from some other class i.e. in our case Object() class. Strangeness++.
3.  Same as C#, I have created the “First” local instance variable. By default in C# reference type are initialized to NULL. In F# since “First” is marked as [option](https://msdn.microsoft.com/en-us/library/dd233245.aspx) type, we will have to explicitly set its default value to “None”. Also notice that I have marked this field as “mutable”. In F# everything is immutable by default. Since we are going to manipulate the “First” node many times, we will have to tell the compiler that it’s a mutable field by marking it as mutable.
4.  In this line, I am creating an instance of Node record type. If you have gone through the F# [record type](https://msdn.microsoft.com/en-us/library/dd233184.aspx?f=255&MSPPError=-2147217396) and [option](https://msdn.microsoft.com/en-us/library/dd233245.aspx) tutorial, then you will easily understand what's going on here.
5.  What we see in here is called [pattern matching](https://msdn.microsoft.com/en-us/library/dd547125.aspx). If you are new to F#, then this concept alone is good enough to win all your love for the language. Kindly go through the msdn tutorial to know more about pattern matching. Also what we have declared over here is an F# method. Notice how the method is prefixed with “x” qualifier. In F#, this keyword can be accessed with any literal like “x”, “y”etc.
6.  Same as point 5, I have used pattern matching inside a property.
7.  Here instead of using regular looping constructs like for, while etc. I have used F#’s way of implementing recursive methods. In F#, recursive methods are marked with rec keyword. Inside the method, I have used pattern matching on the input value. If its None I return void otherwise known as unit in F#(represented as ()) else I call the same function with next node in the list.
8.  After declaring the recursive method, over here I am invoking the method by passing relevant input parameters.

This post had lots of theory but in later posts we will mostly see code snippets of various data structures and algorithms.