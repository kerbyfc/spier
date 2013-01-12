
Spier = require('../spier.js');

optkeys = {
  '-i': 'ignore',
  '--ignore': 'ignore',
  '-d': 'dir',
  '--dir': 'dir',
  '-f': 'filter',
  '--filter': 'filter'
};

args = process.argv.slice(2);

options = {};
key = false;

while (args.length) {
    arg = args.shift();
    console.log( arg );
    console.log( optkeys );
    if (arg.match(/^-*/g)[0].length > 0 && optkeys[arg] !== void(0)) {
        key = optkeys[arg];
        console.log( key );
        options[key] = null;
    } else if (key) {
        options[key] = arg;
        key = false;
    }
};


console.log(options);

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