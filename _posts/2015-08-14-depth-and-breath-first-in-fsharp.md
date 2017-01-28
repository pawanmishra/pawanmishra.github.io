---
layout: splash
title: Going Functional - Breadth & Depth First Search in F#
tags: [F#, Algorithms]
---
In this blog post, I will provide the depth and breadth first traversal implementation in F#. But before that lets look at the Java based implementation of these traversal mechanisms. The code is taken from [Algorithms 4th Edition](http://algs4.cs.princeton.edu/home/) by Robert Sedgewick and Kevin Wayne. You can find the complete code here : [http://algs4.cs.princeton.edu/40graphs/](http://algs4.cs.princeton.edu/40graphs/ "http://algs4.cs.princeton.edu/40graphs/") 

### Graph.java

```java
public class Graph {  
    private final int V;  
    private int E;  
    private Bag<integer>[] adj;  

    public Graph(int V) {  
        if (V < 0) throw new IllegalArgumentException("Number of vertices must be nonnegative");  
        this.V = V;  
        this.E = 0;  
        adj = (Bag<integer>[]) new Bag[V];  
        for (int v = 0; v < V; v++) {  
            adj[v] = new Bag<integer>();  
        }  
    }  

    public Graph(In in) {  
        this(in.readInt());  
        int E = in.readInt();  
        if (E < 0) throw new IllegalArgumentException("Number of edges must be nonnegative");  
        for (int i = 0; i < E; i++) {  
            int v = in.readInt();  
            int w = in.readInt();  
            addEdge(v, w);  
        }  
    }  

    public int V() {  
        return V;  
    }  

    public int E() {  
        return E;  
    }  

    public void addEdge(int v, int w) {  
        E++;  
        adj[v].add(w);  
        adj[w].add(v);  
    }  

    public Iterable <integer>adj(int v) {  
        return adj[v];  
    }  

    public int degree(int v) {  
        return adj[v].size();  
    }  
}
```

### DepthFirstPaths

```java
public class DepthFirstPaths {  
    private boolean[] marked;  
    private int[] edgeTo;  
    private final int s;  

    public DepthFirstPaths(Graph G, int s) {  
        this.s = s;  
        edgeTo = new int[G.V()];  
        marked = new boolean[G.V()];  
        dfs(G, s);  
    }  

    // depth first search from v  
    private void dfs(Graph G, int v) {  
        marked[v] = true;  
        for (int w : G.adj(v)) {  
            if (!marked[w]) {  
                edgeTo[w] = v;  
                dfs(G, w);  
            }  
        }  
    }  

    public boolean hasPathTo(int v) {  
        return marked[v];  
    }  

    public Iterable <integer>pathTo(int v) {  
        if (!hasPathTo(v)) return null;  
        Stack <integer>path = new Stack<integer>();  
        for (int x = v; x != s; x = edgeTo[x])  
            path.push(x);  
        path.push(s);  
        return path;  
    }  
}
```

### BreadthFirstPath

```java
public class BreadthFirstPaths {  
    private boolean[] marked;  
    private int[] edgeTo;  

    public BreadthFirstPaths(Graph G, int s) {  
        marked = new boolean[G.V()];  
        edgeTo = new int[G.V()];  
        bfs(G, s);  
    }  

    // breadth-first search from a single source  
    private void bfs(Graph G, int s) {  
        Queue <integer>q = new Queue<integer>();  
        for (int v = 0; v < G.V(); v++)  
            distTo[v] = INFINITY;  
        marked[s] = true;  
        q.enqueue(s);  

        while (!q.isEmpty()) {  
            int v = q.dequeue();  
            for (int w : G.adj(v)) {  
                if (!marked[w]) {  
                    edgeTo[w] = v;  
                    marked[w] = true;  
                    q.enqueue(w);  
                }  
            }  
        }  
    }  

    public boolean hasPathTo(int v) {  
        return marked[v];  
    }  

    public Iterable <integer>pathTo(int v) {  
        if (!hasPathTo(v)) return null;  
        Stack <integer>path = new Stack<integer>();  
        int x;  
        for (x = v; distTo[x] != 0; x = edgeTo[x])  
            path.push(x);  
        path.push(x);  
        return path;  
    }  
}
```

The code for BreadthFirst & DepthFirst traversal technique is fairly straight forward. In the below mentioned F# implementation, I have combined these two implementation in one single file.

```
module Graph  

open System  
open System.IO  

type Graph (v : int) =  
    let V = v  
    let mutable E = 0  
    let Adj : int list array = Array.zeroCreate V  
    do Adj |> Array.iteri (fun i x -> Adj.[i] <- [])  
    new(reader : TextReader) = Graph(Int32.Parse(reader.ReadLine()))  

    member x.Vertices with get() = V  
    member x.Edge with get() = E  
    member x.Adjecent v = Adj.[v]  
    member x.AddEdge (v, w) =   
        Adj.[v] <- w::Adj.[v]  
        Adj.[w] <- v::Adj.[w]  
        E <- E + 1  

    member x.AddEdge (reader: TextReader) =   
        let tempEdge = Int32.Parse(reader.ReadLine())  
        for i in [0..tempEdge-1] do  
            let items = reader.ReadLine().Split(' ') |> Array.map (fun x -> Int32.Parse(x))   
            x.AddEdge (items.[0], items.[1])  

[<AbstractClass><abstractclass>]  
type Path (graph : Graph, source : int) =  
    let HasPath (v, (marked:bool array)) = marked.[v]  
    member x.PathTo (v, (edgeTo:int array), (marked:bool array)) :int list option =  
        match HasPath (v, marked) with  
        | false -> None  
        | true ->   
            let rec ComputePath v items =  
                match v with  
                | x when x <> source -> ComputePath edgeTo.[x] (x::items)  
                | s when s = source -> s::items  
                | _ -> items  
            ComputePath v [] |> Some  

type DepthFirstPath (graph : Graph, source : int) =  
    inherit Path(graph, source)  
    let marked : bool array = Array.zeroCreate graph.Vertices  
    let edgeTo : int array = Array.zeroCreate graph.Vertices  
    let rec DFS (graph:Graph, v:int) =  
        marked.[v] <- true  
        graph.Adjecent v |> List.iter (fun x -> match marked.[x] with  
                                                   | false ->  edgeTo.[x] <- v; DFS(graph, x);   
                                                   | _ -> ())   
    do DFS(graph, source)  
    member x.Path (v:int) :int list option = base.PathTo (v, edgeTo, marked)  

type BreadthFirstPath (graph : Graph, source : int) =  
    inherit Path(graph, source)  
    let marked : bool array = Array.zeroCreate graph.Vertices  
    let edgeTo : int array = Array.zeroCreate graph.Vertices  
    let BFS (graph:Graph, v:int) =  
        marked.[v] <- true  
        let rec Traverse (data:int list) =  
            match data with  
            | [] -> ()  
            | hd::tl ->   
                let tempLst = graph.Adjecent hd |> List.filter (fun i -> not marked.[i]) |> List.map (fun x -> edgeTo.[x] <- hd; marked.[x] <- true; x;)  
                Traverse (tl@tempLst) |> ignore  
        Traverse [v]  
    do BFS(graph, source)  
    member x.Path (v:int) :int list option = base.PathTo (v, edgeTo, marked)  

let ConstructGraph (path:string) =  
    use reader = new StreamReader(path)  
    let graph = Graph(reader)  
    graph.AddEdge reader  
    let dfp = DepthFirstPath(graph, 0)  
    let path = dfp.Path(3)  
    printfn "DFS %A" path.Value  

    let bfs = BreadthFirstPath(graph, 0)  
    let bfsPath = bfs.Path(3)  
    printfn "BFS : %A" path.Value
```

Lets break down the implementation and see what all new constructs have been used in the above code.

*   First we have declared the Graph type. Note that in the Graph type, we have declared secondary constructor using **new(reader:TextReader).** To know more about types and constructors in F#, please read here : [https://msdn.microsoft.com/en-us/library/dd233230.aspx](https://msdn.microsoft.com/en-us/library/dd233230.aspx "https://msdn.microsoft.com/en-us/library/dd233230.aspx") & [https://msdn.microsoft.com/en-us/library/dd233192.aspx](https://msdn.microsoft.com/en-us/library/dd233192.aspx "https://msdn.microsoft.com/en-us/library/dd233192.aspx"). Graph type has few properties and methods used for adding new edges.
*   Next we have declared an abstract base class for Depth & Breadth first types. Note that for declaring abstract type, the type definition has to be attributed with “**AbstractClass**” attribute. Rest of the code for abstract class is fairly simple.
*   Next in the Depth & Breadth first types, I have inherited from the base type i.e. **Path.** For traversal, I have once again made use of F#’s recursion & [pattern matching](https://msdn.microsoft.com/en-us/library/dd547125.aspx) technique. In the BreadthFirstPath type, I have also made use of pattern matching technique on list type. To know more about pattern matching in lists please read here : [https://msdn.microsoft.com/en-us/library/dd547125.aspx](https://msdn.microsoft.com/en-us/library/dd547125.aspx "https://msdn.microsoft.com/en-us/library/dd547125.aspx")
*   Finally in the ConstructGraph method, I am first creating the StreamReader instance. Note carefully that instead of “**let**” keyword, I have used “**use**” this time. In F# “use” keyword is used to designate those instances which implement the “**IDisposable**” interface. Also while creating instances, “**new**” keyword is generally not required(e.g. see **DepthFirstPath** & **BreadthFirstPath** instantiation in **ConstructGraph** method). But in case when the type implements “**IDisposable**” interface, then “**new**” keyword is mandatory.