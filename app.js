var express = require('express');
var path = require('path');
const log = require('barelog')


var router = require('./routes.js');

var app = express();

app.use(express.static(path.join(__dirname, 'public')));
app.use('/node_modules', express.static(path.join(__dirname, 'node_modules')));

app.use('/', router);

// error handler
app.use(function(err, req, res, next) {
  log('ERROR PASSED TO EXPRESS ERROR HANDLER:')
  log(err)
  // set locals, only providing error in development
  res.locals.message = err.message;


  // render the error page
  res.status(err.status || 500);
  res.json({ error: err })

});

module.exports = app;
