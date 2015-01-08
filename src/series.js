// Generated by CoffeeScript 1.8.0
module.exports = function(tasks, callback) {
  var next, result;
  tasks = tasks.slice(0);
  next = function(cb) {
    var task;
    if (tasks.length === 0) {
      return cb();
    }
    task = tasks.shift();
    return task(function() {
      return next(cb);
    });
  };
  result = function(cb) {
    return next(cb);
  };
  if (callback != null) {
    result(callback);
  }
  return result;
};