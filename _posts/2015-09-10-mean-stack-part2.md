---
title: MEANT Stack Part2 - Node & Mongoose SetUp
tags: [vscode, node, typescript, mongodb, angularjs]
---
{% include toc %}
In the previous [post]({% post_url 2015-09-10-mean-stack-part1 %}), we went through the steps of installing necessary software's & modules required for building our application. In this post, we are going to concentrate on our application backend i.e. setting up node as as web server & mongoose related codebase for performing CRUD activities in the underlying mongo database.

> Note : Ensure that the [mongodb](https://www.mongodb.org/) service is running by verifying it in the services.msc. Also now that we are starting with actual coding, it’s time for us to open up our solution(File –> Open Folder) in Visual Studio Code.

Lets start with some [nodejs](https://nodejs.org/en/) related coding.

### Node Startup file

* * *

Under bin directory, create a new JavaScript file and call it [www.js](http://www.js) and add to it the following lines :

```javascript
var debug = require('debug')('example-server');  
var app = require('../');  

app.set('port', process.env.PORT || 3000);  

var server = app.listen(app.get('port'), function() {  
  debug('Express server listening on port ' + server.address().port);  
});
```

Next open up the package.json file and under “**scripts**” section, add the following line :

```javascript
"scripts": {  
  "test": "echo \"Error: no test specified\" && exit 1",  
  "start": "node ./bin/www"  
},
```

Normally when we start node via “**node**” followed by a startup script file e.g. **node index.js**. With “start” tag, what we can instead do is in command prompt, navigate to the root directory and issue : “**npm start**” command. This will automatically start node with “./bin/www.js” as startup script file. Screenshot below :

[![image](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/Building-Web-App-Using-MEAN-StackPart-2-_D280/image_thumb.png "image")](https://aspblogs.blob.core.windows.net/media/pawanmishra/Windows-Live-Writer/Building-Web-App-Using-MEAN-StackPart-2-_D280/image_2.png)

In the **package.json** file, we have specified the main script file as “**index.js**”. Next we have to create the “**index.js**” file. In the root level, add new JavaScript file called “**index.js**” and add to it the following content :

```javascript
var express = require("express");  
var path = require('path');  
var cookieParser = require('cookie-parser');  
var bodyParser = require('body-parser');  

require('./lib/connection');  
var teams = require('./routes/teams');  

var app = express();  

app.use(bodyParser.json());  
app.use(bodyParser.urlencoded({ extended: true}));  
app.use(cookieParser());  
app.use(express.static(path.join(__dirname, 'public')));  

app.use(teams);  

app.use(function(req, res, next){  
    var err = new Error('Not found');  
    err.status = 404;  
    next(err);  
});  

app.use(function(err, req, res, next) {  
    res.status(err.status || 500);  
});  

module.exports = app;
```

The above code loads various node modules and performs some configuration related steps. It also attaches global level error handlers. For the time being ignore the “./lib/connection” & “./routes/teams” file for now. We will come back to these files later in the post. With this code in place, if we execute the “**npm start**” command, then our node server start running. Although since we haven’t defined any end points for receiving requests, the server would be of no use to us. So lets setup our mongoose related codebase for performing CRUD applications against our mongodb.

> Note : If your are not familiar with mongodb and how it works, then you can go through the online tutorial here : [http://docs.mongodb.org/manual/core/crud-introduction/](http://docs.mongodb.org/manual/core/crud-introduction/ "http://docs.mongodb.org/manual/core/crud-introduction/"). For these blog post series, I am making an assumption that you are comfortable with mongodb & working with mongo shell. However I would like to emphasize that even if you have very basic knowledge of mongodb & mongo shell, then that would be good enough for this blog post series.

### Mongoose Setup

* * *

The very first thing that we have to finalize is the schema of our document that will be persistent in the database. With “schema of our document”, I mean our the structure of our object that will be serialized into JSON before getting persisted in the database. Start by creating a new file called “**team.js**” under “**models**” directory and add the following content to it.

```javascript
var mongoose = require('mongoose');  
var Schema = mongoose.Schema;  
var TeamSchema = new Schema({  
    name: {  
        type: String,  
        required: true,  
        unique: true  
  },  
  member_count: {  
    type: Number,  
    required: true  
  },  
  members: [{  
   EmpId: {  
     type: String,  
     required: true  
   },  
   firstName: {  
     type: String,  
     required: true  
   },  
   lastName: {  
     type: String,  
     required: true  
   }   
  }]  
});  

module.exports = mongoose.model('Team', TeamSchema);
```

Our “**TeamSchema**” contains a team name(represented by name), count of team members([member](https://msdn.microsoft.com/en-us/library/dd233244.aspx)_count) and array of team members represented by json object containing three fields i.e. EmpId, firstName & lastName. You can read more about mongoose schema here : [https://scotch.io/tutorials/using-mongoosejs-in-node-js-and-mongodb-applications](https://scotch.io/tutorials/using-mongoosejs-in-node-js-and-mongodb-applications "https://scotch.io/tutorials/using-mongoosejs-in-node-js-and-mongodb-applications")

Next we will add RESTful api endpoints for creating, update, delete & retrieve of “**Team**” resource.

### RESTful Implementation for Team Schema

* * *

Under “routes” folder, create a new file called “**teams.js**” with following content.

```javascript
var express = require('express');  
var mongoose = require('mongoose');  
var Team = mongoose.model('Team');  
var router = express.Router();  

router.post('/teams', function(req, res, next) {  
      Team.create(req.body, function (error, team1) {  
        if (error) {  
            return res.sendStatus(500);  
        }   
        res.sendStatus(200);  
  });  
});  

router.get('/teams/:teamName', function(req, res, next) {  
    Team.find({name: new RegExp(req.params.teamName, 'i')}).exec(function(error, result) {  
        if(error) {  
            return next(error);  
        }  

        if(!result) {  
            res.status(404);  
        }  

        res.json(result);  
    });  
});  

router.put('/teams/:teamName', function(req, res, next) {  
    delete req.body._id;  

    Team.update({name : req.params.teamName}, req.body, function(error, affectedRows, response) {  
        if(error) {  
            return next(error);  
        }  
        res.sendStatus(200);  
    });  
});  

router.delete('/teams/:teamName', function(req, res, next) {  
    Team.findOne({name : req.params.teamName}).remove().exec(function(error, result) {  
        if(error) {  
            return next(error);  
        }  

        res.sendStatus(200);  
    })  
})  

router.get('/teams', function(req, res, next) {  
    Team.find().sort({member_count: 1}).exec(function(error, result){  
        if(error) {  
            return next(error);  
        }  

        res.json(result);  
    });  
});  

router.get('/', function(req, res, next) {  
    res.redirect('/teams');  
});  

module.exports = router;
```

If you are mildly familiar with Node & mongoose, then the above code should be self explanatory. I have added REST end points for GET, POST, PUT & DELETE. Last piece that is remaining is configuring the mongodb connection. After that we would move on to the testing of our API.

### Mongoose Connection Configuration

* * *

Under “**lib**” folder create “**connection.js**” file with following content :

```javascript
var mongoose = require('mongoose');  
var dbUrl = 'mongodb://localhost:27017/teams';  
mongoose.connect(dbUrl);  

process.on('SIGINT', function(){  
    mongoose.connection.close(function(){  
        console.log('Mongoose default connection closed!!');  
        process.exit(0);  
    });  
});  

require('../models/team');
```

By default mongodb service runs on port 27017\. You can change the port at the time of installation. Also “**/teams**” tells mongodb to which database it needs to connect to. If the database is not present, mongodb will create the database once the very first request arrives.

### Testing

* * *

Through command line, start the node server by issuing command : **npm start.** This will start the node server. Next using chromes extension POSTMAN, we will test our API.

First lets create few resources using the POST command. Issue POST request on following url : “**http://localhost:3000/teams**” with following items as body content.

```
--------------- First Team -----------------------  
{
    "name": "TeamA",
    "member_count" : 3,
    "members": [
        {
            "EmpId": 11,
            "firstName": "Dan",
            "lastName": "D"
        },
        {
            "EmpId": 21,
            "firstName": "Pan",
            "lastName": "P"
        },
        {
            "EmpId": 31,
            "firstName": "San",
            "lastName": "S"
        }]
}  

----------------- Second Team ---------------------  
{
    "name": "TeamC",
    "member_count" : 2,
    "members": [
        {
            "EmpId": 11,
            "firstName": "Mok",
            "lastName": "M"
        },
        {
            "EmpId": 21,
            "firstName": "Foo",
            "lastName": "F"
        }]
}  
--------------- Third Team -----------------------------  
{
    "name": "TeamC",
    "member_count" : 2,
    "members": [
        {
            "EmpId": 11,
            "firstName": "Yup",
            "lastName": "Y"
        }]
}
```

If the api is working fine, then for each POST request, you should get HTTP Status Code 200 as response.

Next lets issue some GET Request.

```
Request : http://localhost:3000/teams  
Response :  

[  
  {  
    "_id": "55f1806b3518e1881b0b4798",  
    "name": "TeamC",  
    "member_count": 1,  
    "__v": 0,  
    "members": [  
      {  
        "EmpId": "11",  
        "firstName": "Yup",  
        "lastName": "Y",  
        "_id": "55f1806b3518e1881b0b4799"  
      }  
    ]  
  },  
  {  
    "_id": "55f1805b3518e1881b0b4795",  
    "name": "TeamB",  
    "member_count": 2,  
    "__v": 0,  
    "members": [  
      {  
        "EmpId": "11",  
        "firstName": "Mok",  
        "lastName": "M",  
        "_id": "55f1805b3518e1881b0b4797"  
      },  
      {  
        "EmpId": "21",  
        "firstName": "Foo",  
        "lastName": "F",  
        "_id": "55f1805b3518e1881b0b4796"  
      }  
    ]  
  },  
  {  
    "_id": "55f180423518e1881b0b4791",  
    "name": "TeamA",  
    "member_count": 3,  
    "__v": 0,  
    "members": [  
      {  
        "EmpId": "11",  
        "firstName": "Dan",  
        "lastName": "D",  
        "_id": "55f180423518e1881b0b4794"  
      },  
      {  
        "EmpId": "21",  
        "firstName": "Pan",  
        "lastName": "P",  
        "_id": "55f180423518e1881b0b4793"  
      },  
      {  
        "EmpId": "31",  
        "firstName": "San",  
        "lastName": "S",  
        "_id": "55f180423518e1881b0b4792"  
      }  
    ]  
  }  
]  

Request : http://localhost:3000/teams/TeamC  
Response :  

[
  {
    "_id": "55f1806b3518e1881b0b4798",
    "name": "TeamC",
    "member_count": 1,
    "__v": 0,
    "members": [
      {
        "EmpId": "11",
        "firstName": "Yup",
        "lastName": "Y",
        "_id": "55f1806b3518e1881b0b4799"
      }
    ]
  }
]
```

Finally lets try updating a record using PUT action.

```
Request : http://localhost:3000/teams/TeamC  
HTTP Verb : PUT  
Request Body :  

{
    "name": "TeamC",
    "member_count" : 1,
    "members": [
        {
            "EmpId": 11,
            "firstName": "Grown Yup",
            "lastName": "G Y"
        }]
}  

Response : 200 OK  

Request : http://localhost:3000/teams/TeamC  
HTTP Verb : GET  
Response :  

[
  {
    "_id": "55f1806b3518e1881b0b4798",
    "name": "TeamC",
    "member_count": 1,
    "__v": 0,
    "members": [
      {
        "EmpId": "11",
        "firstName": "Grown Yup",
        "lastName": "G Y",
        "_id": "55f183083518e1881b0b479a"
      }
    ]
  }
]
```

In each of the server response, the returned entity is having additional fields like “_id” & “__v”. These fields are added by mongodb. For our implementation purpose, we don’t really have to worry about these fields.

Now that our back end server & RESful api is working fine, its time to move on to the front end development. And that is where we would experience the power of [TypeScript](http://www.typescriptlang.org/).