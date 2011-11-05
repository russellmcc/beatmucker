#~readme.out~
## oscroute
#
# _Simple node.js OSC router_

express = require 'express'


# Now, start up the UI server:
console.log __dirname
uiPort = 8214
uiServer = express.createServer()
uiServer.use express.static(__dirname + "/")
uiServer.listen uiPort
console.log "Started connect Server on port " + uiPort