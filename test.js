Spier = require('./spier.js');

spier = new Spier({primary:true});

ftype = function (file) {
    return file.stat.isDirectory() ? 'directory' : 'file';
};

spier.on( 'create', function (file) {
    console.log( 'create' + ' ' +  ftype(file) + ' ' + file.path );
});
spier.on( 'remove', function (file) {
    console.log( 'remove' + ' ' +  ftype(file) + ' ' + file.path );
});
spier.on( 'change', function (file) {
    console.log( 'change' + ' ' +  ftype(file) + ' ' + file.path );
});
spier.on( 'rename', function (file) {
    console.log( 'rename', ftype(file), 'from', file.lastname, 'to', file.name );
});

spier.spy();