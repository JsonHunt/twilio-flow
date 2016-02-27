xml = require 'xml'
_ = require 'lodash'

module.exports = (call)->

	clear: ->
		call.body = []
		call.response = {Response: call.body}

	getInput: (config)->
		c = _.assign {}, call.app.inputDefaults, call.script.inputDefaults, config
		gather = []
		gather._attr =
			action: "#{call.app.prefix}?action=#{call.action}&onGather=true&attempt=#{call.attempt+1}"
			numDigits: c.maxDigits
			timeout: c.timeout
		call.maxAttempts = c.maxAttempts
		call.onInvalidInput = c.onInvalidInput
		call.onMaxInvalidInput = c.onMaxInvalidInput
		call.body.push {Gather: gather}
		if c.required is true
			c.onMissingInput call,call.flow

		toReturn =
			say: (prompt,voice)-> call.flow.say(prompt,voice,gather); return @
			on: (digits, callback)->
				call.acceptableInputs.push {key: digits.toString(), callback: callback}
				return @

			onInput: (callback)->
				call.acceptableInputs.push {key: "any", callback: callback}
				return @

		return toReturn

	onResolveInput: ()=>
		console.log "Resolving input #{call.digits}"
		console.log "Acceptable:"
		for inp in call.acceptableInputs
			console.log "#{inp.key}"
		match = _.find call.acceptableInputs, (i)=> i.key in [call.digits,"any"]
		if match
			call.acceptableInputs = []
			if _.isFunction match.callback
				match.callback()
			else
				call.flow.goto match.callback
		else
			call.onInvalidInput call, call.flow

	recordVoice: (config)->
		if _.isString config
			config = {onRecording: config}
		if _.isFunction config
			config = {onRecording: config}
		c = _.assign {}, call.app.recordDefaults, call.script.recordDefaults, config
		call.body.push
			Record:
				_attr:
					action: "#{call.app.prefix}?action=#{call.action}&onRecord=true&attempt=#{call.attempt}"
					timeout: c.timeout

		c.onMissingRecording call,call.flow
		call.onResolveRecord = if _.isFunction c.onRecording then c.onRecording else call.flow[c.onRecording]
		call.maxAttempts = c.maxAttempts
		call.onMaxMissingRecordings = c.onMaxMissingRecordings

	say: (text,voice,container)->
		if container is undefined
			container = call.body
		if voice is undefined
			voice = call.app.voice

		prompt = @prompts?[text]
		if prompt is undefined
			prompt = text

		if prompt.url
			container.push {Play: prompt.url}
		else
			toSay = if prompt.text then prompt.text else prompt
			container.push
				Say: [
					_attr:
						voice: voice
					, toSay
				]
		# container.push {Pause:''}

	play: (url)-> call.body.push {Play: url}

	setScript: (name)-> call.app.setScript call, name

	goTo: (target,attempt)->
		redirect = "#{call.app.prefix}?action=#{target}"
		redirect += "&attempt=#{attempt}" if attempt
		call.body.push {Redirect: redirect}

	goto: (target, attempt)-> @goTo target, attempt

	hangup: ()-> call.body.push {Hangup:''}
