An unofficial online (real-time, websocket-based) version of [The Resistance](http://boardgamegeek.com/boardgame/41114/the-resistance), the awesome game of social deduction designed by [Don Eskridge](http://boardgamegeek.com/boardgamedesigner/11906/don-eskridge).

Buy the original game, and support the developers! It's an awesome party game, and the art is great! This is just a way to play with people remotely, facilitated by a server to keep track of rounds/voting and Google+ Hangouts to facilitate yelling at each other until your voice is hoarse.

__Dependencies__

* [mongodb](http://www.mongodb.org/)
* [node.js](http://nodejs.org/), and then (from inside the code directory):

		npm install express mongoskin socket.io underscore node-uuid
		sudo npm install -g coffee-script

__Running__

Make sure that the mongo daemon is running, e.g.:

	sudo mongod

And then, from the code directory, run:

	coffee server.coffee
	
Then go to: http://127.0.0.1:2020/

__Demo server__

Try it live at: http://eslgenie.com:2020/