---
layout: single
title: Laptop Inauguration
---
Today I received my new laptop which is an <a href="http://www.cpubenchmark.net/cpu.php?cpu=Intel+Core+i5-2450M+%40+2.50GHz">Intel Core i5-2450M @ 2.50GHz</a> 4 GB RAM machine . The other laptop(office provided) which I have used for past two years for programming is an <a href="http://www.cpubenchmark.net/cpu.php?cpu=Intel+Core2+Duo+T6570+%40+2.10GHz">Intel Core2 Duo T6570 @ 2.10GHz</a> machine. Reason why I am talking about the laptops that I own is because of my interest in writing multi-threaded/parallel code using the new TPL API provided in the .Net 4.0 framework.
I have spent significant amount of time in past one year writing code using the Parallel API of .Net framework. But given the fact that the hardware that I was using for running those applications wasn&rsquo;t that great, I was never much satisfied with the overall improvement in performance.

Today I decided to inaugurate my new laptop by running a heavy CPU intensive code and comparing its performance against my other laptop. I totally agree that its not a fair comparison but I am doing it as an experiment just to see how much power does these extra cores add given that you have written the app in order to take advantage of these cores.
<a href="http://www.passmark.com/index.html" target="_blank"><strong>Passmark Ratings</strong></a>
<a href="http://www.cpubenchmark.net/cpu.php?cpu=Intel+Core+i5-2450M+%40+2.50GHz">Intel Core i5-2450M @ 2.50GHz</a> is rated 3,574 and is present under high end CPU section. On the other hand <a href="http://www.cpubenchmark.net/cpu.php?cpu=Intel+Core2+Duo+T6570+%40+2.10GHz">Intel Core2 Duo T6570 @ 2.10GHz</a> is rated 1,350 and it is present under mid range CPU section.

### Performance Testing

For performance testing we need a CPU intensive application. CPU intensive application can be easily created by running multiple threads and making each thread do some heavy CPU related computation. In my case, I decided to simulate a real world problem of finding a &ldquo;sub-string&rdquo; pattern in a given string. &ldquo;Sub-string&rdquo; pattern search is a very well known problem and there are multiple established algorithms that solve this problem. I decided to use the famous Rabin-Karp algorithm for pattern matching. Explaining [Rabin-Karp](http://en.wikipedia.org/wiki/Rabin%E2%80%93Karp_algorithm) is beyond the scope of this article. 

The C# implementation of Rabin-Karp algorithm is taken from the following article : <a href="http://haishibai.blogspot.in/2011/03/karp-rabin-string-matching-algorithm-c.html">http://haishibai.blogspot.in/2011/03/karp-rabin-string-matching-algorithm-c.html</a>.
Next challenge was to find a large dataset i.e. large number of words/text/numbers which can act as patterns and then a large document which will be used as the the domain in which the Rabin-Karp pattern matching algorithm will be applied.
I am currently [reading](http://www.amazon.com/Algorithms-4th-Edition-Robert-Sedgewick/dp/032157351X) Algorithms 4th Edition by Robert Sedgewick and Kevin Wayne</a>. Its online web resources page provides lots of real world large [datasets](http://introcs.cs.princeton.edu/java/data/). I used a word file containing 20,068 words are the source of patterns that I wanted to search and another word file containing the complete [Magna-Carta](http://en.wikipedia.org/wiki/Magna_Carta) text as the domain in which the search will be performed.

#### Code

```csharp
public class RabinKarpAlgo
{
    private readonly string inputString;
    private readonly string pattern;
    private ulong siga = 0;
    private ulong sigb = 0;
    private readonly ulong Q = 100007;
    private readonly ulong D = 256;
    
    public RabinKarpAlgo(string inputString, string pattern)
    {
        this.inputString = inputString;
        this.pattern = pattern;
    }
    
    public bool Match()
    {
        for (int i = 0; i &lt; pattern.Length; i++)
        {
            siga = (siga * D + (ulong)inputString[i]) % Q;
            sigb = (sigb * D + (ulong)pattern[i]) % Q;
        }
        
        if(siga == sigb)
            return true;
        
        ulong pow = 1;
        for (int k = 1; k &lt;= pattern.Length - 1; k++)
            pow = (pow * D) % Q;
            
        for (int j = 1; j &lt;= inputString.Length - pattern.Length; j++)
        {
            siga = (siga + Q - pow * (ulong)inputString[j - 1] %Q) % Q;
            siga = (siga * D + (ulong)inputString[j + pattern.Length - 1]) % Q;
            
            if (siga == sigb)
            {
                if (inputString.Substring(j, pattern.Length) == pattern)
                {
                    return true;
                }
            }
        }
        
        return false;
    }
}

void Main()
{
    Dictionary<string,bool> collection = new Dictionary<string,bool>();
    IEnumerable<string> commonWords = File.ReadAllLines(<span class="str">@"G:\LINQPad4\words.txt")
        .Where(x =>; !string.IsNullOrEmpty(x)).Select(t => t.Trim());
    
    string magna_carta = File.ReadAllText(@"G:\LINQPad4\magna-carta.txt");
    
    Parallel.ForEach(commonWords,
    () =>; new Dictionary<string,bool>(),
    (word, loopState, localState) =>;
    {
        RabinKarpAlgo rbAlgo = new RabinKarpAlgo(magna_carta,word);
        localState.Add(word,rbAlgo.Match());
        return localState;
    },
    (localState) =>;
    {
        lock(collection){
            foreach(var item in localState)
            {
                collection.Add(item.Key, item.Value);
            }
        }
    });
    
    collection.Dump();
}
```
Note: I have used LinqPad for writing this application. If you don&rsquo;t have LinqPad in your machine then I will recommend you to go and download it from the official LinqPad site. You can also copy-paste the code in VS and it will run fine(ensure that you have given correct path for the files used in the code).
The above code takes a word as input and tries to figure out if it is present in the magna-carta text or not. Finally it saves the result set in a shared dictionary where the word represents the key and the value(true/false) represents its presence in the magna-carta text. Interesting thing to note here is that I have used the concept of &ldquo;Thread Local Storage&rdquo; while implementing the Parallel.ForEach block. For more on Thread Local Storage : <a href="http://weblogs.asp.net/pawanmishra/archive/2012/05/16/understanding-thread-local-storage-tls-in-tpl.aspx">http://weblogs.asp.net/pawanmishra/archive/2012/05/16/understanding-thread-local-storage-tls-in-tpl.aspx</a>
<strong>Results</strong>
With compiler optimization flag turned on on both machine, the code on C-i5 machine took around 20 seconds whereas on the Core 2 Duo T6570 machine it took close to 40 seconds. And with the compiler optimization flag turned off, the code on C-i5 machine took 35 seconds where on the Core 2 Duo T6570 machine it took more than a minute. I am not sure as what's going on when the compiler optimization flag is turned on that reduces the execution time almost by 50%(irrespective of the type of machine on which the code is running).&nbsp;
<strong>Things To Try</strong>
<ul>
<li>Remove parallelism and test the performance of sequential codebase</li>
<li>Remove thread local storage and instead use shared dictionary with explicit locking and test its performance</li>
<li>Use other files from <a href="http://introcs.cs.princeton.edu/java/data/">http://introcs.cs.princeton.edu/java/data/</a> site containing 200,000+ &amp; 600,000+ words respectively</li>
<li>Run the above code on i7 and on machines with more number of cores</li>
</ul>
<strong>GitHub Repository</strong> : <a href="https://github.com/pawanmishra/Rabin_Karp_Pattern_Search">https://github.com/pawanmishra/Rabin_Karp_Pattern_Search</a>