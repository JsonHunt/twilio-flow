## Twilio Flow
#### Helper library for rapid development of interactive voice systems using Twilio

### Installation using NPM

npm install twilio-flow --save

### Twilio configuration
1. Create a Twilio account
2. Purchase a number
3. Configure an app
4. Update gulpfile with your account info, twilio app ID and your app URL
5. Run gulp update-twilio-app

## How to write your voice scripts (example in CoffeeScript)
```
script1 = (call,flow)->
	start: ->
		flow.say "welcome back" if call.skipGreeting isnt true
		flow.getInput()
		.say 'select an option from the menu'
		.say 'press 1 for hours'
		.say 'press 2 for locations'
		.say 'press 3 for a song'
		.on 1, ->
			controller.checkIfOpen().then (isOpen)->
				flow.say 'We are currently closed' if isOpen is false
				flow.say 'We are open till 6 P.M.' if isOpen is true
				call.skipGreeting = true
				flow.goto 'start'
		.on "2", 'locations'
		.on "3", ->
			flow.setScript 'anotherScript'
			flow.goto 'beginning'

	locations: ->
		controller.getLocations().each (location)-> flow.say location
		.then ()->
			flow.getInput()
			.say 'Press any key to record a song'
			.onInput 'recordSong'

	recordSong: ->
		flow.recordVoice ->
			flow.say 'ok, you recorded this'
			flow.play call.recordingURL
			flow.say 'good job!'
			flow.hangup()


script2 = (call,flow)->
	beginning: ->
		flow.say 'separate script'
		flow.getInput {maxDigits:3,timeout:5,required:false}
		.onInput -> flow.hangup()
		.onMissingInput -> flow.say 'no problem, lets continue'
```

## How to use with your Express app (example in CoffeeScript)
```
TwilioFlowApp = require 'twilio-flow'

ivrApp = new TwilioFlowApp()
ivrApp.scripts =
	startScript: script1
	anotherScript: script2

ivrApp.appPrefix = 'myIvrAppPath'
ivrApp.loadPrompts = ()->
	samplePrompts = [
		{text: 'welcome back', url: 'http://pathToAudioFile.mp3'}
		{text: 'goodbye', url: 'http://pathToAudioFile.wav'}
	]
	return samplePrompts

expressApp.use '/myIvrAppPath', ivrApp.router

```
## API

#### app.scripts
An array of scripts defining the flow of the call.

#### app.appPrefix
The URL prefix of the application

#### app.loadPrompts
Function that returns a list of prompts for the purpose of replacing TTS with human voice.

#### app.log
Function that can be defined to log the progress of each call

#### app.onError
Function that can be defined to handle errors during script execution.
By default it logs the error to the console and informs the user that an
error has occurred

#### app.inputDefaults
Default configuration for flow.getInput. Can also be specified on the script.

#### app.recordDefaults
Default configuration for flow.recordVoice. Can also be specified on the script.

## Inside script files
Your scripts should module.export a function call with two parameters: call and flow.

### call
call stores current state of the phonecall, including variables set by you, as well as data passed in by Twilio API. Depending on the actions taken, the following properties may be available on the call object:
```
id
from
to
direction
time_started
caller_id
acceptableInputs
fromCity
fromState
fromZip
fromCountry
toCity
toState
toZip
toCountry
answeredBy
flow
app
attempt
action
body
status
```
Available following getInput:
```
digits
```
Available following recordVoice:
```
recordingURL
recordingID
recordingDuration
duration
```

### flow
flow contains methods that allow you to define the behavior of your script.

#### flow.say text, voice
Reads text using Twilio TTS engine and specified voice. If voice is omitted, will use voice configured for the app (man by default).
If a prompt with matching text property and a url exists in the list, it will play the audio file instead of using TTS.

#### flow.play url
Plays audio file at the given url.

#### flow.getInput config
Used to accept input from user. Config is an object, and accepts following properties:

```maxDigits``` - maximum number of keypresses to accept (default 1)

```timeout``` - how long to wait for input (default 10 seconds)

```maxAttempts``` - how many times invalid or missing input is tolerated (default 2)

```onInvalidInput``` - function to call when invalid input is provided

```onMaxInvalidInput``` - function to call when invalid or missing input is detected too many times

```required``` - is input expected (default true)

```onMissingInput``` - function to call when input is missing

Properties not specified in config will inherit their value from inputDefaults property defined on the script or app object.

**flow.getInput(...)** returns an object with four methods:

```input.say text,voice``` - like flow.say, except pressing keys will interrupt the prompt

```input.play url``` - like flow.play, but pressing keys will interrupt

```input.on input, action``` - when this input is detected, call the action method.
Action can be a function, or a name of a function defined in the script

```input.onInput action``` - like input.on but accepts any input

#### flow.recordVoice config
Used for recording audio. Config can be a function or name of a function to call when recording is complete, or an object with following properties:

```onRecording``` - function or name of a function to call when recording is complete

```timeout``` - how long to wait for voice

```maxAttempts``` - how many times to tolerate silence

```onMissingRecording``` - function to call when only silence is detected for the timeout period during recording

```onMaxMissingRecordings``` - function to call when silent too many times

#### flow.goTo destination, attempt
Used to navigate to another point in the same script. Destination can be a function or a name of a function defined in the script. Attempt is optional

#### flow.setScript scriptName
Used to direct call execution to another script. Scripts are a way to break up an application into functional pieces.

#### flow.hangup()
Used to disconnect the call

#### flow.clear
Used to remove whatever actions were added to current interaction
