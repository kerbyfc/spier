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
    
    w = new Watcher('dir');
    
    w.on('create', function (file) {
        console.log( file.stat.isDirectory() ? 'directory' : 'file', file.name, 'created [', file.path, ']' );
    });
    
    w.start();
    
<br />
### License

MIT