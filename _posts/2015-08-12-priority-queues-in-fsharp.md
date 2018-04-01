---
title: Going Functional - Priority Queues F#
tags: [F#, Algorithms]
---
In this blog post, I will provide the F# implementation for max priority queue. First the java based implementation taken from [Algorithms 4th Edition](http://algs4.cs.princeton.edu/home/) by Robert Sedgewick and Kevin Wayne. You can find the complete priority queue implementation here : [http://algs4.cs.princeton.edu/24pq/MaxPQ.java.html](http://algs4.cs.princeton.edu/24pq/MaxPQ.java.html "http://algs4.cs.princeton.edu/24pq/MaxPQ.java.html")

### Priority Queue

```java
public class MaxPQ <key>implements Iterable <key>{  
    private Key[] pq;                    // store items at indices 1 to N  
    private int N;                       // number of items on priority queue  
    private Comparator <key>comparator;  // optional Comparator  

    public MaxPQ(int initCapacity) {  
        pq = (Key[]) new Object[initCapacity + 1];  
        N = 0;  
    }  

    public boolean isEmpty() {  
        return N == 0;  
    }  

    public int size() {  
        return N;  
    }  

    public Key max() {  
        if (isEmpty()) throw new NoSuchElementException("Priority queue underflow");  
        return pq[1];  
    }  

    public void insert(Key x) {  
        pq[++N] = x;  
        swim(N);  
    }  

    public Key delMax() {  
        Key max = pq[1];  
        exch(1, N--);  
        sink(1);  
        pq[N+1] = null;    
        return max;  
    }  

    private void swim(int k) {  
        while (k > 1 && less(k/2, k)) {  
            exch(k, k/2);  
            k = k/2;  
        }  
    }  

    private void sink(int k) {  
        while (2*k <= N) {  
            int j = 2*k;  
            if (j < N && less(j, j+1)) j++;  
            if (!less(k, j)) break;  
            exch(k, j);  
            k = j;  
        }  
    }  

    private boolean less(int i, int j) {  
        if (comparator == null) {  
            return ((Comparable<key>) pq[i]).compareTo(pq[j]) < 0;  
        }  
        else {  
            return comparator.compare(pq[i], pq[j]) < 0;  
        }  
    }  

    private void exch(int i, int j) {  
        Key swap = pq[i];  
        pq[i] = pq[j];  
        pq[j] = swap;  
    }  
}
```

Java based implementation is fairly straight forward. The crux of the code lies in the **Swim** & **Sink** method. Lets take a look at the F# based implementation :

```
module PriorityQueue  

type PriorityQueue<'T when 'T :> System.IComparable<'T>> (maxN : int) =  
    let pq : 'T array = Array.zeroCreate (maxN + 1)  
    let mutable N = 0  

    let Less i j = pq.[i].CompareTo(pq.[j]) < 0  
    let Exchange i j =   
        let temp = pq.[i]  
        pq.[i] <- pq.[j]  
        pq.[j] <- temp  
        i  

    let rec Swim k =  
        match (k > 1 && Less (k/2) k) with  
        | true -> Exchange (k/2) k |> Swim;  
        | false -> ()  

    let rec Sink k =  
        match 2*k <= N, 2*k with  
        | true, j when j < N && Less j (j + 1) -> match Less k (j+1), j+1 with  
                                                    | true, x -> Exchange k x |> ignore; Sink x;  
                                                    | false, _ -> ()  
        | true, j -> Exchange k j |> ignore; Sink j;  
        | false, _ -> ()  

    member x.IsEmpty with get() = N = 0  
    member x.Size with get() = N  

    member x.Insert (item:'T) = N <- N + 1; pq.[N] <- item; Swim N;  

    member x.DelMax() =  
        let max = pq.[1]  
        Exchange 1 N |> ignore  
        N <- N - 1  
        pq.[N+1] <- Unchecked.defaultof<'T>  
        Sink 1  
        max  
```

Lets break down the above code and try to understand the individual pieces:

*   In the beginning I have declared a [module](https://msdn.microsoft.com/en-us/library/dd233221.aspx). Modules are like namespaces with a constraint that their definition cannot span to multiple files. Modules can be used to logically group functionality within a file.
*   Next I have declared a [generic](https://msdn.microsoft.com/en-us/library/dd233215.aspx) class with constraint on the type parameter. Also note that, just after the class definition I have declared what is called as [primary constructor](https://msdn.microsoft.com/en-us/library/dd233192.aspx) in F#.
*   After the class definition, we have multiple “let” statements. All of those let statements are either doing some sort of initialization or are used for declaring internal helper functions. “**let**” based functions aren’t exposed outside the type definition.
*   Followed by the “let” based declarations, we see [member](https://msdn.microsoft.com/en-us/library/dd233244.aspx) definitions which are nothing but methods in F#. Within the various member definitions, **IsEmpty** & **Size** are basically read-only properties. Once again we are seeing the power of F#’s [pattern matching](https://msdn.microsoft.com/en-us/library/dd547125.aspx) & overall succinctness in play here.

In next blog post, we will move on to Graphs.

Thanks.