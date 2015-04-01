// Generated by CoffeeScript 1.9.1
(function() {
  var VoiceCall, app, req, res;

  VoiceCall = require('./../gen/voice-call');

  app = {
    settings: {
      voice: 'alice'
    }
  };

  req = {};

  res = {
    send: function(text) {
      return this.text = text;
    },
    set: function(a, b) {}
  };

  describe('Generated XML', (function(_this) {
    return function() {
      it('has proper voice', function() {
        var call;
        call = new VoiceCall(app, res);
        call.update(req, res);
        call.say("This is a test");
        call.go();
        return console.log(res.text);
      });
      it('has proper timeout', function() {
        var call;
        call = new VoiceCall(app, res);
        call.update(req, res);
        call.acceptInput(1, 'dupa');
        call.setTimeout(200);
        call.say("This is dupa");
        call.go();
        return console.log(res.text);
      });
      it('respects required flag', function() {
        var call;
        call = new VoiceCall(app, res);
        call.update(req, res);
        call.acceptInput(1, 'dupa', false);
        call.setTimeout(200);
        call.say("This is dupa");
        call.go();
        return console.log(res.text);
      });
      return it('puts go instructions outside of Gather tag', function() {
        var call;
        call = new VoiceCall(app, res);
        call.update(req, res);
        call.acceptInput(1, 'dupa', false);
        call.setTimeout(200);
        call.say("This is dupa");
        call.goTo('someplace else');
        return console.log(res.text);
      });
    };
  })(this));

}).call(this);
