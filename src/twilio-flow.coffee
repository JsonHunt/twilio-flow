VoiceCall = require('./voice-call')

class TwilioFlow
	bind: (router, app)->
		app.calls = {}
		router.use "/", (req,res,next)->
			try
				# TODO: FOR SECURITY, STOP PROCESSING IF REQUEST DOES NOT CONTAIN VALID ACCOUNT ID
				callId = req.body?.CallSid
				callId ?= 0

				if !app.calls[callId]
					app.calls[callId] = new VoiceCall(app,req)

				call = app.calls[callId]
				call.update(req,res)

				if call.repeat > app.settings.repeat
					methodName = app.settings.noInput
				else
					methodName = req.path.substr(1)

				call.position = methodName

				app[methodName](call)
			catch e
				console.log e
				res.send "Error: " + e

module.exports = new TwilioFlow()
