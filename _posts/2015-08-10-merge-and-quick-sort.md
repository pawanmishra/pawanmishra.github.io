---
layout: single
title: Going Functional - Merge & Quick Sort in F#
---
Continuing our functional journey, in this post I will first present the Java based implementation of merge sort followed by F# based implementation. Finally we will repeat the same steps for QuickSort algorithm. Java based implementation of the sorting algorithms is taken from [Algorithms 4th Edition](http://algs4.cs.princeton.edu/home/) by **Robert Sedgewick** and **Kevin Wayne**.

### Merge Sort

Following is the Java based implementation of **MergeSort**, which uses an auxiliary array for maintaining intermediate values.

```java
// stably merge a[lo .. mid] with a[mid+1 ..hi] using aux[lo .. hi]  
private static void merge(Comparable[] a, Comparable[] aux, int lo, int mid, int hi) {  

    // copy to aux[]  
    for (int k = lo; k <= hi; k++) {  
        aux[k] = a[k];   
    }  

    // merge back to a[]  
    int i = lo, j = mid+1;  

    for (int k = lo; k <= hi; k++) {  
        if      (i > mid)              a[k] = aux[j++];  
        else if (j > hi)               a[k] = aux[i++];  
        else if (less(aux[j], aux[i])) a[k] = aux[j++];  
        else                           a[k] = aux[i++];  
    }  
}  

// mergesort a[lo..hi] using auxiliary array aux[lo..hi]  
private static void sort(Comparable[] a, Comparable[] aux, int lo, int hi) {  
    if (hi <= lo) return;  
    int mid = lo + (hi - lo) / 2;  
    sort(a, aux, lo, mid);  
    sort(a, aux, mid + 1, hi);  
    merge(a, aux, lo, mid, hi);  
}
```

Next is the F# implementation. The F# implementation replicates exactly the same pattern and codebase as we see in the above code.

```
let private Merge (data: int array) (aux : int array) low mid high =  
    let mutable i = low  
    let mutable j = mid + 1  
    for k in low..high do aux.[k] <- data.[k]  
    for k in [low..high] do  
        data.[k] <- match k with  
                    | _ when (i > mid) -> j <- j + 1; aux.[j - 1]  
                    | _ when j > high -> i <- i + 1; aux.[i - 1]  
                    | _ when aux.[j] < aux.[i] -> j <- j + 1; aux.[j - 1];   
                    | _ -> i <- i + 1; aux.[i - 1];   
let rec private Sort (data: int array) (aux : int array) low high =  
    match low, high with   
    | _,_ when high <= low -> ()  
    | _ ->   
        let mid = low + (high - low) / 2  
        Sort data aux low mid  
        Sort data aux (mid+1) high  
        Merge data aux low mid high  
        ()  
let MergeSort (data: int array) (aux : int array) low high =  
    Sort data aux low high  
    printfn "%A" data
```

Notice how [pattern matching](https://msdn.microsoft.com/en-us/library/dd547125.aspx) has been used instead of iterative for and while loop. General advise when programming in F# is to try and avoid for and while loop and instead try and focus on pattern matching along with recursive functions.One more thing to note in the “**Merge**” method is how the return value of the pattern matching expression is assigned to the “**data**” array index element. This highlights the power of F# wherein if-else block, pattern matching block are expressions which return values.

### Quick Sort

Next lets move on to the implementation of **Quicksort** algorithm. First the Java based implementation.

```java
// quicksort the subarray from a[lo] to a[hi]  
private static void sort(Comparable[] a, int lo, int hi) {   
    if (hi <= lo) return;  
    int j = partition(a, lo, hi);  
    sort(a, lo, j-1);  
    sort(a, j+1, hi);  
}  
// partition the subarray a[lo..hi] so that a[lo..j-1] <= a[j] <= a[j+1..hi]  
// and return the index j.  
private static int partition(Comparable[] a, int lo, int hi) {  
    int i = lo;  
    int j = hi + 1;  
    Comparable v = a[lo];  
    while (true) {   

        // find item on lo to swap  
        while (less(a[++i], v))  
            if (i == hi) break;  

        // find item on hi to swap  
        while (less(v, a[--j]))  
            if (j == lo) break;      // redundant since a[lo] acts as sentinel  

        // check if pointers cross  
        if (i >= j) break;  

        exch(a, i, j);  
    }  

    // put partitioning item v at a[j]  
    exch(a, lo, j);  

    // now, a[lo .. j-1] <= a[j] <= a[j+1 .. hi]  
    return j;  
}
```

Unlike F#’s Mergesort algorithm, the Quicksort algorithm implementation turned out to be a bit more complicated.

```
let private Partition (data: int array) low high =  
    let mutable i = low  
    let mutable j = high + 1  
    let pivot = data.[low]  
    let less x y = x <= y  
    let exchange x y =   
        let temp = data.[x];   
        data.[x] <- data.[y];   
        data.[y] <- temp;   
        y  
    let rec proc_i s =  
                match s+1 with  
                | x when less data.[x] pivot && x <> high -> proc_i x;  
                | _ -> s+1   
    let rec proc_j t =  
                match t-1 with  
                | x when less pivot data.[x] && x <> low -> proc_j x;   
                | _ -> t-1  
    let rec partition_data s t =  
         match (proc_i s), (proc_j t) with  
            | x , y when x >= y -> y  
            | x , y -> exchange x y |> partition_data x   
    j <- partition_data i j  
    exchange low j  
let rec private Sort (data: int array) low high =  
    match low, high with  
    | _ , _ when high <= low -> ()  
    | _ ->   
        let j = Partition data low high  
        Sort data low (j - 1)  
        Sort data (j + 1) high  
        ()  
let QuickSort (data: int array) low high =  
    Sort data low high  
    printfn "%A" data
```

The structure of the above code is very much similar to what we have in Java based implementation. Its just that I have strictly tried to avoid **while** & **for** loop. In the partition method, the proc_I & proc_j recursive methods identify the I & j index values wherein the values have to be swapped. Note how inside the **Partition** method, I have declared helper functions like **less, exchange, proc_i , proc_j and partition_data**. If you found the above implementation complicated, then I will agree with you. I am still trying to learn F# language and I am very much sure that anyone who holds a better command on the language can write the above code in much simpler manner. If you are one of them, then I request you to please leave your comments.

Thanks.