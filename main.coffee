require ["Audiolet"], (AudioLetLib) -> # AudioLet pollutes globally
  Synth = (audiolet, freq) ->
    AudioletGroup.apply @, [audiolet, 0, 1]
    @sine = new Sine @audiolet, freq
    @modulator = new Saw @audiolet, 2.1 * freq
    @modulatorMulAdd = new MulAdd @audiolet, 200, freq
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 1, .2, .5, =>
        @audiolet.scheduler.addRelative 0, @.remove.bind(@)
    
    @modulator.connect @modulatorMulAdd
    @modulatorMulAdd.connect @sine
    @envelope.connect @gain, 0, 1
    @sine.connect @gain
    @gain.connect @outputs[0]

  extend Synth, AudioletGroup
  
  frequencyPattern = new PSequence [262, 262, 392, 392], Infinity
  
  $(document).click ->
    frequencyPattern.list[1] += 10
  
  AudioletApp = =>
    @audiolet = new Audiolet()
    frequencyPattern = new PSequence [262, 262, 392, 392], Infinity
    @audiolet.scheduler.play [frequencyPattern], 1, (frequency) =>
      synth = new Synth @audiolet, frequency
      synth.connect @audiolet.output
    
  @audioletApp = new AudioletApp()