(function(){"use strict";
  var M, _MoveKWArgsT, Text, extend, create, print, repeat, after, JSON, __class, EventEmitter, hello;
  M = Move.runtime, _MoveKWArgsT = M._MoveKWArgsT, Text = M.Text, extend = M.extend, create = M.create, print = M.print, repeat = M.repeat, after = M.after, JSON = M.JSON, __class = M.__class, EventEmitter = M.EventEmitter;
  hello = function hello(name) {
    name !== null && typeof name === "object" && name.__kw === _MoveKWArgsT && (arguments.keywords = name, name = name.name);
    return "Hello " + name;
  };
  return repeat({
    times: 3,
    __kw: _MoveKWArgsT
  })(function () {
    return print(hello({
      name: "John",
      __kw: _MoveKWArgsT
    }));
  });
})();