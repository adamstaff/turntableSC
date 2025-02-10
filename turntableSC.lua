-- 
--         turntable v2.1.1
--         By Adam Staff
--
--
--
--               
--    ▼ instructions below ▼
--
-- K1+K3: Load a wav file
-- K3: play / stop
-- K2: pause
--
-- E1: pitch
-- E2: nudge
-- E3: small nudge
-- K1+E2: big nudge
-- K2+K3: backspin
--
-- K1+K2: toggle loop
-- K1+E3: waveform zoom
--
-- Map a MIDI controller to
-- 'Fader Position' to fade
-- between the turntable and
-- norns stereo inputs
--

util = require "util"
fileselect = require "fileselect"

function init()

  weIniting = true
  clockCounter = 60
  osdate = os.date()
  osdate = osdate:sub(12,16)
  jitter = 0
  
	-- encoder settings
  norns.enc.sens(2,1)
  norns.enc.accel(2,-2)

	-- clocks setup
  play_clock_id = clock.run(play_clock)
  
  -- turntable variables
  rpmOptions = { "33 1/3", "45", "78" }
  zoomOptions = {0.125, 0.25, 0.5, 1, 1.5, 2, 4}
  faderOptions = {0, 1, 3, 10}
  tt = {}
  tt.rpm = 33.3
  tt.recordSize = 27
  tt.recordSpeed = 33.33
  tt.playRate = 0.
  tt.destinationRate = 0.
  tt.nudgeRate = 0.
  tt.inertia = 0.1
  tt.position = 0
  tt.pitch = 1
  tt.stickerSize = 9
  tt.stickerHole = 1
  tt.mismatch = 1
  tt.rateRate = 1
  
  heldKeys = {}
  
  playing = false
  paused = false
  weLoading = false
  screenDirty = true
  
  pausedHand = 15
  
  --uncomment to auto load a file
  --load_file(_path.audio..'/something.wav', 0, 0, -1, 0, 1)
end

function load_file(file)
  if file and file ~= "cancel" then
    print('loading file '..file)
    --get file info
    local ch, length, rate = audio.file_info(file)
    --calc length in seconds
    waveform.lengthInS = length * ((rate / 48000) / rate)
    print("sample length is "..waveform.lengthInS)
    print("sample rate is "..rate)
    waveform.rate = rate
    waveform.length = length
    tt.rateRate = rate / 48000
    --load file into buffer (file, start_source (s), start_destination (s), duration (s), preserve, mix)
    engine.fileload(file, length)
    --read samples into waveformSamples (number of samples)
    --update param
  end
  weLoading = false
  heldKeys[1] = false
  screenDirty = true
end

function drawBackground()

end

function drawUI()
  screen.level(15)
  screen.move(64,32)
  screen.text(tt.playRate)
end

function redraw()
  if not weLoading then
  	if screenDirty or tt.playRate > 0.001 or tt.playRate < 0.001 then
			screen.clear()
			drawBackground()
			drawUI()
			screen.fill()
			tt.position = tt.position + tt.playRate * ((tt.rpm/60)*360)/60
		end
  end

  screen.update()

end


function play_clock()
  while true do
    clock.sleep(1/240)
    local get_to = tt.rateRate * tt.pitch * tt.mismatch * tt.destinationRate + tt.nudgeRate
    if tt.playRate ~= get_to then
      if tt.playRate < 0.01 and tt.playRate > -0.01 then
        tt.playRate = 0 
      else
		  engine.rate = tt.playRate
      end
    end
  end
end

function enc(e, d)
  --SHIFTING
  if (heldKeys[1]) then
    paused = true
    if e == 1 then
    	
    end
    if e == 2 then
      tt.nudgeRate = d * 10
    end
    if e == 3 then
      if not heldKeys[2] then

      end
    end
  else
    paused = false
    --Not Shifting
    if (e == 3) then
      tt.nudgeRate = d / 10
    end
    
    if (e == 2) then
      tt.nudgeRate = d * 2
    end
    
    if (e == 1) then

    end
  end
  screenDirty = true
end

function key(k, z)

  heldKeys[k] = z == 1

  -- load sample
  if (k == 3 and z ==0 and heldKeys[1]) then
	  weLoading = true
		fileselect.enter(_path.audio,load_file)
	end
	
  if z == 0 then
    if k == 1 then
      
    end
  end
  
  if k == 2 and heldKeys[1] and z==0 then

  end
  
  if k == 2 and not heldKeys[1] and z == 1 then
      paused = true
      if playing then 
        tt.destinationRate = 0
        tt.inertia = 0.7
      end
  end
  if k == 2 and z == 0 then
    paused = false
    if playing then
      tt.destinationRate = 1
      tt.inertia = 0.3
    end
  end
  
  if k == 3 then
    if z == 1 and not heldKeys[1] and not heldKeys[2] and not weLoading then --PLAY/STOP
      if playing then
        playing = false
        tt.destinationRate = 0
      else
        playing = true
        tt.destinationRate = 1
      end
    end
  end
  
  if heldKeys[2] and heldKeys[3] then --wheeeell upp
    tt.playRate = -40
    tt.inertia = 0.1
  end
  
  screenDirty = true
end

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(play_clock_id)
--  clock.cancel(sync_clock_id)
end