// *****************************************************************************
// Are You Here?
//
// entrypoint file
//
// *****************************************************************************

import Express from 'express';
import fs from 'fs';
import { Dept } from './status';
import { modifyUserStatus, addDept } from './operation';

//
// init
//
const app = Express();

const deptFile = 'statuses.json';
let dept: Dept;
if (fs.existsSync(deptFile)) {
  const str = fs.readFileSync(deptFile).toString();
  dept = JSON.parse(str);
} else {
  dept = new Dept();
  dept.name = "Dept";
  fs.writeFileSync(deptFile, JSON.stringify(dept));
}


//
// config
//
const prefix = '/api';
app.use(Express.json());

app.get('/', function(req, res){
    res.sendFile('index.html', { root: __dirname + '' } );
});

// curl -X POST http://localhost:4486/api/refresh
app.post(prefix + '/refresh', (req, res) => {
  res.send(dept);
});

// curl -X POST http://localhost:4486/api/modifyUserStatus -d '{"name": "haru", "status": "Out"}' -H "Content-Type: application/json"
app.post(prefix + '/modifyUserStatus', (req, res) => {
  const user = req.body;
  modifyUserStatus(dept, user);
  res.send(dept);
});

app.post(prefix + '/addDept', (req, res) => {
  const addInfo = req.body;
  addDept(dept, addInfo);
  res.send(dept);
});





//
// start server
//
app.listen(4486, function () {
  console.log('App is listening on port 4486!');
});