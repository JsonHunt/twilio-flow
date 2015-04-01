VoiceCall = require './../gen/voice-call'

app =
	settings:
		voice: 'alice'

req = {}
res =
	send: (text)->
		@text = text
	set: (a,b)->


describe 'Generated XML', ()=>
	it 'has proper voice', ()=>
		call = new VoiceCall(app,res)
		call.update(req,res)
		call.say "This is a test"
		call.go()
		console.log res.text

	it 'has proper timeout', ()=>
		call = new VoiceCall(app,res)
		call.update(req,res)
		call.acceptInput 1,'dupa'
		call.setTimeout 200
		call.say "This is dupa"
		call.go()
		console.log res.text

	it 'respects required flag', ()=>
		call = new VoiceCall(app,res)
		call.update(req,res)
		call.acceptInput 1,'dupa',false
		call.setTimeout 200
		call.say "This is dupa"
		call.go()
		console.log res.text

	it 'puts go instructions outside of Gather tag', ()=>
		call = new VoiceCall(app,res)
		call.update(req,res)
		call.acceptInput 1,'dupa',false
		call.setTimeout 200
		call.say "This is dupa"
		call.goTo 'someplace else'
		console.log res.text
