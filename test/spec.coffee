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
