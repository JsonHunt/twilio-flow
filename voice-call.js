// Generated by CoffeeScript 1.10.0
(function() {
  var _, xml;

  xml = require('xml');

  _ = require('lodash');

  module.exports = function(call) {
    return {
      clear: function() {
        call.body = [];
        return call.response = {
          Response: call.body
        };
      },
      getInput: function(config) {
        var c, gather, toReturn;
        c = _.assign({}, call.app.inputDefaults, call.script.inputDefaults, config);
        gather = [];
        gather._attr = {
          action: call.app.prefix + "?action=" + call.action + "&onGather=true&attempt=" + (call.attempt + 1),
          numDigits: c.maxDigits,
          timeout: c.timeout
        };
        call.maxAttempts = c.maxAttempts;
        call.onInvalidInput = c.onInvalidInput;
        call.onMaxInvalidInput = c.onMaxInvalidInput;
        call.body.push({
          Gather: gather
        });
        if (c.required === true) {
          c.onMissingInput(call, call.flow);
        }
        toReturn = {
          say: function(prompt, voice) {
            call.flow.say(prompt, voice, gather);
            return this;
          },
          on: function(digits, callback) {
            call.acceptableInputs.push({
              key: digits.toString(),
              callback: callback
            });
            return this;
          },
          onInput: function(callback) {
            call.acceptableInputs.push({
              key: "any",
              callback: callback
            });
            return this;
          }
        };
        return toReturn;
      },
      onResolveInput: (function(_this) {
        return function() {
          var inp, j, len, match, ref;
          console.log("Resolving input " + call.digits);
          console.log("Acceptable:");
          ref = call.acceptableInputs;
          for (j = 0, len = ref.length; j < len; j++) {
            inp = ref[j];
            console.log("" + inp.key);
          }
          match = _.find(call.acceptableInputs, function(i) {
            var ref1;
            return (ref1 = i.key) === call.digits || ref1 === "any";
          });
          if (match) {
            call.acceptableInputs = [];
            if (_.isFunction(match.callback)) {
              return match.callback();
            } else {
              return call.flow.goto(match.callback);
            }
          } else {
            return call.onInvalidInput(call, call.flow);
          }
        };
      })(this),
      recordVoice: function(config) {
        var c;
        if (_.isString(config)) {
          config = {
            onRecording: config
          };
        }
        if (_.isFunction(config)) {
          config = {
            onRecording: config
          };
        }
        c = _.assign({}, call.app.recordDefaults, call.script.recordDefaults, config);
        call.body.push({
          Record: {
            _attr: {
              action: call.app.prefix + "?action=" + call.action + "&onRecord=true&attempt=" + call.attempt,
              timeout: c.timeout
            }
          }
        });
        c.onMissingRecording(call, call.flow);
        call.onResolveRecord = _.isFunction(c.onRecording) ? c.onRecording : call.flow[c.onRecording];
        call.maxAttempts = c.maxAttempts;
        return call.onMaxMissingRecordings = c.onMaxMissingRecordings;
      },
      say: function(text, voice, container) {
        var prompt, ref, toSay;
        if (container === void 0) {
          container = call.body;
        }
        if (voice === void 0) {
          voice = call.app.voice;
        }
        prompt = (ref = this.prompts) != null ? ref[text] : void 0;
        if (prompt === void 0) {
          prompt = text;
        }
        if (prompt.url) {
          return container.push({
            Play: prompt.url
          });
        } else {
          toSay = prompt.text ? prompt.text : prompt;
          return container.push({
            Say: [
              {
                _attr: {
                  voice: voice
                }
              }, toSay
            ]
          });
        }
      },
      play: function(url) {
        return call.body.push({
          Play: url
        });
      },
      setScript: function(name) {
        return call.app.setScript(call, name);
      },
      goTo: function(target, attempt) {
        var redirect;
        redirect = call.app.prefix + "?action=" + target;
        if (attempt) {
          redirect += "&attempt=" + attempt;
        }
        return call.body.push({
          Redirect: redirect
        });
      },
      goto: function(target, attempt) {
        return this.goTo(target, attempt);
      },
      hangup: function() {
        return call.body.push({
          Hangup: ''
        });
      }
    };
  };

}).call(this);
