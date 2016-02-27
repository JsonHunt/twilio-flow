gulp = require 'gulp'

gulp.task 'update-twilio-app', ->
	accountSID: 'sid'
	authToken: 'token'
	app:
		id: "twilioAppID"
		voiceUrl: 'http://myserver/myApp?action=start'

	twilio = require('twilio')(accountSID,authToken)
	twilio.applications(app.id).update app, (err, app)->
		throw err if err
		console.log "Application #{app.friendlyName} was updated."
