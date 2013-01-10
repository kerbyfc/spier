Watcher 
=========
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Version 1.0 
 

<br />
**It detects directory changes, such as**

- create
- remove
- change
- rename

<br />

### Installation <br />
    npm install -g watcher
    
<br />
### Usage

    require 'watcher'
    
    w = new Watcher('mydir')
    
    w.on('create', function (file) {
        console.log( file.stat.isDirectory() ? 'directory' : 'file', file.name, ' created' );
    });
    
    w.start();
    
<br />
### License

MIT