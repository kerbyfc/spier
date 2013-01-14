#!/usr/bin/env node

Spier = require('../spier.js');

optkeys = {
    '-i': 'ignore',
    '--ignore': 'ignore',
    '-d': 'dir',
    '--dir': 'dir',
    '-f': 'filter',
    '--filter': 'filter',
    '-h': 'help',
    '--help' : 'help'
};

keys = {
    'dir': '-d --dir       • specify directory to spy',
    'ignore': '-i --ignore      regex that explains what files will be ignored',
    'filter': '-f --filter      regex that explains what files will be processed \n                   applying after -i',
    'help': '-h --help        show this message'
};

args = process.argv.slice(2);

options = {};
key = false;

while (args.length) {
    arg = args.shift();
    if (arg.match(/^-*/g)[0].length > 0 && optkeys[arg] !== void(0)) {
        key = optkeys[arg];
        options[key] = null;
    } else if (key) {
        options[key] = arg;
        key = false;
    }
};

if (options.help !== void(0) || options.dir === void(0) || options.dir === null) {

    help = '\n  Spier help:    • required\n';
    for (var i in keys) {
        help += '\n  ' + keys[i] + '\n';
    };
    console.log(help);

} else {

    spier = new Spier(options.dir, options);

    ctype = function (file) {
        return file.stat.isDirectory() ? 'directory' : 'file';
    };

    spier.on( 'create', function (file) {
        console.log( 'create' + ' ' +  ctype(file) + ' ' + file.path );
    });
    spier.on( 'remove', function (file) {
        console.log( 'remove' + ' ' +  ctype(file) + ' ' + file.path );
    });
    spier.on( 'change', function (file) {
        console.log( 'change' + ' ' +  ctype(file) + ' ' + file.path );
    });
    spier.on( 'rename', function (from, to, file) {
        console.log( 'rename', ctype(file), from, to );
    });

    spier.spy();

}

