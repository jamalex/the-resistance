http = require("http")
fs = require("fs")
express = require("express")
crypto = require("crypto")
mongoskin = require("mongoskin")
db = mongoskin.db("localhost/david?auto_reconnect")

games = db.collection("games")
names = db.collection("names")

app = express(
    express.cookieParser(),
    express.session(),
)

app.use "/static", express.static(__dirname + "/static")

app.get "/", (request, response) ->
  fs.readFile __dirname + "/static/index.html", (err, text) ->
      response.end text

app.get "/game/:gameid", (request, response) ->
  fs.readFile __dirname + "/static/game.html", (err, text) ->
      response.end text

server = http.createServer(app)
io = require("socket.io").listen(server)

hash = (msg) -> crypto.createHash('md5').update(msg).digest("hex")

roomvisitors = {}

loadGameData = (data, callback) ->
    games.findOne _id: new db.ObjectID(data.gameid), (err, obj) ->
        if err
            console.error "Error loading game:", err
            return
        if not obj
            console.error "Game not found:", data
            return
        callback err, obj

saveGameData = (obj) ->
    games.save obj

# handle the creation of a new socket (i.e. a new browser connecting)
io.sockets.on "connection", (socket) ->
    
    socket.session = ""
    socket.name = "Guest" + Math.random().toString()[3..7]
    socket.rooms = io.sockets.manager.roomClients[socket.id]
    
    sendGameData = (obj, sockets) ->
        if obj not instanceof Object
            return
        if not sockets
            sockets = io.sockets.clients(obj._id.toString())
        if sockets not instanceof Array
            sockets = [sockets]
        for s in sockets            
            data = started: obj.started, players: obj.players, rounds: obj.rounds
            if s.session in (obj.badpeople or [])
                data.badpeople = obj.badpeople
            s.emit "gamedata", data
    
    # handle incoming "msg" events, and emit them back out to all connected clients
    socket.on "msg", (data) ->
        if data.message[0...35] is "https://plus.google.com/hangouts/_/"
            games.save _id: new db.ObjectID(data.gameid), hangoutUrl: data.message
            io.sockets.in(data.gameid).emit "hangout", url: data.message
        else
            message = "<b>" + socket.name + ":</b> " + data.message
            io.sockets.in(data.gameid).emit "msg", message

    socket.on "session", (data) ->
        console.log data
        socket.session = hash(data.sessionid)
        names.findOne _id: socket.session, (err, obj) ->
            if obj?.name
                socket.name = obj.name
            else
                names.save _id: socket.session, name: socket.name
            socket.emit "name", session: socket.session, name: socket.name

    socket.on "changename", (data) ->
        socket.name = data.name
        names.save _id: socket.session, name: socket.name
        for room of socket.rooms
            if room and socket.rooms[room]
                gameid = room[1..]
                updateObj = {$set: {}}
                updateObj["visitors." + socket.session] = socket.name
                games.update {_id: gameid}, updateObj
                io.sockets.in(gameid).emit "name", session: socket.session, name: socket.name

    socket.on "creategame", ->
        games.save {}, (err, obj) ->
            socket.emit "showgame", obj._id

    socket.on "joingame", (data) ->
        loadGameData data, (err, obj) ->
            obj.visitors or= {}
            obj.visitors[socket.session] = socket.name
            io.sockets.in(data.gameid).emit "visitorjoined", session: socket.session, name: socket.name
            socket.join(data.gameid)
            # send all the cached game data to the client, to initialize it
            for s, n of obj.visitors
                socket.emit "visitorjoined", session: s, name: n
            if obj.hangoutUrl
                socket.emit "hangout", url: obj.hangoutUrl
            sendGameData obj, socket
            saveGameData obj
                
    socket.on "startgame", (data) ->
        loadGameData data, (err, obj) ->
            if obj.started
                return
            obj.started = true
            obj.players = [{session: s, name: n} for s, n of obj.visitors]
            saveGameData obj
    
    socket.on "disconnect", ->
        for room of socket.rooms
            if room and socket.rooms[room]
                gameid = room[1..]
                # delete roomvisitors[gameid]?[socket.session]
                updateObj = {$unset: {}}
                updateObj["visitors." + socket.session] = 1
                games.update {_id: gameid}, updateObj
                io.sockets.in(gameid).emit "visitorleft", session: socket.session, name: socket.name
            
    

server.listen 2020