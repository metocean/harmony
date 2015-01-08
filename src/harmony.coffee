dirdiff = require './dirdiff'
require_raw = require './require_raw'
Redwire = require 'redwire'
series = require './series'

# Copy all of the properties on source to target, recurse if an object
copy = (source, target) ->
  for key, value of source
    if typeof value is 'object'
      target[key] = {} if !target[key]? or typeof target[key] isnt 'object'
      copy value, target[key]
    else
      target[key] = value

module.exports = class Harmony
  constructor: (options) ->
    @_options =
      configdir: process.cwd()
      refresh: no
    copy options, @_options
    
    @config = {}
    @redwires = {}
    
    @tick()
    
    noop = ->
    # Stay alive even with nothing listening
    @_interval = if @_options.refresh
      setInterval @tick, @_options.refresh
    else
      setInterval noop, 60000
  
  error: (error) =>
    if error.stack?
      console.error error.stack
    else
      console.error error
  
  tick: => dirdiff @_options.configdir, @config, @update
  
  update: (added, removed, modified, unchanged) =>
    for key, value of removed
      delete @config[key]
      @unload key
    for key, value of modified
      @config[key] = value
      @transfer key
    for key, value of added
      @config[key] = value
      @load key
  
  create: (key) =>
    console.log "Creating #{key}..."
    item = @redwires[key].item
    if !item.config.log?
      item.config.log = {}
    item.config.log.notice = (message) ->
        console.log message
    redwire = new Redwire item.config
    @redwires[key].redwire = redwire
    @bind key
  
  bind: (key) =>
    console.log "Binding #{key}..."
    { item, redwire } = @redwires[key]
    bindings = redwire.createNewBindings()
    item.bind redwire, bindings
    redwire.setBindings bindings
  
  load: (key) =>
    console.log "Loading #{key}..."
    try
      item = require_raw "#{@_options.configdir}/#{key}"
      @redwires[key] = item: item
      @create key
    catch e
      delete @config[key]
      return @error e
  
  transfer: (key) =>
    try
      item = require_raw "#{@_options.configdir}/#{key}"
    catch e
      return @error e
    
    # Configuration different, need to unload and load
    if JSON.stringify(@redwires[key].item.config) isnt JSON.stringify(item.config)
      console.log "Reloading #{key}..."
      @unload key
      @redwires[key] = item: item
      @create key
      return
    
    console.log "Migrating #{key}..."
    @redwires[key].item.end() if @redwires[key].item.end?
    @redwires[key].item = item
    @bind key
  
  unload: (key) =>
    console.log "Unloading #{key}..."
    { item, redwire } = @redwires[key]
    item.end() if item.end?
    redwire.close()
    delete @redwires[key]
  
  close: =>
    clearInterval @_interval
    for _, item of @redwires
      item.item.end() if item.item.end?
      item.redwire.close()