#!/usr/bin/env node

var spier = require('../spier.js');
var program = require('commander');
var sys = require('sys');
var exec = require('child_process').exec;

function parseString(val) {
    if (typeof val === 'object') {
        var result = [];
        for (var i in val) {
            if (typeof val[i] !== 'function') {
                result.push (val[i]);
            }
        }
        console.log('result', result.join(','));
        return '{' + result.join(',') + '}';
    } else {
        return val.toString();
    }
}

program
    .version('1.4.0')
    .usage('spy <target> [options]')
    .option('-t, --in [directory]', 'specify a directory for watching', '.')
    .option('-p, --for <pattern>', 'filter files by pattern, regexp string or object', parseString, null)
    .option('-i, --ignoring <pattern>', 'ignore files by pattern, regexp string or object', parseString, null)
    .option('-m, --matchBase', 'matchBase flag for minimatch patterns')
    .option('-e, --existing', 'call create callbacks for existing files on start')
    .option('-f, --folders', 'call create callbacks for folders')
    .option('-s, --skipEmpty', 'skip empty folders')
    .option('-D, --debug', 'output debug information');


program.on('--help', function(){
    console.log('  Example:');
    console.log("    spy --for '**/photos_{normal,big}/*.{jpg,jpeg}' --in 'www/uploads' --ignoring 'r/sex|porno/i' \n");
});

program.parse(process.argv);

var options = {
    root: program['in'],
    ignore: program['ignoring'],
    pattern: program['for'],
    existing: program.existing !== void(0),
    matchBase: program.matchBase !== void(0),
    folders: program.folders !== void(0),
    skipEmpty: program.skipEmpty !== void(0),
    debug: program.debug !== void(0)
};

console.log(options);

spier = new spier(options);

var ctype = function (file) {
    // console.log('--------------------------', file, file['stat']);
    return file.stat.isDirectory() ? 'directory' : 'file';
};

spier.on( 'create', function (file) {
    console.log( 'create' + ' ' +  ctype(file) + ' ' + file.path );
});
spier.on( 'remove', function (file) {
    console.log( 'remove' + ' ' +  ctype(file) + ' ' + file.path );
});
spier.on( 'change', function (file) {
    console.log('change', arguments);
    console.log( 'change' + ' ' +  ctype(file) + ' ' + file.path );
});
spier.on( 'rename', function (file) {
    console.log( 'rename', ctype(file), file.oldpath, file.path );
});

spier.spy();