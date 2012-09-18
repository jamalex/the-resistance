"_I_ am a _good person_." -- David

Will the programmers make their project successful in the face of secret saboteurs? Play today to find out!

__Dependencies__

* [mongodb](http://www.mongodb.org/)
* [node.js](http://nodejs.org/), and then (from inside the code directory):

		npm install express mongoskin socket.io underscore
		sudo npm install -g coffee-script

__Running__

Make sure that the mongo daemon is running, e.g.:

	sudo mongod

And then, from the code directory, run:

	coffee server.coffee
	
Then go to: http://127.0.0.1:2020/