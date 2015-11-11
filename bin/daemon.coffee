Harmony = require '../src/harmony'
harmony = new Harmony()
process.on 'SIGHUP', harmony.tick