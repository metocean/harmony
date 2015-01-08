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
    keystocreate = []
    
    for key, value of removed
      console.log "Deleting #{key}..."
      delete @config[key]
      @unload key
    
    for key, value of modified
      def = @read key
      continue if !def?
      @config[key] = value
      
      # Configuration different, need to recreate
      source = JSON.stringify @redwires[key].def.config
      target = JSON.stringify def.config
      if source isnt target
        console.log "#{source} isnt #{target}"
        console.log "Recreating #{key}..."
        @unload key
        @redwires[key] = def: def
        keystocreate.push key
        continue
      
      console.log "Migrating #{key}..."
      @redwires[key].def.end() if @redwires[key].def.end?
      @redwires[key].def = def
      @bind key
    
    for key, value of added
      def = @read key
      continue if !def?
      @config[key] = value
      @redwires[key] = def: def
      console.log "Creating #{key}..."
      keystocreate.push key
    
    # create everything last so conflicts don't occur
    @create key for key in keystocreate
  
  read: (key) =>
    try
      return require_raw "#{@_options.configdir}/#{key}"
    catch e
      @error e
      return null
  
  create: (key) =>
    def = @redwires[key].def
    # Copy configuration so we can modify it and still compare
    config = {}
    config[k] = v for k, v of def.config
    config.log = {} if !config.log?
    config.log.notice = (message) -> console.log message
    redwire = new Redwire config
    @redwires[key].redwire = redwire
    @bind key
  
  bind: (key) =>
    { def, redwire } = @redwires[key]
    bindings = redwire.createNewBindings()
    def.bind redwire, bindings
    redwire.setBindings bindings
  
  unload: (key) =>
    { def, redwire } = @redwires[key]
    def.end() if def.end?
    redwire.close()
    delete @redwires[key]
  
  close: =>
    clearInterval @_interval
    for _, def of @redwires
      def.def.end() if def.def.end?
      def.redwire.close()