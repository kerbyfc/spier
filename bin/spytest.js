#!/usr/bin/env node

var spier = require('../spier.js');
var program = require('commander');
var sys = require('sys')
var exec = require('child_process').exec;

program
    .version('1.4.0')
    .option('-i, in [directory]', 'specify a directory for watching', '.')
    .option('-f, for [pattern]', 'filter files by pattern, regexp string or object', null)
    .option('-i, ignoring [pattern]', 'ignore files by pattern, regexp string or object', null)
    .option('-m, matchBase', 'matchBase flag for minimatch patterns')
    .option('-e, existing', 'call create callbacks on start')


program.on('--help', function(){
    console.log('  Example:');
    console.log('    spy for /myRegExp/i in project ignoring /.git|.idea/ \n');
});

program.parse(process.argv);

if (!program.in) {
    console.log('Use spy --help');
} else {

    var options = {
        root: program.in,
        ignore: program.ignoring,
        pattern: program.for,
        existing: program.existing !== void(0),
        matchBase: program.matchBase !== void(0)
    }

    spier = new spier(options);

    var ctype = function (file) {
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

//spier = new Spier()
//console.log(program);


//
//console.log('you ordered a pizza with:');
//if (program.peppers) console.log('  - peppers');
//if (program.pineapple) console.log('  - pineappe');
//if (program.bbq) console.log('  - bbq');
//console.log('  - %s cheese', program.cheese);
//
//
//Spier = require('../spier.js');
//
//optkeys = {
//    '-i': 'ignore',
//    '--ignore': 'ignore',
//    '-if': 'ignore_flags',
//    '--i-flags': 'ignore_flags',
//    '-d': 'dir',
//    '--dir': 'dir',
//    '-e': 'existing',
//    '--existing': 'existing',
//    '-p': 'pattern',
//    '--pattern': 'pattern',
//    '-f': 'filter',
//    '-ff': 'filter_flags',
//    '--f-flags': 'filter_flags',
//    '--filter': 'filter',
//    '-s': 'skip_empty',
//    '--skip-empty': 'skip_empty',
//    '-h': 'help',
//    '--help' : 'help'
//};
//
//keys = {
//    'dir': '• -d --dir        <String> - Directory path to spy for\n                               Just use " -d . " to spy for current directory \n',
//    'ignore': '  -i --ignore     <RegExp> - Files to be ignored \n                               If you want to ignore git and idea folders, then specify `.idea\\|.git`\n',
//    'ignore_flags': '  -if --i-flags   <String> - RegExp flags for -i option (`g`,`i`)  \n',
//    'filter': '  -f --filter     <RegExp> - Files to be processed \n                               If you want to spy for files changes in `app` and `bin` folders, just specify: `app\\/\\|bin\\/`. Take effect after after -i \n',
//    'filter_flags': '  -ff --f-flags   <String> - RegExp flags for -f option (`g`,`i`)  \n',
//    'pattern': '  -p --pattern   <string> - Minimatch pattern, that explains what files will be processed. See [https://github.com/isaacs/minimatch] \n',
//    'skip_empty': '  -s --skip-empty          - Empty directories (without non-ignored files, matched by pattern or filter regexp) will be skipped \n',
//    'existing': '  -e --existing            - Fire create events for existing files on start \n                               Use if applying of `create` callbacks on existing files is needed\n',
//    'help': '  -h --help                - Show this help\n'
//};
//
//args = process.argv.slice(2);
//
//options = {};
//key = false;
//
//while (args.length) {
//    arg = args.shift();
//    if (arg.match(/^-*/g)[0].length > 0 && optkeys[arg] !== void(0)) {
//        key = optkeys[arg];
//        options[key] = null;
//    } else if (key) {
//        options[key] = arg;
//        key = false;
//    }
//};
//
//if (options.help !== void(0) || options.dir === void(0) || options.dir === null) {
//
//    help = '\n  Spier help:    • required\n';
//    for (var i in keys) {
//        help += '\n  ' + keys[i];
//    };
//    console.log(help);
//
//} else {
//
//    spier = new Spier(options.dir, options);
//
//    ctype = function (file) {
//        return file.stat.isDirectory() ? 'directory' : 'file';
//    };
//
//    spier.on( 'create', function (file) {
//        console.log( 'create' + ' ' +  ctype(file) + ' ' + file.path );
//    });
//    spier.on( 'remove', function (file) {
//        console.log( 'remove' + ' ' +  ctype(file) + ' ' + file.path );
//    });
//    spier.on( 'change', function (file) {
//        console.log( 'change' + ' ' +  ctype(file) + ' ' + file.path );
//    });
//    spier.on( 'rename', function (from, to, file) {
//        console.log( 'rename', ctype(file), from, to );
//    });
//
//    spier.spy();
//
//}