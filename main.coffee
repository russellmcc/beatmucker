cWidth = 700
cHeight = 300
barLinesStyle = 'rgb(0,200,0)'
delayLineStyle = 'rgb(0,0,200)'
bgStyle = 'rgb(200,0,0)'

require ["Audiolet", "audiofile"], (AudioLetLib, audiofilelib) -> # AudioLet pollutes globally

  # My stupid synth.
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
  
  bpm = 138
  
  # beats/samples utils
  beatsToSeconds = (beats) -> beats / bpm * 60
  secondsToSamples = (audiolet, seconds) -> 
    Math.floor(seconds * audiolet.device.sampleRate)
  beatsToSamples = (audiolet, beats) -> 
    secondsToSamples audiolet, (beatsToSeconds beats)
  secondsToBeats = (seconds) -> seconds * bpm / 60
  samplesToSeconds = (audiolet, samples) ->
    samples / audiolet.device.sampleRate
  samplesToBeats = (audiolet, samples) ->
    secondsToBeats (samplesToSeconds audiolet, samples)
  
  # this buffer holds the sample.
  amen = new AudioletBuffer 1, 0
  amen.load 'audio/amen.wav', false
  
  # this buffer holds the delay.
  delayBuff = new AudioletBuffer 1, amen.length
  
  # maximum delay in seconds
  maxDelay = (beatsToSeconds 8)
  
  drawDelayBuff = (audiolet) ->
    # fill BG
    canvas = $('#delaygraph')[0]
    context = canvas.getContext('2d')
    context.fillStyle = bgStyle
    context.fillRect 0, 0, cWidth, cHeight
    
    # draw beat lines
    totalNumBeats = Math.floor(samplesToBeats audiolet, amen.length)
    if totalNumBeats < cWidth 
      context.strokeStyle = barLinesStyle
      context.beginPath()
      for line in [0...totalNumBeats]
        samples = beatsToSamples audiolet, line
        pixels = samples / amen.length * cWidth
        context.moveTo pixels, 0
        context.lineTo pixels, cHeight
        
        seconds = beatsToSeconds line
        pixels = seconds / maxDelay * cHeight
        context.moveTo 0, pixels
        context.lineTo cWidth, pixels
        
      context.stroke()
      
    # draw delay line
    context.strokeStyle = delayLineStyle
    context.lineWidth = 3
    context.beginPath()
    context.moveTo 0, cHeight
    for x in [0...cWidth]
      samples = Math.floor (x/cWidth * amen.length)
      delay = delayBuff.channels[0][samples]
      context.lineTo x, cHeight * (1 - delay / maxDelay)
    context.stroke()
    
  AudioletApp = =>
    $('#bpm').change =>
      bpm = $('#bpm').val()
      @audiolet.scheduler.setTempo bpm
      drawDelayBuff @audiolet
      
    @audiolet = new Audiolet()
    @audiolet.scheduler.setTempo bpm
    
    beats = [0, 0, 1, 2,  3, 4, 0, 0] 
    for i in [0..delayBuff.length]
      beat = Math.floor(samplesToBeats @audiolet, i)
      beat = 0 if beat >= beats.length
      delayBuff.channels[0][i] = beatsToSeconds beats[beat]
  

    @delay = new Delay @audiolet, maxDelay, 0
    
    @delayBuffPlayer = new BufferPlayer @audiolet, delayBuff, 1, 0, 1

    @resetTrig = new TriggerControl @audiolet
        
    
    @player = new BufferPlayer @audiolet, amen, 1, 0, 1
    @resetTrig.connect @player, 0, 1
    @player.connect @delay
    @delayBuffPlayer.connect @delay, 0, 1
    @delay.connect @audiolet.output
    drawDelayBuff @audiolet
    

  @audioletApp = new AudioletApp()