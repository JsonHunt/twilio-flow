express = require 'express'
tFlow = require './voice-call'
Promise = require 'bluebird'
xml = require 'xml'
_ = require 'lodash'
di = require './../di'

get = (req,value) ->
	if req.body?[value]?
		return req.body[value]
	if req.query?[value]?
		return req.query[value]

module.exports = ()->
	app =
		calls: {}
		scripts: {}
		voice: 'male'

		log: (call)->
			console.log call.body
			console.log "Input: #{call.digits}" if call.digits

		onError: (call,error)->
			console.log error
			flow = call.flow
			flow.clear()
			flow.say 'We are sorry, an error has occurred. This call will now be disconnected.'
			flow.hangup()

		inputDefaults:
			timeout: 10
			maxDigits: 1
			maxAttempts: 3
			required: true

			onMissingInput:  (call,flow)->
				flow.say "Sorry, I didn't get that"
				flow.goto call.action, call.attempt+1

			onInvalidInput: (call,flow)->
				flow.say "That was not a valid entry"
				flow.goto call.action, call.attempt+1

			onMaxInvalidInput: (call,flow)->
				flow.say "Due to lack of input, this call will now be disconnected. Goodbye"
				flow.hangup()

		recordDefaults:
			timeout: 10
			maxAttempts: 3
			required: true

			onMissingRecording: (call,flow)->
				flow.say "Sorry, I didn't get that. Please try again louder"
				flow.goto call.action, call.attempt+1

			onMaxMissingRecordings: (call,flow)->
				flow.say "Due to lack of voice input, this call will now be disconnected. Goodbye"
				flow.hangup()

	app.router = express.Router()

	app.createCall = (id, req)->
		console.log "New Call #{id}"
		call =
			id: id
			from: get req, 'From'
			to: get req, 'To'
			direction: get req, 'Direction'
			time_started: new Date()
			caller_id: get req, 'CallerName'
			acceptableInputs: []
			fromCity:	get req, 'FromCity'
			fromState: get req, 'FromState'
			fromZip: get req, 'FromZip'
			fromCountry: get req, 'FromCountry'
			toCity: get req, 'ToCity'
			toState: get req, 'ToState'
			toZip: get req, 'ToZip'
			toCountry: get req, 'ToCountry'
			answeredBy: get req, 'AnsweredBy'

		call.flow = tFlow call
		call.app = app
		app.calls[id] = call
		return call

	app.updateCall = (call, req)->
		call.attempt = get req, 'attempt'
		call.attempt ?= 0
		call.attempt = parseInt call.attempt
		call.action = get req, 'action'
		call.recordingURL = get req, 'RecordingUrl'
		call.recordingID = get req, 'RecordingSid'
		call.recordingDuration = get req, 'RecordingDuration'
		call.digits = get req, 'Digits'
		call.status = get req, 'CallStatus'
		call.duration = get req, 'CallDuration'
		call.outerBody = undefined
		call.body = []
		call.response = {Response: call.body}

		scriptName = get req, 'script'
		app.setScript call,scriptName

	app.setScript = (call,scriptName)->
		if scriptName
			call.scriptName = scriptName
		if call.scriptName is undefined
			call.scriptName = app.defaultScript

		scriptPath = app.scripts[call.scriptName]
		if call.script is undefined or app.testMode is true
			try
				delete require.cache[require.resolve(scriptPath)]
			catch err
				console.log "Unable to delete require cache: #{err}"
			call.script = require(scriptPath)(call,call.flow)

	app.loadPrompts = (call)-> di.model.Prompts.findAll()

	app.router.use "/", (req,res)->
		if app.defaultScript is undefined
			for key,value of app.scripts
				app.defaultScript = key
				break

		Promise.resolve().then ()->
			callId = req.body.CallSid
			callId ?= 0 if callId is undefined and app.testMode is true
			throw "Invalid request" if callId is undefined
			call = app.calls[callId]
			if call is undefined
				return app.createCall(callId,req)
			else
				return call
		.then (call)->
			app.updateCall(call,req)
			Promise.resolve().then ()->
				if call.flow.prompts is undefined or app.testMode is true
					Promise.resolve(app.loadPrompts(call)).then (prompts)->
						call.flow.prompts = {}
						prompts.forEach (p)-> call.flow.prompts[p.text] = p
			.then ()->
				if req.query?.onGather
					if call.attempt > call.maxAttempts
						return call.onMaxInvalidInput call, call.flow
					else
						return call.flow.onResolveInput()
				else if req.query?.onRecord
					if call.attempt > call.maxAttempts
						return call.onMaxMissingRecordings call, call.flow
					else
						return call.onResolveRecord()
				else
					return call.script[call.action]()
			.catch (err)->
				app.onError call, err
			.then ()-> app.log call if app.log
			.then ()->
				xres = xml call.response, {declaration: {encoding: 'UTF-8'}}
				res.set('Content-Type', 'text/xml')
				res.send xres

	return app
