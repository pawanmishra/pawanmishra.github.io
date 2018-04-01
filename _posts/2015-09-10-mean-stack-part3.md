---
title: MEANT Stack Part3 - Front End Implementation - 1
tags: [vscode, node, typescript, mongodb, angularjs]
excerpt: In this and the next module, we will concentrate on building front-end of our application using [AngularJs](https://angularjs.org/), [TypeScript](http://www.typescriptlang.org/) & [Bootstrap](http://getbootstrap.com/).
---
{% include toc %}
In the previous two posts([part-1]({% post_url 2015-09-10-mean-stack-part1 %}) & [part-2]({% post_url 2015-09-10-mean-stack-part2 %})) we have gone through the steps of installing required software's and setting up of our applications back-end server functionality. In this and the next module, we will concentrate on building front-end of our application using [AngularJs](https://angularjs.org/), [TypeScript](http://www.typescriptlang.org/) & [Bootstrap](http://getbootstrap.com/). In this post, we will focus on building following things :

*   Configure VS Code for TypeScript development
*   Angular related setup code
*   Web page for listing registered teams
*   Implementing corresponding  AngularJs controller

> Note : Some of the code snippets that I have used in this blog post is taken from the “[Angular with TypeScript](http://www.pluralsight.com/courses/angular-typescript)” [pluralsight](http://www.pluralsight.com/) course by Deborah Kurata. I am thankful to pluralsight & Deborah Kurata for coming up with such an amazing course on Angularjs & TypeScript.

### Configure VS Code for TypeScript development

* * *

Open the solution directory in VS Code and press keys : **Ctrl + Shift + B.** Since we are doing this for the first time, we will be presented with the following prompt :

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_thumb_1.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_4.png)

Press the “**Configure Task Runner**” option on the right side of the bar. It will create “.settings” folder in our solution and in that it will add a file called **task.json.** Open up the file and in the very first un-commented JSON structure(given below), set the “args” property to empty array i.e. remove the default HelloWorld.ts entry.

```javascript
// A task runner that calls the Typescript compiler (tsc) and  
// Compiles a HelloWorld.ts program  
{  
    "version": "0.1.0",  

    // The command is tsc. Assumes that tsc has been installed using npm install -g typescript  
    "command": "tsc",  

    // The command is a shell script  
    "isShellCommand": true,  

    // Show the output window only if unrecognized errors occur.  
    "showOutput": "silent",  

    // args is the HelloWorld program to compile.  
    "args": [],  

    // use the standard tsc problem matcher to find compile problems  
    // in the output.  
    "problemMatcher": "$tsc"  
}
```

This enables VS Code to compile our TypeScript files. Lets get started with some angular + TypeScript related coding.

### AngularJs Setup Code

* * *

Download following files from internet and add it under the ~/public/scripts directory :

*   jquery-2.1.4.min.js
*   angular.js
*   angular-resource.js
*   angular-mocks.js
*   angular-route.js
*   bootstrap.min.js

Next download following files and add it under ~public/styles directory :

*   bootstrap.css

Next add following files as per the structure given below :

*   public
    *   app
        *   common
            *   common.services.ts
            *   dataAccessService.ts
        *   teams
            *   team.ts
            *   teamListCtrl.ts
            *   teamListView.html
            *   teamRegistrationCtrl.ts
            *   teamRegistrationView.html
        *   app.ts
    *   index.html

I have highlighted the files to be added in color. In this blog post, we will not be working on all of the files. Now that we have our TypeScript files(blank) added in our solution, just go ahead and press **Ctrl + Shift + B.**  This builds our solution and of everything ran file without throwing any errors, then TypeScript transpiler will  generate the corresponding *.js files in the same location.

> Remember : Every time *.ts file is modified, remember to press the **Ctrl+Shift+B**  command. This will update the corresponding *.js file. If you find that your application is not responding to the changes, then most likely you have forgotten to  update your JavaScript files.

Any angular project starts by declaring the root level module. In our case, lets do the same by adding following lines to the app.ts file under public directory.

```javascript
module app {  
        angular.module("teamManagement", ["common.services", "ngRoute"]).config(['$routeProvider',  
                function($routeProvider) {  
                }]);  
}
```

In the above code, we have declared our main module as “**teamManagement**”. Added two new dependencies : “**common.services**” & “**ngRoute**”. For now “**common.services**” is empty but don’t worry we will be populating it soon. “ngRoute” module is used for configuring angular-routes. We will add angular routing logic later in the code.

Lets switch over to common.services.ts file and add to it the following content :

```javascript
module app.common {  
    angular.module("common.services", ["ngResource"]);  
}
```

Finally, add to the **index.html** the following mark-up. We will be making use of angular’s **ng-view**, functionality to load html dynamically based on the routing logic.

```html
<!DOCTYPE html>  
<html>  
<head lang="en">  
    <meta charset="UTF-8">  
    <title>ACME World</title>  

    <!-- Style sheets -->  
    <link href="styles/bootstrap.css" rel="stylesheet" />  
</head>  
<body ng-app="teamManagement">  
    <div class="container">  
        <nav class="navbar navbar-default">  
            <div class="container-fluid">  
                <div class="navbar-header">  
                    <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">  
                    <span class="sr-only">Toggle navigation  
                    <span class="icon-bar">  
                    <span class="icon-bar">  
                    <span class="icon-bar">  
                    </button>  
                    <span class="navbar-brand">ACME  
                </div>  
                <div id="navbar" class="navbar-collapse collapse">  
                    <ul class="nav navbar-nav">  
                        <li><a href="#/teams">Home</a></li>  
                        <li><a href="#/register">Register</a>  
                    </ul>  
                </div>  
            </div>  
        </nav>  
        <ng-view />  
    </div>  
    <!-- Library Scripts -->  
    <script src="scripts/jquery-2.1.4.min.js"></script>  
    <script src="scripts/angular.js"></script>  
    <script src="scripts/angular-resource.js"></script>  
    <script src="scripts/angular-mocks.js"></script>  
    <script src="scripts/angular-route.js"></script>  
    <script src="scripts/bootstrap.min.js"></script>  

    <!-- Application Script -->  
    <script src="app/app.js"></script>  

    <!-- Domain Classes -->  
    <script src="app/teams/team.js"></script>  

    <!-- Services -->  
    <script src="app/common/common.services.js"></script>  
    <script src="app/common/dataAccessService.js"></script>  

    <!-- Controllers -->  
    <script src="app/teams/teamListCtrl.js"></script>  
    <script src="app/teams/teamRegistrationCtrl.js"></script>  
</body>  
</html>
```

The UI looks like below :

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_thumb_2.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_6.png)

Clicking on “**Home**” displays screen used for listing registered teams.

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_thumb_3.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_8.png)

and clicking on “**Register**” will display the registration page.

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_thumb_4.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_10.png)

Lets go through the code required for implementing our “**Home**” screen i.e. **teamListView.html** template.

### Building the UI : teamListView.html

* * *

First, add to the team.ts file inside ~public/app/teams directory, the strongly typed type definition for representing our schema i.e. to represent the data coming from the mongo database.

```javascript
module app.domain {  
    export interface ITeamMember {  
        EmpId : number;  
        firstName : string;  
        lastName : string;  
    }  

    export class TeamMember implements ITeamMember {  
        constructor(public EmpId: number,  
                    public firstName : string,  
                    public lastName : string) {  
                }  
    }  

    export interface ITeam {  
        name : string;  
        member_count : number;  
        members : ITeamMember[];  
    }  

    export class Team implements ITeam {  
        constructor(public name : string,  
                    public member_count : number,  
                    public members : app.domain.TeamMember[]) {  
        }  
    }  
}
```

We have defined an interface called “ITeamMember” which represents an individual team members. Next we have “ITeam” interface representing a team. A team consists of team name, member_count & array of team members. The declaration is wrapped under **app.domain** module declaration, which enables the corresponding JavaScript code base to be wrapped inside the **IIFE(immediately invoked function expression).** And annotating the interface and corresponding class definition with “**export**” keyword enables us to access the declared types in other files/modules. For e.g. we can access the “**ITeamMember**” interface using **app.domain.ITeamMember**.

Next lets implement our data access service layer by implementing it in dataAccessService.ts file. For performing any data access action, we will be making use of **angular-resource** module. Through this layer, we will be performing the CRUD operations which will be internally handled by our Node + [mongodb](https://www.mongodb.org/) based backend server. Following is the code which needs to be added in dataAccessService.ts file.

```javascript
module app.common {  
    interface IDataAccessService {  
        getTeamResource() : ng.resource.IResourceClass<ITeamResource>;  
    }  

    interface ITeamResource extends ng.resource.IResource<app.domain.ITeam> {  
    }  

    interface ITeamResourceClass extends ng.resource.IResourceClass<ITeamResource> {  
        update(params: Object, data: Object, success?: Function, error?: Function) : void;  
    }  

    export class DataAccessService   
        implements IDataAccessService {  

        static $inject = ["$resource"];  
        constructor(private $resource: ng.resource.IResourceService) {  

        }  

        getTeamResource() {  
            return <ITeamResourceClass> this.$resource("http://localhost:3000/teams/:teamName", {}, {  
                transformResponse: function(data, headers) {  
                    return angular.fromJson(data);  
                },  
                post: {method:'POST'},  
                query: {method: 'GET', isArray: true },  
                update: {method: 'PUT', isArray: false},  
                'delete': {method:'DELETE', params: { teamName:"@teamName" }}  
            });  
        }  
    }  
    angular.module("common.services").service("dataAccessService", DataAccessService);  
}
```

By default **angular-resource** [module](https://msdn.microsoft.com/en-us/library/dd233221.aspx) provides support for performing GET, POST & DELETE verbs. In the above code, we have extended it to provide support for PUT verb via “**update**” method. You can view the definitions of the interfaces like **IResource** & **IResourceClass** in the corresponding type definition file. You can read more about the “**update**” functionality here : [https://gist.github.com/scottmcarthur/9005953](https://gist.github.com/scottmcarthur/9005953 "https://gist.github.com/scottmcarthur/9005953"). In the above code, via the IDataAccessService class we are returning a representation of our resource which is going to be an instance of type **ITeam(app.domain.ITeam)**. And with the help of **angular-resource** module, we can perform the GET, POST, PUT & DELETE operations on that resource.

With our data access layer in place and the strongly typed definition of our resource defined, its time to add the HTML markup & corresponding controller for our teamListView.html template. Following is the markup of the template :

```javascript
<div class="panel panel-primary"  
     ng-controller="TeamListCtrl as vm">  
     <div class="panel-heading"  
            style="font-size:large">Search Teams  
     </div>  
     <div class="panel-body">  
        <div class="col-md-9">  
            <label for="teamName" class="sr-only">First Name</label>  
            <input type="text" id="teamName" ng-model="vm.teamName" class="form-control" placeholder="Team Name">  
        </div>  
        <div class="col-md-3">  
            <button ng-click="vm.searchTeams(vm.teamName, vm.log)" class="btn btn-primary btn-md btn-block">Search Teams</button>  
        </div>  
     </div>  
     <div class="panel-body container-fluid">  
         <div class="col-md-3" ng-repeat="team in vm.teams">  
             <div class="panel panel-primary">  
                <div class="panel-heading" style="font-size:large">  
                    <div class="btn-group pull-right">  
                        <a href="#/edit/{{team.name}}" class="btn btn-default btn-xs">Edit</a>  
                        <a href="#" ng-click="vm.delete($index)" class="btn btn-default btn-xs">Delete</a>  
                    </div>  
                    <h4>{{team.name}}</h4></div>  
                <div class="panel-body">  
                    <ul class="list-unstyled">  
                        <li ng-repeat="member in team.members" style="font-size:medium">{{ member.firstName }} {{ member.lastName }} - {{ member.EmpId }}</li>  
                    </ul>  
                </div>  
            </div>  
         </div>  
      </div>  
</div>
```

Lets break down the markup and understand the various components :

*   Our controller for this template is called “**TeamListCtrl**”
*   Next we have a div containing an input text box followed by a button. On clicking of the button, we are passing the value of the input text box as input parameter to the underlying method called “**searchTeams**”. As name suggests, we are going to use this feature for searching teams.
*   Finally, matching teams are listed in forms of divs. The header of the div contains the teamName and options for **editing** & **deleting** of the teams. And inside the div, individual team [member](https://msdn.microsoft.com/en-us/library/dd233244.aspx) are listed.

If you are mildly familiar with angularjs then the above code would be fairly easy to understand. Lets implement our  “**TeamListCtrl**”  controller. Add to the ~public/app/teams/teamListCtrl.ts file following content :

```javascript
module app.teamList {  
    interface ITeamCallback {  
        (items: app.domain.ITeam[]): any;     
    }  

    export interface ITeamListModel {  
        teams : app.domain.ITeam[];  
        teamName : string;  
        searchTeams(teamName : string, callback : ITeamCallback) : void;  
        log(items : app.domain.ITeam[]) : void;  
        delete(index : number) : void;  
    }  

    export class TeamListCtrl implements ITeamListModel {  
        teams : app.domain.ITeam[];  
        teamName : string;  

        static $inject=["dataAccessService", "$location"];  
        constructor(private dataAccessService : app.common.DataAccessService,  
            private $location : ng.ILocationService) {  
            this.teams = [];  
        }  

        searchTeams(teamName : string, callback : ITeamCallback) : void {  
            var resource = this.dataAccessService.getTeamResource();  
            this.teams = [];  
            let _me = this;  
            resource.query({teamName : teamName}, (data) => {  
                angular.forEach(data, function(ff){  
                    let members : app.domain.ITeamMember[] = [];  
                    angular.forEach(ff.members, function(item){  
                        let tempMem = new app.domain.TeamMember(item.EmpId, item.firstName, item.lastName);  
                        members.push(tempMem);  
                    })  
                    let tempTeam = new app.domain.Team(ff.name, members.length, members);  
                    _me.teams.push(tempTeam);  
                });  
                callback(_me.teams);  
            });  
        }  

        delete(index : number) : void {  
            let deletedTeam = this.teams[index];  
            this.teams.splice(index, 1);  
            var resource = this.dataAccessService.getTeamResource();  
            resource.delete({teamName : deletedTeam.name});  
            this.$location.path('/teams');  
        }  

        log(items : app.domain.ITeam[]) : void {  
            // do nothing  
        }  
    }  

    angular.module("teamManagement").controller("TeamListCtrl", TeamListCtrl);  
}
```

Lets try to understand the above mentioned code snippet :

```javascript
export interface ITeamListModel {  
    teams : app.domain.ITeam[];  
    teamName : string;  
    searchTeams(teamName : string, callback : ITeamCallback) : void;  
    log(items : app.domain.ITeam[]) : void;  
    delete(index : number) : void;  
}
```

In ITeamListModel, I have encapsulated the functionality which controller is going to provide to the UI. If we look at the markup, then we can see that each of the listed members of the ITeamListModel interface is tied to some visual element in UI. ITeamListModel is then implemented on concreete class called **TeamListModel.**

```javascript
export class TeamListCtrl implements ITeamListModel {  
    teams : app.domain.ITeam[];  
    teamName : string;  

    static $inject=["dataAccessService"];  
    constructor(private dataAccessService : app.common.DataAccessService) {  
        this.teams = [];  
    }  

    searchTeams(teamName : string, callback : ITeamCallback) : void {  
        var resource = this.dataAccessService.getTeamResource();  
        this.teams = [];  
        let _me = this;  
        resource.query({teamName : teamName}, (data) => {  
            angular.forEach(data, function(ff){  
                let members : app.domain.ITeamMember[] = [];  
                angular.forEach(ff.members, function(item){  
                    let tempMem = new app.domain.TeamMember(item.EmpId, item.firstName, item.lastName);  
                    members.push(tempMem);  
                })  
                let tempTeam = new app.domain.Team(ff.name, members.length, members);  
                _me.teams.push(tempTeam);  
            });  
            callback(_me.teams);  
        });  
    }  

    delete(index : number) : void {  
        let deletedTeam = this.teams[index];  
        this.teams.splice(index, 1);  
        var resource = this.dataAccessService.getTeamResource();  
        resource.delete({teamName : deletedTeam.name});  
    }  

    log(items : app.domain.ITeam[]) : void {  
        // do nothing  
    }  
}
```

First in the constructor, we are injecting “**dataAccessService**” module which we have declared above and we are initializing the “**teams**” array. Next in the searchTeams method, I am getting a representation of the **ITeam**  resource via getTeamResource() method and then querying over it via the “**query**” method. In the callback of the query method, I am parsing the returned result and populating the instance level “**teams**” array. Note how with help of TypeScript we are able to perform regular object oriented based functionalities lile create new instance of class “**TeamMember**” via “**new**” operator. Similarly the **delete** operation is straight forward. Delete method gets as input the index of deleted item. It removed the item from the “**teams**” array and then deletes it from database using the “**delete**” method. One last think which I haven’t touched is the second parameter to the searchTeams method i.e. a callback function. I will **touchbase** upon this in my next post.

> Note : If you have noticed inside method “searchTeams”, I have set **let _me = this**  in the third line of the method. In TypeScript, “**this**” refers to the current instance but inside the callback functions the context is lost. In order to pass the outer “**this**” instance in the callback function, just assign it to any local variable and access that local variable inside the callback.

Till now we have completed setting up of our angular module, data access layer, strongly typed schema of our resources, html markup of the template and corresponding angular controller implementation. One last think remaining is to link the teamListView.html with corresponding angular controller via angular routing functionality. To do that, add to app.ts following lines :

```javascript
module app {  
        angular.module("teamManagement", ["common.services", "ngRoute"]).config(['$routeProvider',  
                function($routeProvider) {                          
                        $routeProvider.when('/teams', {  
                                templateUrl: '/app/teams/teamListView.html'  
                        });  

                        $routeProvider.otherwise({  
                                redirectTo: '/'  
                        });  
                }]);  
}
```

Now if you have your node server & mongodb service running and if you navigate to the following url : [http://localhost:3000/index#/teams](http://localhost:3000/index#/teams), you will get the previously mentioned search teams screen. Clicking on the “Search Teams” button will list down our previously registered teams :

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_thumb_5.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/5f111ad5ba2a_9EEB/image_12.png)

This blog post covered lots of front related functionality. In the next post we will complete the app by implementing the registration screen and putting in place a small grunt script file for packaging our application.