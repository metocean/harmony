module.exports =
  config: http: port: 8888
  bind: (redwire, bindings) ->
    bindings
      .http 'http://localhost:8888/'
      .use (mount, url, req, res, next) ->
        res.write 'OK'
        res.end()

