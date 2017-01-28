---
layout: splash
title: MEANT Stack - Part1
tags: [vscode, node, typescript, mongodb, angularjs]
---
{% include toc %}
In this multi-part blog series, I will walk you through on how to build a small web application using  [Nodejs](https://nodejs.org/en/), [MongoDb](https://www.mongodb.org/), [TypeScript](http://www.typescriptlang.org/) & [AngularJs](https://angularjs.org/). We will be building a small web application for creating and registering teams. A team will have team members and a unique team name. The application will have two screens. First one used for creating a new team and the other one used for listing all the registered teams. In this post, we will concentrate on installing & setting up of required software's. Let’s get started.

> Note : Some of the code snippets that I have used in this blog post is taken from the “[Angular with TypeScript](http://www.pluralsight.com/courses/angular-typescript)” [pluralsight](http://www.pluralsight.com/) course by Deborah Kurata. I am thankful to pluralsight & Deborah Kurata for coming up with such an amazing course on Angularjs & TypeScript.

### Visual Studio Code

* * *

Download and install Visual Studio Code from here : [https://code.visualstudio.com/](https://code.visualstudio.com/ "https://code.visualstudio.com/")

### MongoDb

* * *

Download and install [MongoDb](https://www.mongodb.org/) from here : [https://www.mongodb.org](https://www.mongodb.org "https://www.mongodb.org"). You can choose either the msi based installer or the zip format. Install or unzip the content in any directory of your choice say C:/mongo. Add to <span style="font-weight: bold;">system path, <span style="font-weight: normal;">the mongodb’s bin directory path i.e. C:\mongo\bin. Next, at the bin directory level, create two new folders i.e. db & log. And inside db folder, create another folder called data. The data folder will contain our database related files. Finally, we need to install [mongodb](https://www.mongodb.org/) as service. For that, lets first create a configuration file inside C:\mongo directory and call it as mongod.cfg. Add following lines to the config file :</span></span>

```yaml
systemLog:  
    destination: file  
    path: c:\mongo\log\mongod.log  
storage:  
    dbPath: c:\mongo\db\data
```

Next for installing mongodb as service, issue the following command. You can read more about it here : [https://docs.mongodb.org/manual/tutorial/install-mongodb-on-windows/](https://docs.mongodb.org/manual/tutorial/install-mongodb-on-windows/ "https://docs.mongodb.org/manual/tutorial/install-mongodb-on-windows/")

> "C:\mongo\bin\mongod.exe" --config "C:\mongo\mongod.cfg" --install

Ensure that mongodb is installed and up & running as service in services.msc.

### Node

* * *

Download and install Nodejs from here : [https://nodejs.org/en/](https://nodejs.org/en/ "https://nodejs.org/en/"). Nodejs will also install the node package manager called npm. We will first use npm to install global level modules. Executing the following command will install TypeScript, grunt-cli & TypeScript Definitions as global packages.

> npm install grunt grunt-cli typescript tsd -g

To check if TypeScript is installed or not, execute the following command :

> tsc -version  
Output : message TS6029: Version 1.5.3

### Folder Structure

* * *

Lets start by creating the relevant folder structure for our application. I am going to call the root level folder as “MEANT” which stands for Mongo Express [Angularjs](https://angularjs.org/) Node & TypeScript. Inside the “MEANT” folder, create following folder structure :

*   bin
*   lib
*   models
*   public
    *   app
        *   common
        *   teams
    *   images
    *   scripts
    *   styles
*   routes

### Configuring NPM & Node Modules

* * *

With the folder structure in place, lets go ahead and configure the node modules required for building our application. In command prompt, navigate to the “MEANT” directory and execute the following command :

> npm init

Calling npm init will initialize the directory with node specific files like package.json, index.js etc. It will prompt us for entering application level metadata information. For this tutorial, just leave everything to default. Sample :

```
C:\Pawan\Dev\MEANT>npm init  
This utility will walk you through creating a package.json file.  
It only covers the most common items, and tries to guess sensible defaults.  

See `npm help json` for definitive documentation on these fields  
and exactly what they do.  

Use `npm install <pkg>--save` afterwards to install a package and  
save it as a dependency in the package.json file.  

Press ^C at any time to quit.  
name: (MEANT) MEANT  
Sorry, name can no longer contain capital letters.  
name: (MEANT) meant  
version: (1.0.0)  
description:  
entry point: (index.js)  
test command:  
git repository:  
keywords:  
author:  
license: (ISC)  
About to write to C:\Pawan\Dev\MEANT\package.json:  

{  
  "name": "meant",  
  "version": "1.0.0",  
  "description": "",  
  "main": "index.js",  
  "scripts": {  
    "test": "echo \"Error: no test specified\" && exit 1"  
  },  
  "author": "",  
  "license": "ISC"  
}  

Is this ok? (yes) yes  

C:\Pawan\Dev\MEANT>
```

Next we have to install the node modules that are required for our application. Execute the following command :

> C:\Pawan\Dev\MEANT>npm install express debug mongoose path body-parser cookie-parser --save

### TypeScript Type Definition Installation

* * *

Next we are going to install the TypeScript’s type definition files for various node & angular libraries that we are going to use in our application. Type definition files help in providing intellisense when working various client side libraries. You can read more about TSD here : [http://definitelytyped.org/](http://definitelytyped.org/ "http://definitelytyped.org/"). In order to install the tsd files, execute the following command :

> C:\Pawan\Dev\MEANT>tsd install angularjs/* jquery express node mongoose body-parser gruntjs --save

If executed successfully, the output would look something like below. tsd will create a new file called tsd.json containing list of all the modules for which the tsd files have been installed and all of the *.d.ts files will be installed inside the typings folder.

```
C:\Pawan\Dev\MEANT>tsd install angularjs/* jquery express node mongoose body-parser gruntjs --save  

 - angularjs       / angular-animate  
   -> angularjs    > angular  
   -> jquery       > jquery  
 - angularjs       / angular-cookies  
   -> angularjs    > angular  
   -> jquery       > jquery  
 - angularjs       / angular-mocks  
   -> angularjs    > angular  
   -> jquery       > jquery  
 - angularjs       / angular-resource  
   -> angularjs    > angular  
   -> jquery       > jquery  
 - angularjs       / angular-route  
   -> angularjs    > angular  
   -> jquery       > jquery  
 - angularjs       / angular-sanitize  
   -> angularjs    > angular  
   -> jquery       > jquery  
 - angularjs       / angular  
   -> jquery       > jquery  
 - angularjs       / angular-scenario-v1.2.0  
   -> jquery       > jquery  
 - body-parser     / body-parser  
   -> express      > express  
   -> node         > node  
   -> serve-static > serve-static  
   -> mime         > mime  
 - express         / express  
   -> node         > node  
   -> serve-static > serve-static  
   -> mime         > mime  
 - gruntjs         / gruntjs  
   -> node         > node  
 - jquery          / jquery  
 - mongoose        / mongoose  
   -> node         > node  
 - node            / node  

running install..  

written 16 files:  

- angularjs/angular-animate.d.ts  
- angularjs/angular-cookies.d.ts  
- angularjs/angular-mocks.d.ts  
- angularjs/angular-resource.d.ts  
- angularjs/angular-route.d.ts  
- angularjs/angular-sanitize.d.ts  
- angularjs/angular.d.ts  
- angularjs/legacy/angular-scenario-1.2.d.ts  
- body-parser/body-parser.d.ts  
- express/express.d.ts  
- gruntjs/gruntjs.d.ts  
- jquery/jquery.d.ts  
- mime/mime.d.ts  
- mongoose/mongoose.d.ts  
- node/node.d.ts  
- serve-static/serve-static.d.ts
```

Finally lets add one more config file called tsconfig.json containing the following lines. This file tells TypeScript’s transpiler to generate ES5 compatible JavaScript.

```
{  
    "compilerOptions": {  
        "target": "ES5"  
    }  
}
```

With this we have successfully completed the installation of all of the required components that are needed for our application. In the next post, we will cover nodejs & mongoose related implementation. By the end of the next post, we would be able to create, update, delete teams with team members in our mongodb database via our running node server.