Watcher 
=========
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Version 1.0 
 

<br />
**It detects any changes in directory, such as**

- create
- remove
- change
- rename

<br />

### Installation <br />
    npm install -g watcher
    
<br />
### Usage

    Watcher = require('watcher');

    w = new Watcher('src');

    ctype = function (file) {
        return file.stat.isDirectory() ? 'directory' : 'file';
    };

    w.on( 'create', function (file) {
        console.log( 'create' + ' ' +  ctype(file) + ' ' + file.path );
    });
    w.on( 'remove', function (file) {
        console.log( 'remove' + ' ' +  ctype(file) + ' ' + file.path );
    });
    w.on( 'change', function (file) {
        console.log( 'change' + ' ' +  ctype(file) + ' ' + file.path );
    });
    w.on( 'rename', function (from, to, file) {
        console.log( 'rename', ctype(file), from, to );
    });

    w.start();
    
<br />
### License

MIT