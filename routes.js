var express = require('express');
var router = express.Router();
const log = require('barelog')
const fs = require('fs')
const { spawn } = require('child_process');
var tmp = require('tmp');

router.post('/processRaw', (req, res) => {

    const jbin = process.env.JSONNET_BIN;
    const jlib = process.env.JSONNET_LIB;
    const jfile = process.env.JSONNET_FILE;

    const tmpobj = tmp.fileSync();
    var fstream = fs.createWriteStream(null, {fd: tmpobj.fd});

    req.pipe(fstream);

    const child = spawn(jbin,
      ['-J', jlib,
       '--ext-code-file', 'src=' + tmpobj.name,
       jfile]);

       res.setHeader('Content-Type', 'application/json');

    const now = new Date().toISOString().
      replace(/T/, ' ').      // replace T with a space
      replace(/\..+/, '')     // delete the dot and everything after
      + ' UTC';

    child.stdout.on('data', (data) => {
      res.write(data.toString().replace(new RegExp(/%TIMESTAMP%/, 'g'), now));
      res.status(200);
    });
    child.stderr.on('data', (data) => {
      res.setHeader('Content-Type', 'text/plain');

      log('child err:' + data.toString());
      res.statusMessage = data.toString().replace(new RegExp(/[^a-zA-Z0-9 ]/, 'g'), ' ');
      log("sending back: " + res.statusMessage);
      res.status(400).end();
    });

    child.stdout.on('error', (data) => {
      res.setHeader('Content-Type', 'text/plain');

      log('child fail:' + data.toString());
      res.statusMessage = data.toString().replace(new RegExp(/[^a-zA-Z0-9 ]/, 'g'), ' ');
      log("sending back: " + res.statusMessage);
      res.status(400).end();

    });

    child.on('exit', function (code, signal) {
      log('child process exited with ' +
                  'code ' + code + ' and signal ' + signal);
      res.status(200);
      res.end();
    });
});

module.exports = router;
