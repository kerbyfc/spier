Spier <font size="2">1.1</font>
========= 

**Spies for any changes in directory, such as**

- create
- remove
- change
- rename

<br />

### Installation

    $ npm install -g spier
<br />

### Command line usage

    $ spy --help
<br />

### Command line usage example

    $ spy -d . --ignore .idea\|.git --filter \/js\/\|\/less\/
<br />

### Node.js usage

    Spier = require('spier');

    spier = new Spier('src');

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
    spier.on( 'rename', function (from, to, file) {
        console.log( 'rename', ftype(file), from, to );
    });

    spier.spy();
    
<br />