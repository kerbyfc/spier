Spier
=========
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Version 1.0
 

<br />
**It spied for any changes in directory, such as**

- create
- remove
- change
- rename

<br />

### Installation <br />
    npm install -g spier
    
<br />
### Usage

    Spier = require('spier');

    spier = new Spier('src');

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
    
<br />
### License

MIT