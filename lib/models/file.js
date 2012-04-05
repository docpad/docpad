(function() {
  var EventSystem, FileModel, balUtil, coffee, fs, js2coffee, path, yaml, _,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  balUtil = require('bal-util');

  fs = require('fs');

  path = require('path');

  _ = require('underscore');

  EventSystem = balUtil.EventSystem;

  coffee = null;

  yaml = null;

  js2coffee = null;

  FileModel = (function(_super) {

    __extends(FileModel, _super);

    FileModel.prototype.layouts = null;

    FileModel.prototype.outDirPath = null;

    FileModel.prototype.logger = null;

    FileModel.prototype.type = 'file';

    FileModel.prototype.id = null;

    FileModel.prototype.basename = null;

    FileModel.prototype.extension = null;

    FileModel.prototype.extensions = [];

    FileModel.prototype.extensionRendered = null;

    FileModel.prototype.filename = null;

    FileModel.prototype.filenameRendered = null;

    FileModel.prototype.fullPath = null;

    FileModel.prototype.outPath = null;

    FileModel.prototype.relativePath = null;

    FileModel.prototype.relativeBase = null;

    FileModel.prototype.data = null;

    FileModel.prototype.header = null;

    FileModel.prototype.parser = null;

    FileModel.prototype.meta = {};

    FileModel.prototype.body = null;

    FileModel.prototype.content = null;

    FileModel.prototype.rendered = false;

    FileModel.prototype.contentRendered = false;

    FileModel.prototype.contentRenderedWithoutLayouts = null;

    FileModel.prototype.dynamic = false;

    FileModel.prototype.title = null;

    FileModel.prototype.date = null;

    FileModel.prototype.slug = null;

    FileModel.prototype.url = null;

    FileModel.prototype.urls = [];

    FileModel.prototype.ignore = false;

    FileModel.prototype.tags = [];

    FileModel.prototype.relatedDocuments = [];

    function FileModel(_arg) {
      var key, meta, value;
      this.layouts = _arg.layouts, this.logger = _arg.logger, this.outDirPath = _arg.outDirPath, meta = _arg.meta;
      this.extensions = [];
      this.meta = {};
      this.urls = [];
      this.tags = [];
      this.relatedDocuments = [];
      for (key in meta) {
        if (!__hasProp.call(meta, key)) continue;
        value = meta[key];
        this[key] = value;
      }
    }

    FileModel.prototype.getAttributes = function() {
      var attributeName, attributeNames, attributes, value, _i, _len;
      attributes = {};
      attributeNames = 'id basename extension extensions extensionRendered filename filenameRendered fullPath outPath relativePath relativeBase\n\ndata header parser meta body content rendered contentRendered contentRenderedWithoutLayouts\n\ndynamic title date slug url urls ignore tags'.split(/\s+/g);
      for (_i = 0, _len = attributeNames.length; _i < _len; _i++) {
        attributeName = attributeNames[_i];
        value = this[attributeName];
        if (typeof value !== 'function') attributes[attributeName] = value;
      }
      return attributes;
    };

    FileModel.prototype.getSimpleAttributes = function() {
      var attributeName, attributeNames, attributes, value, _i, _len;
      attributes = {};
      attributeNames = 'id basename extension extensions extensionRendered filename filenameRendered fullPath outPath relativePath relativeBase\n\nparser\n\ndynamic title date slug url urls ignore tags'.split(/\s+/g);
      for (_i = 0, _len = attributeNames.length; _i < _len; _i++) {
        attributeName = attributeNames[_i];
        value = this[attributeName];
        if (typeof value !== 'function') attributes[attributeName] = value;
      }
      return attributes;
    };

    FileModel.prototype.toJSON = function() {
      return this.getAttributes();
    };

    FileModel.prototype.load = function(next) {
      var complete, filePath, logger,
        _this = this;
      filePath = this.relativePath || this.fullPath || this.filename;
      logger = this.logger;
      logger.log('debug', "Loading the file " + filePath);
      complete = function(err) {
        if (err) return typeof next === "function" ? next(err) : void 0;
        logger.log('debug', "Loaded the file " + filePath);
        return typeof next === "function" ? next() : void 0;
      };
      path.exists(this.fullPath, function(exists) {
        if (exists) {
          return _this.read(complete);
        } else {
          return _this.parse(_this.data, function(err) {
            if (err) return typeof next === "function" ? next(err) : void 0;
            return _this.normalize(function(err) {
              if (err) return typeof next === "function" ? next(err) : void 0;
              return complete();
            });
          });
        }
      });
      return this;
    };

    FileModel.prototype.read = function(next) {
      var logger, tasks,
        _this = this;
      logger = this.logger;
      logger.log('debug', "Reading the file " + this.relativePath);
      tasks = new balUtil.Group(function(err) {
        if (err) {
          logger.log('err', "Failed to read the file " + _this.relativePath);
          return typeof next === "function" ? next(err) : void 0;
        } else {
          return _this.normalize(function(err) {
            if (err) return typeof next === "function" ? next(err) : void 0;
            logger.log('debug', "Read the file " + _this.relativePath);
            return typeof next === "function" ? next() : void 0;
          });
        }
      });
      tasks.total = 2;
      if (this.date) {
        tasks.complete();
      } else {
        balUtil.openFile(function() {
          return fs.stat(_this.fullPath, function(err, fileStat) {
            balUtil.closeFile();
            if (err) return typeof next === "function" ? next(err) : void 0;
            if (!_this.date) _this.date = new Date(fileStat.ctime);
            return tasks.complete();
          });
        });
      }
      balUtil.openFile(function() {
        return fs.readFile(_this.fullPath, function(err, data) {
          balUtil.closeFile();
          if (err) return typeof next === "function" ? next(err) : void 0;
          return _this.parse(data.toString(), tasks.completer());
        });
      });
      return this;
    };

    FileModel.prototype.parse = function(fileData, next) {
      var a, b, c, err, key, match, seperator, value, _ref;
      fileData = (fileData || '').replace(/\r\n?/gm, '\n').replace(/\t/g, '    ');
      this.data = fileData;
      this.header = null;
      this.parser = null;
      this.meta = {};
      this.body = null;
      this.content = null;
      this.rendered = false;
      this.contentRendered = null;
      this.contentRenderedWithoutLayouts = null;
      this.extensionRendered = null;
      this.filenameRendered = null;
      match = /^\s*([\-\#][\-\#][\-\#]+) ?(\w*)\s*/.exec(this.data);
      if (match) {
        seperator = match[1];
        a = match[0].length;
        b = this.data.indexOf("\n" + seperator, a) + 1;
        c = b + 3;
        this.header = this.data.substring(a, b);
        this.body = this.data.substring(c);
        this.parser = match[2] || 'yaml';
        try {
          switch (this.parser) {
            case 'coffee':
            case 'cson':
              if (!coffee) coffee = require('coffee-script');
              this.meta = coffee.eval(this.header, {
                filename: this.fullPath
              });
              break;
            case 'yaml':
              if (!yaml) yaml = require('yaml');
              this.meta = yaml.eval(this.header);
              break;
            default:
              this.meta = {};
              err = new Error("Unknown meta parser [" + this.parser + "]");
              return typeof next === "function" ? next(err) : void 0;
          }
        } catch (err) {
          return typeof next === "function" ? next(err) : void 0;
        }
      } else {
        this.body = this.data;
      }
      this.body = this.body.replace(/^\n+/, '');
      this.meta || (this.meta = {});
      this.content = this.body;
      this.title = this.title || this.basename || this.filename;
      if ((this.meta.date != null) && this.meta.date) {
        this.meta.date = new Date(this.meta.date);
      }
      if (this.meta.urls != null) this.addUrl(this.meta.urls);
      if (this.meta.url != null) this.addUrl(this.meta.url);
      _ref = this.meta;
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        value = _ref[key];
        this[key] = value;
      }
      if (typeof next === "function") next();
      return this;
    };

    FileModel.prototype.addUrl = function(url) {
      var existingUrl, found, newUrl, _i, _j, _len, _len2, _ref;
      if (url instanceof Array) {
        for (_i = 0, _len = url.length; _i < _len; _i++) {
          newUrl = url[_i];
          this.addUrl(newUrl);
        }
      } else if (url) {
        found = false;
        _ref = this.urls;
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          existingUrl = _ref[_j];
          if (existingUrl === url) {
            found = true;
            break;
          }
        }
        if (!found) this.urls.push(url);
      }
      return this;
    };

    FileModel.prototype.writeRendered = function(next) {
      var filePath, logger,
        _this = this;
      filePath = this.outPath;
      logger = this.logger;
      logger.log('debug', "Writing the rendered file " + filePath);
      balUtil.openFile(function() {
        return fs.writeFile(filePath, _this.contentRendered, function(err) {
          balUtil.closeFile();
          if (err) return typeof next === "function" ? next(err) : void 0;
          logger.log('debug', "Wrote the rendered file " + filePath);
          return typeof next === "function" ? next() : void 0;
        });
      });
      return this;
    };

    FileModel.prototype.write = function(next) {
      var body, data, fullPath, header, logger,
        _this = this;
      fullPath = this.fullPath;
      logger = this.logger;
      if (!js2coffee) {
        js2coffee = require(path.join('js2coffee', 'lib', 'js2coffee.coffee'));
      }
      logger.log('debug', "Writing the file " + filePath);
      header = 'var a = ' + JSON.stringify(this.meta);
      header = js2coffee.build(header).replace(/a =\s+|^  /mg, '');
      body = this.body.replace(/^\s+/, '');
      data = "### " + this.parser + "\n" + header + "\n###\n\n" + body;
      this.header = header;
      this.body = body;
      this.data = data;
      balUtil.openFile(function() {
        return fs.writeFile(_this.fullPath, _this.data, function(err) {
          balUtil.closeFile();
          if (err) return typeof next === "function" ? next(err) : void 0;
          logger.log('info', "Wrote the file " + fullPath);
          return typeof next === "function" ? next() : void 0;
        });
      });
      return this;
    };

    FileModel.prototype.normalize = function(next) {
      var fullDirPath, relativeDirPath;
      if (!this.filename && this.basename) this.filename = this.basename;
      if (!this.basename && this.filename) this.basename = this.filename;
      if (!this.fullPath && this.basename) this.fullPath = this.basename;
      if (!this.relativePath && this.fullPath) this.relativePath = this.fullPath;
      this.basename = path.basename(this.fullPath);
      this.filename = this.basename;
      this.basename = this.filename.replace(/\..*/, '');
      this.extensions = this.filename.split(/\./g);
      this.extensions.shift();
      this.extension = this.extensions[this.extensions.length - 1];
      this.extensionRendered = this.extensions[0];
      fullDirPath = path.dirname(this.fullPath) || '';
      relativeDirPath = path.dirname(this.relativePath).replace(/^\.$/, '') || '';
      this.relativeBase = relativeDirPath.length ? path.join(relativeDirPath, this.basename) : this.basename;
      this.id = this.relativeBase;
      if (typeof next === "function") next();
      return this;
    };

    FileModel.prototype.contextualize = function(next) {
      var _this = this;
      this.getEve(function(err, eve) {
        if (err) return typeof next === "function" ? next(err) : void 0;
        _this.extensionRendered = eve.extensionRendered;
        _this.filenameRendered = "" + _this.basename + "." + _this.extensionRendered;
        _this.url || (_this.url = "/" + _this.relativeBase + "." + _this.extensionRendered);
        _this.slug || (_this.slug = balUtil.generateSlugSync(_this.relativeBase));
        _this.title || (_this.title = _this.filenameRendered);
        _this.outPath = _this.outDirPath ? path.join(_this.outDirPath, _this.url) : null;
        _this.addUrl(_this.url);
        return typeof next === "function" ? next() : void 0;
      });
      return this;
    };

    FileModel.prototype.getLayout = function(next) {
      var layout;
      layout = this.layout;
      if (!layout) {
        return typeof next === "function" ? next(new Error('This document does not have a layout')) : void 0;
      }
      console.log(layout);
      this.layouts.findOne({
        relativeBase: layout
      }, function(err, layout) {
        if (err) {
          return typeof next === "function" ? next(err) : void 0;
        } else if (!layout) {
          err = new Error("Could not find the layout: " + layout);
          return typeof next === "function" ? next(err) : void 0;
        } else {
          return typeof next === "function" ? next(null, layout) : void 0;
        }
      });
      return this;
    };

    FileModel.prototype.getEve = function(next) {
      if (this.layout) {
        return this.getLayout(function(err, layout) {
          if (err) return typeof next === "function" ? next(err) : void 0;
          return layout.getEve(next);
        });
      } else {
        return typeof next === "function" ? next(null, this) : void 0;
      }
    };

    FileModel.prototype.render = function(templateData, next) {
      var file, finish, logger, renderDocument, renderExtensions, renderLayouts, renderPlugins, rendering, reset,
        _this = this;
      file = this;
      logger = this.logger;
      logger.log('debug', "Rendering the file " + this.relativePath);
      reset = function() {
        file.rendered = false;
        file.content = file.body;
        file.contentRendered = file.body;
        return file.contentRenderedWithoutLayouts = file.body;
      };
      reset();
      rendering = file.body;
      finish = function(err) {
        var _ref;
        if ((_ref = file.type) === 'document' || _ref === 'partial') {
          file.content = file.body;
          file.contentRendered = rendering;
          file.contentRenderedWithoutLayouts = rendering;
          file.rendered = true;
        }
        if (err) return next(err);
        logger.log('debug', "Rendering completed for " + file.relativePath);
        return next(null, rendering);
      };
      renderPlugins = function(file, eventData, next) {
        return file.emitSync(eventData.name, eventData, function(err) {
          if (err) {
            logger.log('warn', 'Something went wrong while rendering:', file.relativePath);
            return next(err);
          }
          return next(err);
        });
      };
      renderLayouts = function(next) {
        if (!file.layout) return next();
        return file.getLayout(function(err, layout) {
          var _ref;
          if (err) return next(err);
          if ((_ref = file.type) === 'document' || _ref === 'partial') {
            file.contentRenderedWithoutLayouts = rendering;
          }
          if (layout) {
            templateData.content = rendering;
            return layout.render(templateData, function(err, result) {
              if (err) return next(err);
              rendering = result;
              return next();
            });
          } else {
            return next();
          }
        });
      };
      renderDocument = function(next) {
        var eventData;
        eventData = {
          name: 'renderDocument',
          extension: file.extensions[0],
          templateData: templateData,
          file: file,
          content: rendering
        };
        return renderPlugins(file, eventData, function(err) {
          if (err) return next(err);
          rendering = eventData.content;
          return next();
        });
      };
      renderExtensions = function(next) {
        var extension, extensions, tasks, _i, _len, _ref;
        if (file.extensions.length <= 1) return next();
        tasks = new balUtil.Group(next);
        extensions = [];
        _ref = file.extensions;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          extension = _ref[_i];
          extensions.unshift(extension);
        }
        _.each(extensions.slice(1), function(extension, index) {
          return tasks.push(function(complete) {
            var eventData;
            eventData = {
              name: 'render',
              inExtension: extensions[index],
              outExtension: extension,
              templateData: templateData,
              file: file,
              content: rendering
            };
            return renderPlugins(file, eventData, function(err) {
              if (err) return complete(err);
              rendering = eventData.content;
              return complete();
            });
          });
        });
        return tasks.sync();
      };
      renderExtensions(function(err) {
        if (err) return finish(err);
        return renderDocument(function(err) {
          if (err) return finish(err);
          return renderLayouts(function(err) {
            return finish(err);
          });
        });
      });
      return this;
    };

    return FileModel;

  })(EventSystem);

  module.exports = FileModel;

}).call(this);
