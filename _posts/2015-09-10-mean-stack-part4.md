---
title: MEANT Stack Part4 - Front End Implementation - 2
tags: [vscode, node, typescript, mongodb, angularjs]
exceprt: In this part we will implement the html page used for registering the teams.
---
{% include toc %}
This is the last part of the four part blog series on building web applications using MEAN stack, [TypeScript](http://www.typescriptlang.org/) and Visual Studio Code. In the previous three parts we have covered the following things :

*   [Part 1]({% post_url 2015-09-10-mean-stack-part1 %}) : Setting up the requires software, ide, node modules
*   [Part 2]({% post_url 2015-09-10-mean-stack-part2 %}) : REST Api implementation using ExpressJs and Mongoose based CRUD api for backend Mongo database
*   [Part 3]({% post_url 2015-09-10-mean-stack-part3 %}) : Implementation of html page for listing registred teams. Also lots of [AngularJs](https://angularjs.org/) related setup code implementation.

In this part we will implement the html page used for registering the teams. With most of the AngularJs related ground work has already been covered in the previous post, this post will be comparatively shorter than the previous posts in this series. Before we get down to the markup & related angular implementation, lets have a look at the UI of the html page :

### UI

* * *

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/Building-Web-App-Using-MEAN-StackPart-3-_8A07/image_thumb.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/Building-Web-App-Using-MEAN-StackPart-3-_8A07/image_2.png)

“**Add** [**Member**](https://msdn.microsoft.com/en-us/library/dd233244.aspx)” button is used to add new team members to the underlying collection in angularjs. Added team members are listed in the table below.any point of time, added team members can be removed by clicking the “**Remove**” button. Finally, provide the team_name information and click “**Submit**”. This will save the team to the underlying mongo database. Lets go through the angularjs controller & markup for this page.

#### HTML Template

* * *

```html
<div class="panel panel-primary"  
     ng-controller="TeamRegistrationCtrl as vm">  
        <div class="panel-heading"  
            style="font-size:large">Register  
        </div>  
        <div class="panel-body">  
            <div class="row">  
                <div class="col-md-3">  
                    <label for="firstName" class="sr-only">First Name</label>  
                    <input type="text" id="firstName" ng-model="vm.member.firstName" class="form-control" placeholder="First Name">  
                </div>  
                <div class="col-md-3">  
                    <label for="lastName" class="sr-only">Last Name</label>  
                    <input type="text" id="lastName" ng-model="vm.member.lastName" class="form-control" placeholder="Last Name">  
                </div>  
                <div class="col-md-3">  
                    <label for="empId" class="sr-only">Emp Id</label>  
                    <input type="number" id="empId" ng-model="vm.member.EmpId" class="form-control" placeholder="Emp Id">  
                </div>  
                <div class="col-md-3">  
                    <button ng-click="vm.addMember()" class="btn btn-primary btn-md btn-block">Add Member</button>  
                </div>  
            </div>  
            <div class="row">  
                </br>  
                </br>  
            </div>  
            <div class="row">  
                <div class="col-md-12">  
                    <table class="table table-condensed" style="font-size:medium">  
                        <thead>  
                            <tr>  
                                <th>First Name</th>  
                                <th>Last Name</th>  
                                <th>Emp Id</th>  
                                <th></th>  
                            </tr>  
                        </thead>  
                        <tbody>  
                            <tr ng-repeat="member in vm.members" >  
                                <td>{{ member.firstName }} </td>  
                                <td>{{ member.lastName }} </td>  
                                <td>{{ member.EmpId }} </td>  
                                <td><button ng-click="vm.remove($index)" class="btn btn-danger btn-sm">Remove</button></td>  
                            </tr>  
                        </tbody>     
                    </table>  
                </div>  
            </div>  
            <div class="row" ng-hide="!vm.members.length">  
                <div class="col-md-9">  
                    <label for="teamName" class="sr-only">Team Name</label>  
                    <input type="text" id="teamName" ng-model="vm.teamName" ng-readonly="!vm.newRecord" class="form-control" placeholder="Team Name" required="">  
                </div>  
                <div class="col-md-3">  
                    <button class="btn btn-md btn-primary btn-block" ng-click="vm.submit()">Submit</button>  
                </div>  
            </div>  
            <div class="panel-body" ng-show="vm.submitted">  
                <div class="col-md-12">  
                    <div ng-class="vm.saved ? 'panel panel-success' : 'panel panel-warning'">  
                        <div class="panel-heading" style="font-size:large">{{ vm.message }}</div>  
                    </div>  
                </div>  
            </div>  
        </div>  
</div>
```

### Controller
---

The controller for this page is called “**TeamRegistrationCtrl**”. the markup is making use of basic angularjs directives like ng-repeat, ng-hide etc. Styling of elements is done via [Bootstrap](http://getbootstrap.com/) css.

#### TeamRegistrationCtrl controller

* * *

```javascript
module app.teamRegistration {  
    interface ITeamListModel {  
        teamName : string;  
        saved : boolean;  
        submitted : boolean;  
        message : string;  
        members : app.domain.ITeamMember[];  
        member : app.domain.ITeamMember;  
        addMember() : void;  
        submit(): void;  
        newRecord : boolean;  
        remove(index : number) : void;  
    }  

    class TeamRegistrationCtrl implements ITeamListModel {  
        teamName : string = "";  
        team : app.domain.ITeam;  
        members : app.domain.TeamMember[] = [];  
        member : app.domain.ITeamMember;  
        saved : boolean;  
        submitted : boolean = false;  
        message : string;  
        teamList : app.teamList.ITeamListModel;  
        newRecord : boolean = true;  

        static $inject = ["dataAccessService", "$routeParams", "$location"]  
        constructor(private dataAccessService : app.common.DataAccessService,  
            private $routeParams : ng.route.ICurrentRoute,  
            private $location: ng.ILocationService) {  

            if($location.path().indexOf('edit') > 0) {  
                this.newRecord = !this.newRecord;  
                this.initializeEdit($location.path().slice($location.path().lastIndexOf('/') + 1));  
            }  
        }  

        initializeEdit(teamName : string) {  
            this.teamList = new app.teamList.TeamListCtrl(this.dataAccessService, this.$location);  
            this.teamList.searchTeams(teamName, (items) =>   
                {  
                    let item = items[0];  
                    this.teamName = item.name;  
                    this.members = item.members;  
                });  
        }  

        addMember(): void {  
            let mem = new app.domain.TeamMember(this.member.EmpId, this.member.firstName, this.member.lastName);  
            this.member.firstName = this.member.lastName = "";  
            this.member.EmpId = undefined;  
            this.submitted = false;  
            this.members.push(mem);  
        }  

        update(): void {  
            let _me = this;  
            let team : app.domain.ITeam = new app.domain.Team(this.teamName, this.members.length, this.members);  
            let resource = this.dataAccessService.getTeamResource();  
            resource.update({teamName : _me.teamName}, team, () => this.success(), () => this.failed());  
        }  

        submit(): void {  
            if(!this.newRecord) {  
                return this.update();  
            }  

            let _me = this;  
            let team : app.domain.ITeam = new app.domain.Team(this.teamName, this.members.length, this.members);  
            let resource = this.dataAccessService.getTeamResource();  
            resource.save(team, () => this.success(), () => this.failed());  
        }  

        success() : void {  
            this.saved = this.submitted = true;  
            this.members = [];  
            this.message = "Records saved successfully!!";  
        }  

        failed() : void {  
            this.submitted = true;  
            this.saved = false;  
            this.members = [];  
            this.message = "Some error occurred. Please try again or contact acme@acme.com.";  
        }  

        remove(index : number): void {  
            this.members.splice(index, 1);  
        }  
    }  

    angular.module("teamManagement").controller("TeamRegistrationCtrl", TeamRegistrationCtrl);  
}
```

Lets go through the above implementation by breaking it down into smaller pieces. First the “**ITeamListModel**”.

```javascript
interface ITeamListModel {  
    teamName : string;  
    saved : boolean;  
    submitted : boolean;  
    message : string;  
    members : app.domain.ITeamMember[];  
    member : app.domain.ITeamMember;  
    addMember() : void;  
    submit(): void;  
    newRecord : boolean;  
    remove(index : number) : void;  
}
```

This is the model which is governing our UI. Method names are self-explanatory. And the properties are bounded to various UI elements using **ng-model** directive. We have an array called “**members**” which keeps track of the numbers of member added. Submitted & newRecord fields are used for toggling UI elements based on the success or failure of the operation.

> Note : In the previous post, I haven’t covered the functionality of “editing” a team. Listed teams can either be deleted or edited. If you go through the code of this application, you will very easily understand how edit functionality is working. I am not going to cover the edit part in this post.

```javascript
static $inject = ["dataAccessService", "$routeParams", "$location"]  
constructor(private dataAccessService : app.common.DataAccessService,  
    private $routeParams : ng.route.ICurrentRoute,  
    private $location: ng.ILocationService) {  

    if($location.path().indexOf('edit') > 0) {  
        this.newRecord = !this.newRecord;  
        this.initializeEdit($location.path().slice($location.path().lastIndexOf('/') + 1));  
    }  
}
```

In the above code, we are injecting various dependencies in our class. Then using the $locationProvider, I am checking if the current route includes “edit” i.e. whether the screen is being used for editing existing team or for creating new team.

```javascript
addMember(): void {  
    let mem = new app.domain.TeamMember(this.member.EmpId, this.member.firstName, this.member.lastName);  
    this.member.firstName = this.member.lastName = "";  
    this.member.EmpId = undefined;  
    this.submitted = false;  
    this.members.push(mem);  
}  

update(): void {  
    let _me = this;  
    let team : app.domain.ITeam = new app.domain.Team(this.teamName, this.members.length, this.members);  
    let resource = this.dataAccessService.getTeamResource();  
    resource.update({teamName : _me.teamName}, team, () => this.success(), () => this.failed());  
}  

submit(): void {  
    if(!this.newRecord) {  
        return this.update();  
    }  

    let _me = this;  
    let team : app.domain.ITeam = new app.domain.Team(this.teamName, this.members.length, this.members);  
    let resource = this.dataAccessService.getTeamResource();  
    resource.save(team, () => this.success(), () => this.failed());  
}
```

”**addMember**” function is tied to the “**Add Member**” button. On clicking of the button, we are adding the member information to the instance level “**members**” collection. Similarly, “**update**” & “**submit**” functions are used for updating existing record or for creating new record.

```javascript
success() : void {  
    this.saved = this.submitted = true;  
    this.members = [];  
    this.message = "Records saved successfully!!";  
}  

failed() : void {  
    this.submitted = true;  
    this.saved = false;  
    this.members = [];  
    this.message = "Some error occurred. Please try again or contact acme@acme.com.";  
}  

remove(index : number): void {  
    this.members.splice(index, 1);  
}
```

Lastly, we have three helper functions namely success, failed & remove. Success callback is used when save or submit operation is completed successfully. Failed when the CRUD operations failed. Remove method is used for removing added team members from the “members” collection.

### Summary
---

In this blog post series, I might not have covered all of the code in a line by line manner. But if you have basic knowledge of angular & [nodejs](https://nodejs.org/en/), then you will be able to understand what the code is doing. This code base is a nice playground for practicing existing & upcoming front end technologies. I hope that you have & you will enjoy this blog post series.