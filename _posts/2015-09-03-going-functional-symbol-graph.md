---
layout: splash
title: Going Functional - Symbol Graph in F#
tags: [F#, Algorithms]
---
In the previous [post](https://weblogs.asp.net/pawanmishra/going-functional-depth-and-breadth-first-search-in-f), we have seen the implementation of undirected graph data structure in F#. In this post, we will make use of the Graph data structure to implement the **Symbol Graph** data structure. You can read more about Symbol Graph data structure [here](http://algs4.cs.princeton.edu/41graph/). Given below is the java based implementation of Symbol Graph data structure. The implementation if taken from [Algorithms 4th Edition](http://algs4.cs.princeton.edu/home/) by Robert Sedgewick and Kevin Wayne.

```java
public class SymbolGraph {  
    private ST st;  // string -> index  
    private String[] keys;           // index  -> string  
    private Graph G;  

    public SymbolGraph(String filename, String delimiter) {  
        st = new ST<string integer="">();  

        In in = new In(filename);  
        // while (in.hasNextLine()) {  
        while (!in.isEmpty()) {  
            String[] a = in.readLine().split(delimiter);  
            for (int i = 0; i < a.length; i++) {  
                if (!st.contains(a[i]))  
                    st.put(a[i], st.size());  
            }  
        }  

        // inverted index to get string keys in an aray  
        keys = new String[st.size()];  
        for (String name : st.keys()) {  
            keys[st.get(name)] = name;  
        }  

        G = new Graph(st.size());  
        in = new In(filename);  
        while (in.hasNextLine()) {  
            String[] a = in.readLine().split(delimiter);  
            int v = st.get(a[0]);  
            for (int i = 1; i < a.length; i++) {  
                int w = st.get(a[i]);  
                G.addEdge(v, w);  
            }  
        }  
    }  

    public boolean contains(String s) {  
        return st.contains(s);  
    }  

    public int index(String s) {  
        return st.get(s);  
    }  

    public String name(int v) {  
        return keys[v];  
    }  

    public Graph G() {  
        return G;  
    }  
}
```

One of the common use of Symbol Graph data structure is in identifying the **Degree Of Separation** in nodes. For e.g. given a graph of movies & actors wherein movie names and actors are vertices and there are edges between movie name and all of the actors who have acted in the movie. You can read more about this here : [http://algs4.cs.princeton.edu/41graph/](http://algs4.cs.princeton.edu/41graph/ "http://algs4.cs.princeton.edu/41graph/"). Degree Of Separation is defined as given two nodes(say two actors), then if these two actors are connected then what is the degree of separation between them. Degree of separation uses Symbol graph data structure to answer this question. Given below is the Java based implementation of the code.

```java
public class DegreesOfSeparation {  

    // this class cannot be instantiated  
    private DegreesOfSeparation() { }  

    public static void main(String[] args) {  
        String filename  = args[0];  
        String delimiter = args[1];  
        String source    = args[2];  

        // StdOut.println("Source: " + source);  

        SymbolGraph sg = new SymbolGraph(filename, delimiter);  
        Graph G = sg.G();  
        if (!sg.contains(source)) {  
            StdOut.println(source + " not in database.");  
            return;  
        }  

        int s = sg.index(source);  
        BreadthFirstPaths bfs = new BreadthFirstPaths(G, s);  

        while (!StdIn.isEmpty()) {  
            String sink = StdIn.readLine();  
            if (sg.contains(sink)) {  
                int t = sg.index(sink);  
                if (bfs.hasPathTo(t)) {  
                    for (int v : bfs.pathTo(t)) {  
                        StdOut.println("   " + sg.name(v));  
                    }  
                }  
                else {  
                    StdOut.println("Not connected");  
                }  
            }  
            else {  
                StdOut.println("   Not in database.");  
            }  
        }  
    }  
}
```

Degree of separation uses Symbol Graph & BreadthFirstPath data structure. Next we will see the F# based implementation of the above two code snippets combined.

```scala
open Graph  

open System.IO  

type SymbolGraph (path:string, sep:char) =  
    let mutable map = Map.empty<string int="">  
    let mutable keys : string array = Array.zeroCreate map.Count  
    let mutable graph = new Graph(map.Count)  
    let rec tokenize (tempMap:Map<string int="">) (items:string list) =   
        match items with  
        | [] -> map <- tempMap  
        | hd::tl when map.ContainsKey hd -> tokenize tempMap tl  
        | hd::tl ->   
            let tmp = tempMap.Add(hd, tempMap.Count)  
            tokenize tmp tl  
    do    
        use txtReader = new StreamReader(path)  
        let rec initializeMap (tmpReader:TextReader) =   
            match tmpReader.Peek() >= 0 with  
            | false -> ()  
            | true ->   
                tmpReader.ReadLine().Split [|sep|] |> Array.toList |> tokenize map  
                initializeMap tmpReader  
        initializeMap txtReader |> ignore  
        keys <- Array.zeroCreate map.Count  
        map |> Map.iter (fun x y -> keys.[map.[x]] <- x)  
        graph <- new Graph(map.Count)  
        use reader = new StreamReader(path)  
        let rec createGraph (tempMap:Map<string int="">) (reader:TextReader) =  
            match reader.Peek() >= 0 with  
            | false -> ()  
            | true ->   
                let items = reader.ReadLine().Split [|sep|]  
                let vertex = tempMap.[items.[0]]  
                for i in [1..items.Length-1] do  
                    let v = tempMap.[items.[i]]  
                    graph.AddEdge(vertex, v)  
        createGraph map reader |> ignore  

    member x.Graph with get() = graph  
    member x.Contains (s:string) = map.ContainsKey s  
    member x.Index (s:string) = map.Item s  
    member x.Name (v:int) = keys.[v]  

let DegreeOfSeparation =  
    let sg = SymbolGraph("..\Dev\FSharp\DataStructure\DataStructure\movies.csv", '/')  
    let graph = sg.Graph  
    let index = sg.Index "Gray, Ian (I)"  
    let bfs = BreadthFirstPath(sg.Graph, index)  
    let target = sg.Index "Thompson, Jack (I)"  
    let printPath =  
        match bfs.Path(target) with  
        | None -> printfn "Not connected"  
        | Some v ->   
            for i in v do  
                printfn "    %A" (sg.Name i)  
    printPath |> ignore
```

Lets break down the F# code snippet and try to understand the various functional concepts used in the above code.

> type SymbolGraph (path:string, sep:char)

The above line declares a class called SymbolGraph whose [primary constructor](https://msdn.microsoft.com/en-us/library/dd233192.aspx) takes two parameters are input namely : path of the file and the separator.

```
let mutable map = Map.empty<string, int>
let mutable keys : string array = Array.zeroCreate map.Count
let mutable graph = new Graph(map.Count)
```

Next we have declared three mutable data structures. Their usage will be self-explanatory based on their usage in the remaining code.

```
let rec tokenize (tempMap:Map<string int="">) (items:string list) =   
        match items with  
        | [] -> map <- tempMap  
        | hd::tl when map.ContainsKey hd -> tokenize tempMap tl  
        | hd::tl ->   
            let tmp = tempMap.Add(hd, tempMap.Count)  
            tokenize tmp tl
```

Tokenize is a helper function which takes as input a string with records separated by separator and then breaks it down and stores in in key-value pair format in map data structure. In F# by default list, dictionary data structures are immutable i.e. if in a collection any value is added or removed, then internally F# creates a new collection. That’s why in the above code, every time I am adding a new value, I am storing the returned collection in temporary variable and passing it back as input parameter to the function. Once I am done processing the record, I am assigning  temporary collection back to our main **map** data structure.

```
use txtReader = new StreamReader(path)  
        let rec initializeMap (tmpReader:TextReader) =   
            match tmpReader.Peek() >= 0 with  
            | false -> ()  
            | true ->   
                tmpReader.ReadLine().Split [|sep|] |> Array.toList |> tokenize map  
                initializeMap tmpReader  
        initializeMap txtReader |> ignore  
        keys <- Array.zeroCreate map.Count  
        map |> Map.iter (fun x y -> keys.[map.[x]] <- x)  
        graph <- new Graph(map.Count)  
        use reader = new StreamReader(path)  
        let rec createGraph (tempMap:Map<string int="">) (reader:TextReader) =  
            match reader.Peek() >= 0 with  
            | false -> ()  
            | true ->   
                let items = reader.ReadLine().Split [|sep|]  
                let vertex = tempMap.[items.[0]]  
                for i in [1..items.Length-1] do  
                    let v = tempMap.[items.[i]]  
                    graph.AddEdge(vertex, v)  
        createGraph map reader |> ignore
```

In the above code, we are first creating a **StreamReader** instance for reading lines from the file. Next we have defined a recursive function **initializeMap,** which read a line from file and call the tokenize function on that line. Using the map data structure, I have initialized the **keys**  data structure. Next create a graph instance and then using the map data structure, I am initializing the graph.

```
let DegreeOfSeparation =  
    let sg = SymbolGraph("..\Dev\FSharp\DataStructure\DataStructure\movies_new.csv", '/')  
    let graph = sg.Graph  
    let index = sg.Index "Gray, Ian (I)"  
    let bfs = BreadthFirstPath(sg.Graph, index)  
    let target = sg.Index "Thompson, Jack (I)"  
    let printPath =  
        match bfs.Path(target) with  
        | None -> printfn "Not connected"  
        | Some v ->   
            for i in v do  
                printfn "    %A" (sg.Name i)  
    printPath |> ignore
```

Next is the **DegreeOfSeparation** code implementation. It uses the **SymbolGraph**  type and using the **BreadthFirstPath** traversal technique**,** print the path from source node to target node.  

Once again to know more about the Symbol Graph data structure and DegreeOfSeparation concept here : [http://algs4.cs.princeton.edu/41graph/](http://algs4.cs.princeton.edu/41graph/ "http://algs4.cs.princeton.edu/41graph/").