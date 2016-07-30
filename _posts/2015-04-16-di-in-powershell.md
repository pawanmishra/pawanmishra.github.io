---
layout: single
title: Dependency Injection in PowerShell
tags: [C#, PowerShell]
---
In this blog post, I will explain how we can invoke dependency injection based managed code from [PowerShell](http://en.wikipedia.org/wiki/Windows_PowerShell). Invoking regular managed code from PowerShell is quiet straight forward. Say for example, you are asked to create an instance of [HttpClient](https://msdn.microsoft.com/en-us/library/system.net.http.httpclient%28v=vs.118%29.aspx) class and call the GetStringAsync method on it, then it can be done with just following few lines of code.

```
<#
# Load the assemblies
#>
Add-Type -AssemblyName "mscorlib.dll"
[System.Reflection.Assembly]::Load("System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[System.Reflection.Assembly]::Load("System.Net.Http, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

<#
# Create the instance of HttpClient
#>
[string]$contentType = 'application/json'
$client = New-Object -TypeName System.Net.Http.HttpClient
$headerValue = New-Object System.Net.Http.Headers.MediaTypeWithQualityHeaderValue -ArgumentList ($contentType)

<#
# Call the method
#>
$result = $client.GetStringAsync($url).Result
```

The same approach can be used for invoking method of other custom implemented managed classes. All that is required is to refer the assembly & then create instance of the class using “**New-Object**” keyword.

Things get complicated when the custom managed class is instantiated using dependency injection framework like [Ninject](http://www.ninject.org/) or [StructureMap](http://docs.structuremap.net/). In any realistic enterprise application, its natural to expect that there would be some sort of DI framework in play and any sufficiently capable class would be injected with multiple dependency classes. So if we plan to create an instance of following class using “New-Object” approach, then it will require lot of repetitive & boring effort of new-ing up all the injected dependencies.

```csharp
public class IMDBProcess
{
    public IMDBProcess(ILogger logger, IUrlHelper urlHelper, IDBHelper dbHelper,
    IMediaHelper mediaHelper, IIMDBBusinessService businessService...){
        .....
    }
}
```

The proper way of creating an instance of the above class is to :

*   **Initialize the DI container via PowerShell or in other words invoke the code in your managed codebase that initializes the DI container from PowerShell**
*   **Use the container instance to create an instance of the above class**

Unfortunately, invoking the managed code which does the DI container initialization isn't straight forward in most of the application. This code gets executed during application bootstrap and has its own set of dependencies.

I have used the following approach for initializing the [Ninject](http://www.ninject.org/) kernel. The same approach can be used for initializing any other DI framework like [StructureMap](http://docs.structuremap.net/) etc.

```javascript
function Initialize {
    try
    {
        [System.AppDomain]$currentDomain = [System.AppDomain]::CurrentDomain 
        $path = $currentDomain.GetData("APPBASE")

        $Source = @"

            using System;
            using System.Reflection;
            using System.IO;
            using Ninject;
            using Ninject.Extensions.Conventions;
            using Ninject.Extensions.Factory;
            // Add relevant namespaces which are required
            // by the class MyNinjectKernel class

            public class MyNinjectKernel
            {
                static MyNinjectKernel()
                {
                    AppDomain.CurrentDomain.AssemblyResolve += new ResolveEventHandler(CurrentDomain_AssemblyResolve);
                }

                static System.Reflection.Assembly CurrentDomain_AssemblyResolve(object sender, ResolveEventArgs args)
                {
                   string assembliesDir = AppDomain.CurrentDomain.BaseDirectory;
                   var assemblyPath = Path.Combine(assembliesDir, args.Name + ".dll");
                   if (File.Exists(assemblyPath) == false) return null;
                   Assembly assembly = Assembly.LoadFrom(assemblyPath);
                   return assembly;
                }

                public IKernel GetKernel()
                {
                    IKernel kernel = new StandardKernel();
                    // Call custom code which initializes the kernel. 
                    // Remember to add the relevant namespaces.
                    // once initialized return the kernel instance
                    return kernel;
                }

                public object Get(IKernel kernel, Type type)
                {
                    return kernel.Get(type);
                }
            }
"@

        $currentPath = $PSScriptRoot
        $currentDomain.SetData("APPBASE", $currentPath)
        $refs = @("$PSScriptRoot\Ninject.dll", 
                    "$PSScriptRoot\Ninject.Extensions.Factory.dll", 
                    "$PSScriptRoot\Ninject.Extensions.Conventions.dll",
                    // Important : Add references to the all the assemblies which are being used by the MyNinjectKernel class)
        $res = Add-Type -TypeDefinition $Source -Language CSharp -ReferencedAssemblies $refs -PassThru
        $ninject = New-Object MyNinjectKernel
        return $ninject 
    }
    finally
    {
        $currentDomain.SetData("APPBASE", $path)
    }
}
```

Once we have the function in place, then we can call the **Initialize**() function and use the returned $**ninject** instance to create instance of any DI based class.

```
[System.Type]$type = ([type]"AdventureWorks.World.IMDBProcess")
$ninject = Initialize
$kernel = $ninject.GetKernel()
$instance = $ninject.Get($kernel, $type)
```