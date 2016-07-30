---
layout: single
title: Going Functional - Elementry Sorting Algorithms in F#
tags: [F#, Algorithms]
---
In this blog post, I will provide F# implementation for Selection & Insertion sorting algorithms. First the C#/Java based implementation of these algorithms taken from [Algorithms 4th Edition](http://algs4.cs.princeton.edu/home/) by Robert Sedgewick & Kevin Wayne.

```java
public static void selection_sort(Comparable[] a) {
    int N = a.length;
    for (int i = 0; i < N; i++) {
        int min = i;
        for (int j = i+1; j < N; j++) {
            if (less(a[j], a[min])) min = j;
        }
        exch(a, i, min);
    }
}

public static void insertion_sort(Comparable[] a) {
    int N = a.length;
    for (int i = 0; i < N; i++) {
        for (int j = i; j > 0 && less(a[j], a[j-1]); j--) {
            exch(a, j, j-1);
        }
    }
}

private static boolean less(Comparable v, Comparable w) {
    return v.compareTo(w) < 0;
}

private static void exch(Object[] a, int i, int j) {
    Object swap = a[i];
    a[i] = a[j];
    a[j] = swap;
}
```

F# implementation of these iterative algorithms is very much similar. I haven’t made use of any functional construct like [pattern matching](https://msdn.microsoft.com/en-us/library/dd547125.aspx) etc. instead I have tried to keep the implementation very much similar to what is present above. F# implementation of these algorithms is present below:

```
let SelectionSort (data: int array) =
    let N = data.GetLength(0)
    for i in [0..N-1] do
        let mutable min = i
        for j in [i+1..N-1] do
            min <- if data.[j] < data.[min] then j else min
        let temp = data.[i]
        data.[i] <- data.[min]
        data.[min] <- temp
    data

let InsertionSort (data:int array) =
    let N = data.GetLength(0)
    for i in [1..N-1] do
        for j = i downto 1 do
            if data.[j] < data.[j - 1] then
                let temp = data.[j]
                data.[j] <- data.[j - 1]
                data.[j - 1] <- temp
    data

let data = [|2;20;1;11;3;5;7|]
let result = InsertionSort data
printfn "%A" result
```