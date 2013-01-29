// Generated by CoffeeScript 1.4.0
(function() {
  var Dir, File, Spier, fs, minimatch,
    __slice = [].slice,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  fs = require('fs');

  minimatch = require('minimatch');

  Array.prototype.diff = function(arr) {
    return this.filter(function(i) {
      return !(arr.indexOf(i) > -1);
    });
  };

  File = (function() {

    File.prototype.stat = function(path) {
      return fs.statSync(path);
    };

    File.prototype.path = function() {
      var parts;
      parts = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return parts.join(Dir.prototype.separator);
    };

    File.prototype["new"] = function(path, options, parent) {
      var stat;
      if (options == null) {
        options = {};
      }
      stat = File.prototype.stat(path);
      if (stat.isDirectory()) {
        return new Dir(path, stat, options);
      } else {
        return new File(path, stat);
      }
    };

    function File(path, stat) {
      this.path = path;
      this.name = this.path.split(Dir.prototype.separator).slice(-1)[0];
      this.stat = stat;
    }

    return File;

  })();

  Dir = (function() {

    Dir.prototype.separator = process.platform.match(/^win/) != null ? '\\' : '/';

    Dir.prototype.options = {
      pattern: null,
      ignore: null
    };

    function Dir(path, stat, options, parent) {
      if (parent == null) {
        parent = null;
      }
      this.read = __bind(this.read, this);

      this.setup = __bind(this.setup, this);

      this.path = path;
      this.stat = stat;
      this.options = options;
      this.parent = parent;
      this.name = this.path.split(Dir.prototype.separator).slice(-1)[0];
      this.setup();
    }

    Dir.prototype.setup = function() {
      this.subdirs = false;
      this.files = {};
      this.cache = {};
      this.index = {
        current: [],
        existed: [],
        ignored: [],
        subdirs: []
      };
      return this.history = {};
    };

    Dir.prototype.cleanup = function() {
      this.index.current = [];
      this.index.subdirs = [];
      return this.cache = {};
    };

    Dir.prototype.cached = function(filename) {
      return this.cache[filename] || File.prototype["new"](File.prototype.path(this.path, filename, this));
    };

    Dir.prototype.filepath = function(filename) {
      return File.prototype.path(this.path, filename);
    };

    Dir.prototype.check = function(filename) {
      var path, stat;
      path = this.filepath(filename);
      if (this.isInIgnore(path)) {
        return this.ignore(filename);
      }
      stat = File.prototype.stat(path);
      if (!this.matchPattern(path) && !stat.isDirectory()) {
        return this.ignore(filename);
      } else {
        return this.cache[filename] = stat.isDirectory() ? new Dir(path, stat, this.options, this) : new File(path, stat);
      }
    };

    Dir.prototype.isInIgnore = function(path) {
      if (this.options.debug) {
        console.log("" + path + " " + ((this.options.ignore != null) && this.options.ignore.test(path) ? 'WAS' : 'WASN`T') + " ignored by " + this.options.ignore + " pattern");
      }
      return (this.options.ignore != null) && this.options.ignore.test(path);
    };

    Dir.prototype.matchPattern = function(path) {
      if (this.options.debug) {
        console.log("" + path + " " + (!(this.options.pattern != null) || this.options.pattern.test(path) ? 'WAS' : 'WASN`T') + " processed by " + this.options.pattern + " pattern");
      }
      return !(this.options.pattern != null) || this.options.pattern.test(path);
    };

    Dir.prototype.ignore = function(filename) {
      this.index.ignored.push(filename);
      return false;
    };

    Dir.prototype.read = function() {
      var filename, _i, _len, _ref;
      this.cleanup();
      _ref = fs.readdirSync(this.path);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        filename = _ref[_i];
        if (__indexOf.call(this.index.ignored, filename) < 0) {
          this.add(filename);
        }
      }
      return this;
    };

    Dir.prototype.add = function(filename) {
      if (__indexOf.call(this.index.existed, filename) >= 0 || this.check(filename)) {
        return this.index.current.push(filename);
      }
    };

    Dir.prototype.archive = function(filename, event, file) {
      var _base, _ref;
      if ((_ref = (_base = this.history)[filename]) == null) {
        _base[filename] = [];
      }
      this.history[filename].push([event, file]);
      if (this.history[filename].length > 20) {
        return this.history[filename].shift();
      }
    };

    Dir.prototype.trigger = function(event, file) {
      Spier.instances[this.options.id].handlers[event](file);
      return this.archive(file.name, event, file);
    };

    Dir.prototype.invoke = function() {
      var data, event, file;
      event = arguments[0], data = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if ((file = this[event].apply(this, data))) {
        return this.trigger(event, file);
      }
    };

    Dir.prototype.create = function(filename, file) {
      if (file == null) {
        file = false;
      }
      this.files[filename] = file || this.cached(filename);
      if (this.files[filename].stat.isDirectory()) {
        this.index.subdirs.push(filename);
        this.subdirs = true;
      }
      if (this.files[filename].stat.isDirectory() && (!this.options.folders || this.options.skipEmpty)) {
        return false;
      } else {
        if (this.options.skipEmpty && (this.parent != null) && !this.parent.history[this.name]) {
          this.parent.trigger('create', this);
          if (!this.files[filename].stat.isDirectory()) {
            return this.files[filename];
          } else {
            return false;
          }
        } else {
          return this.files[filename];
        }
      }
    };

    Dir.prototype.remove = function(filename) {
      var tmp,
        _this = this;
      tmp = (function() {
        return _this.files[filename];
      })();
      delete this.files[filename];
      return tmp;
    };

    Dir.prototype.rename = function(oldname, newname) {
      this.files[newname] = this.files[oldname];
      this.files[newname].path = File.prototype.path(this.path, newname);
      this.files[newname].name = newname;
      this.files[newname].lastname = oldname;
      delete this.files[oldname];
      return this.files[newname];
    };

    Dir.prototype.change = function(filename) {
      var curr;
      curr = File.prototype.stat(this.filepath(filename));
      if (curr.isDirectory() && (this.files[filename].stat.atime.getTime() !== curr.atime.getTime() || this.files[filename].subdirs)) {
        this.files[filename].stat = curr;
        this.index.subdirs.push(filename);
        return false;
      } else if (!curr.isDirectory() && this.files[filename].stat.ctime.getTime() !== curr.ctime.getTime()) {
        this.files[filename].stat = curr;
        return this.files[filename];
      } else {
        return false;
      }
    };

    Dir.prototype.filenames = function() {
      var file, name, _ref, _results;
      _ref = this.files;
      _results = [];
      for (name in _ref) {
        file = _ref[name];
        _results.push(name);
      }
      return _results;
    };

    Dir.prototype.filepaths = function(filenames) {
      var filename, _i, _len, _results;
      if (filenames == null) {
        filenames = this.filenames();
      }
      _results = [];
      for (_i = 0, _len = filenames.length; _i < _len; _i++) {
        filename = filenames[_i];
        _results.push(this.filepath(filename));
      }
      return _results;
    };

    Dir.prototype.directories = function() {
      var file, name, _ref, _results;
      _ref = this.files;
      _results = [];
      for (name in _ref) {
        file = _ref[name];
        if (file.stat.isDirectory()) {
          _results.push(file);
        }
      }
      return _results;
    };

    Dir.prototype.compare = function() {
      var created, current, existed, file, removed, subdir, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _results;
      existed = this.index.existed;
      current = this.index.current;
      created = current.diff(existed);
      removed = existed.diff(current);
      if (removed.length === created.length && created.length === 1) {
        this.invoke('rename', removed[0], created[0]);
      } else {
        for (_i = 0, _len = created.length; _i < _len; _i++) {
          file = created[_i];
          this.invoke('create', file);
        }
        for (_j = 0, _len1 = removed.length; _j < _len1; _j++) {
          file = removed[_j];
          this.invoke('remove', file);
        }
        _ref = existed.diff(removed);
        for (_k = 0, _len2 = _ref.length; _k < _len2; _k++) {
          file = _ref[_k];
          this.invoke('change', file);
        }
      }
      this.index.existed = (function(c) {
        return c;
      })(this.index.current);
      _ref1 = this.index.subdirs;
      _results = [];
      for (_l = 0, _len3 = _ref1.length; _l < _len3; _l++) {
        subdir = _ref1[_l];
        _results.push(this.files[subdir].read(this.options).compare());
      }
      return _results;
    };

    return Dir;

  })();

  Spier = (function() {

    Spier.prototype.delay = 50;

    Spier.prototype.pause = false;

    Spier.prototype.step = 1;

    Spier.prototype.memory = 10.0;

    Spier.prototype.handlers = {};

    Spier.prototype.options = {
      id: null,
      root: null,
      ignore: null,
      pattern: null,
      matchBase: false,
      existing: false,
      dot: true,
      folders: false,
      skipEmpty: false
    };

    Spier.instances = {};

    Spier.spy = function() {
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Spier, arguments, function(){}).spy();
    };

    function Spier(options) {
      if (options != null) {
        this.configure(options);
      }
    }

    Spier.prototype.spy = function(options) {
      var stat;
      if (this.options.id != null) {
        return this.start();
      }
      if (options != null) {
        this.configure(options);
      }
      if (this.options.root == null) {
        this.shutdown('Specify directory path for spying. Use spy --help');
      }
      try {
        stat = File.prototype.stat(this.options.root);
      } catch (e) {
        this.shutdown(this.options.root + ' doesn`t exists');
      }
      if (!stat.isDirectory()) {
        this.shutdown(this.options["in"] + ' is not a directory');
      }
      this.scope = new Dir(this.options.root, stat, this.options);
      this.options.id = Math.random().toString().substr(2);
      Spier.instances[this.options.id] = this;
      this.start();
      return this;
    };

    Spier.prototype.configure = function(options) {
      var option, value;
      if (options == null) {
        options = null;
      }
      if (typeof options !== 'object') {
        this.shutdown("Options object missing");
      }
      this.options.matchBase = options.matchBase || false;
      for (option in options) {
        value = options[option];
        this.options[option] = option !== 'pattern' && option !== 'ignore' ? value : this.regexp(value, option);
      }
      if (!this.options.folders) {
        this.options.skipEmpty = false;
      }
      return this;
    };

    Spier.prototype.regexp = function(pattern, name) {
      var fIndex;
      if (pattern instanceof RegExp || pattern === null) {
        return pattern;
      } else if (typeof pattern === 'string') {
        if (!pattern.length) {
          return null;
        }
        try {
          if ((pattern.match(/^r\/.*\/([igm]*)?$/) != null) && (fIndex = pattern.lastIndexOf('/'))) {
            return new RegExp(pattern.substr(2, fIndex - 3), pattern.substring(fIndex + 1));
          } else {
            return minimatch.makeRe(pattern, {
              matchBase: this.options.matchBase,
              dot: this.options.dot
            });
          }
        } catch (e) {
          return this.shutdown("Pattern `" + pattern + "` is invalid. " + e.message);
        }
      } else {
        return this.shutdown("Option `" + name + "` must be an instance of String or RegExp. <" + (typeof pattern) + "> " + pattern + " given");
      }
    };

    Spier.prototype.lookout = function() {
      var _this = this;
      this.scope.read().compare();
      if (!this.pause) {
        return this.timeout = setTimeout(function() {
          _this.lookout();
          return _this.step++;
        }, this.delay);
      }
    };

    Spier.prototype.pause = function() {
      this.timeout = clearTimeout(this.timeout) || null;
      return this.pause = true;
    };

    Spier.prototype.start = function() {
      this.step = this.options.existing ? 1 : 0;
      this.pause = false;
      return this.lookout();
    };

    Spier.prototype.on = function(event, handler) {
      var _this = this;
      this.handlers[event] = function() {
        if (_this.step > 0) {
          return handler.apply(null, arguments);
        }
      };
      return this;
    };

    Spier.prototype.shutdown = function(msg) {
      console.log(msg);
      return process.exit(0);
    };

    return Spier;

  })();

  module.exports = Spier;

}).call(this);
