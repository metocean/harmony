Harmony = require '../src/harmony'
harmony = new Harmony()
process.on 'SIGHUP', harmony.tick
process.on 'uncaughtException', (err) ->
    console.error err
    process.exit 1