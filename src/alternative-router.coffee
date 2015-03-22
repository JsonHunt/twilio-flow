xml = require 'xml'
request = require 'request'
pool = require('./../dbpool').pool
_ = require 'underscore'
cson = require 'cson'
express = require('express')

router = express.Router()



output = (res, x)->
	xres = xml x,
		declaration:
			encoding: 'UTF-8'
	res.set('Content-Type', 'text/xml')
	console.log xres
	res.send xres

get = (req,value) ->
	if req.body?[value]?
		return req.body[value]
	if req.query?[value]?
		return req.query[value]

dupa =
	app: {}
	call: {}

	query: (callID, sql, params, select, callback)->
		app = @app
		call = @call[callID]
		pool.query sql,params, (err,result)->
			if sql.indexOf('SELECT') isnt -1
				if sql.indexOf('LIMIT 1') isnt -1
					expr = "#{select} = result[0]"
				else
					expr "#{select} = result"
				console.log "Executing: " + expr
				eval expr
			if callback
				callback()

	if: (callID, step)->
		try
			app = @app
			call = @call[callID]
			return eval(step.if)
		catch e
			console.log "Unable to evaluate IF condition '#{step.if}' " + e
			return false

	getPlay: (callID, body, step)->
		try
			app = @app
			call = @call[callID]
			if step.loop
				for item,index in eval(step.loop)
					expr = eval(step.play)
					body.push {Play: expr}
			else
				expr = eval(step.play)
				body.push {Play: expr}
		catch e
			console.log "Unable to evaluate PLAY url '#{expr}' " + e

	getSay: (callID, body, step)->
		try
			app = @app
			call = @call[callID]
			if step.loop
				for item,index in eval(step.loop)
					@doSay app,call,body,step,@voice,item,index
			else
				@doSay app,call,body,step,@voice
		catch e
			console.log "Unable to evaluate SAY '#{step.say}' " + e

	doSay: (app,call,body,step,voice,item,index)->
		expr = step.say
		expr = expr.replace /{(.*?)}/gi, (x,p1)=> eval(p1)
		body.push
			Say: expr
			_attr:
				voice: voice

	execute: (callID, body, step)->
		app = @app
		call = @call[callID]
		if step.loop
			for item,index in eval(step.loop)
				@executeExpr app,call,step,item,index
		else
			@executeExpr app,call,step

	executeExpr: (app,call,step,item,index)->
		expr = step.execute
		# expr = expr.replace /{(.*?)}/gi, (x,p1)=> eval(p1)
		if _.isFunction(@logic[expr])
			try
				@logic[expr](app,call)
			catch e
				console.log "Unable to execute function 'logic.#{expr}(app,call)' " + e
		else
			expr
			try
				eval(expr)
			catch e
				console.log "Unable to execute expression '#{expr}' " + e

# module.exports.loadDesign = (router,design)->
# 	router.use "/", (req,res,next)->

mode = "dev"
if mode is "prod"
	design = cson.parseCSFile('./src/voice/design.cson')
	dupa.voice = design.voice
	dupa.logic = require './logic'

router.use "/", (req,res,next)->
	# FOR SECURITY, STOP PROCESSING IF REQUEST DOES NOT CONTAIN VALID ACCOUNT ID

	if mode is "dev"
		design = cson.parseCSFile('./src/voice/design.cson')
		if (typeof design is Error)
			console.log design
		delete require.cache[require.resolve('./logic')]
		dupa.voice = design.voice
		dupa.logic = require './logic'
		console.log "Reloaded design and logic. Using #{dupa.voice} voice"

	callID = get req, 'CallSid'
	callID ?= "0"
	repeat = get req, 'repeat'
	repeat ?= 0

	dupa.call[callID] ?= {}
	dupa.call[callID].callID = callID
	dupa.call[callID].repeat = repeat
	dupa.call[callID].digits = get req, 'Digits'
	dupa.call[callID].from = get req, 'From'
	dupa.call[callID].to = get req, 'To'
	dupa.call[callID].status = get req, 'CallStatus'
	dupa.call[callID].direction = get req, 'Direction'

	if get(req,'RecordingUrl')
		dupa.call[callID].recording =
			url: get req, 'RecordingUrl'
			duration: get req, 'RecordingDuration'

	id = req.path.substr(1)
	block = design.blocks[id]
	if !block
		res.send 'Invalid request'
		return

	if repeat > design.repeat
		block = design.blocks[design.noinput]

	body = []
	resp = {Response: body}

	if block.input
		menu = []
		menu._attr =
			action: block.input
			numDigits: block.maxinput
			timeout: design.timeout
		body.push {Gather: menu}
		body.push {Redirect: "#{id}?repeat=#{parseInt(repeat)+1}"}
		body = menu

	actions = []
	for step in block.steps
		if step.if
			if !dupa.if(callID,step)
				continue
		# if step.sql
		# 	dupa.query(callID,step)
		if step.execute
			dupa.execute(callID,step)
		if step.say
			dupa.getSay(callID,body,step)
		if step.play
			dupa.getPlay(callID,body,step)
		if step.hangup
			body.push {Hangup:''}
		if step.goto
			body.push {Redirect: step.goto}

	if !block.input and block.recorded
		body.push
			Record:
				_attr:
					action: block.recorded
					timeout: 10
		body.push
			Redirect: "#{id}?repeat=#{parseInt(repeat)+1}"

	output res, resp


module.exports = router
