fs = require 'fs'

module.exports = (dir, current, callback) ->
  a = {}
  d = {}
  m = {}
  u = {}
  
  pool = {}
  pool[key] = value for key, value of current
  
  try
    items = fs.readdirSync dir
  catch e
    console.error "Could not open directory #{dir}"
    # Default for errors - no changes
    return callback a, d, m, pool
  
  for item in items
    continue if !item.match /\.js$/
    path = "#{dir}/#{item}"
    stat = fs.statSync path
    
    if pool[item]?
      # If the file is newer it has been modified
      if pool[item].changed < stat.mtime.getTime()
        m[item] = path: path, changed: stat.mtime.getTime()
      else
        u[item] = path: path, changed: stat.mtime.getTime()
      delete pool[item]
    else
      a[item] = path: path, changed: stat.mtime.getTime()
  
  # Anything left over is deleted
  d[key] = value for key, value of pool
  
  callback a, d, m, u