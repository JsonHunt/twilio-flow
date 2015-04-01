xml = require 'xml'

class VoiceCall
	constructor:(@app,req)->
		@id = @get req, 'CallSid'
		@id ?= 0
		@from = @get req, 'From'
		@to = @get req, 'To'
		@direction = @get req, 'Direction'
		@time_started = new Date()
		@caller_id = @get req, 'CallerName'

		@fromCity =	@get req, 'FromCity'
		@fromState = @get req, 'FromState'
		@fromZip = @get req, 'FromZip'
		@fromCountry = @get req, 'FromCountry'
		@toCity = @get req, 'ToCity'
		@toState = @get req, 'ToState'
		@toZip = @get req, 'ToZip'
		@toCountry = @get req, 'ToCountry'

	output: (res, x)->
		xres = xml x,
			declaration:
				encoding: 'UTF-8'
		res.set('Content-Type', 'text/xml')
		res.send xres

	get: (req,value) ->
		if req.body?[value]?
			return req.body[value]
		if req.query?[value]?
			return req.query[value]

	update: (req,res)->
		@repeat = @get req, 'repeat'
		@repeat ?= 0
		@recordingURL = @get req, 'RecordingUrl'
		@recordingID = @get req, 'RecordingSid'
		@recordingDuration = @get req, 'RecordingDuration'
		@digits = @get req, 'Digits'
		@status = @get req, 'CallStatus'
		@duration = @get req, 'CallDuration'
		@body = []
		@response = {Response: @body}
		@res = res

	acceptInput: (maxDigits, target)->
		gather = []
		gather._attr =
			action: target
			numDigits: maxDigits
			timeout: @app.settings.timeout
		@body.push {Gather: gather}
		next = parseInt(@repeat)+1
		@body.push {Say: @app.settings.noInputMessage}
		@body.push {Redirect: "#{@position}?repeat=#{next}"}
		@body = gather

	recordSound: (target)->
		@body.push
			Record:
				_attr:
					action: target
					timeout: @app.settings.timeout
		next = parseInt(@repeat)+1
		@body.push
			Say: @app.settings.noInputMessage
		@body.push
			Redirect: "#{@position}?repeat=#{next}"
		@go()

	say: (prompt,voice)->
		if !voice
			voice = @app.settings.voice

		if prompt.url
			@body.push {Play: prompt.url}
		else
			toSay = if prompt.text then prompt.text else prompt
			@body.push
				Say: [
					_attr:
						voice: voice
					, toSay
				]

	play: (url)->
		@body.push {Play: url}

	go: ()->
		@output(@res, @response)

	goTo: (target)->
		@body.push {Redirect: target}
		@go()

	goto: (target)->
		@goTo target

	hangup: ()->
		@body.push {Hangup:''}
		@go()

module.exports = VoiceCall
