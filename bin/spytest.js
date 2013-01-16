Spier = require('../spier.js');

optkeys = {
    '-i': 'ignore',
    '--ignore': 'ignore',
    '-d': 'dir',
    '--dir': 'dir',
    '-o': 'original',
    '--original': 'original',
    '-f': 'filter',
    '--filter': 'filter',
    '-h': 'help',
    '--help' : 'help'
};

keys = {
    'dir': '• -d --dir        <path>  - specify directory to spy on\n',
    'ignore': '  -i --ignore     <regex> - explains what files will be ignored\n',
    'filter': '  -f --filter     <regex> - explains what files will be processed. \n                              NOTE: applying after -i',
    'original': '  -o --original\n',
    'help': '  -h --help show this message\n'
};

args = process.argv.slice(2);

options = {};
key = false;

while (args.length) {
    arg = args.shift();
    if (arg.match(/^-*/g)[0].length > 0 && optkeys[arg] !== void(0)) {
        key = optkeys[arg];
        console.log( key );
        options[key] = null;
    } else if (key) {
        options[key] = arg;
        key = false;
    }
};

if (options.help !== void(0) || options.dir === void(0) || options.dir === null) {

    help = '\n  Spier help:    • required\n';
    for (var i in keys) {
        help += '\n  ' + keys[i];
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