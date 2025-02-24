Engine_turntable : CroneEngine {

	  var params;
	  var turntable;
	  var tBuff;
	  var <posBus;
    
    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

	// we need to make sure the server is running before asking it to do anything
	alloc { // allocate memory to the following:

    var s = Server.default;
    var isLoaded = false;
    // ( server, frames, channels, bufnum )
    tBuff = Buffer.new(context.server, 0, 2, 0);
    posBus = Bus.control(context.server);

    // add SynthDefs
		SynthDef("turntable", {
			arg t_trigger, prate, doloop, stiffness, skipto,
			noise_level = 0.5, t_noise = 0.35, t_dust = 1.0, t_rumble = 0.9, t_motor = 0.5;
			var withnoise, playback, playhead, position, position_deci,
			v_noise, v_dust, v_rumble, v_motor, v_mix;
			// playhead
			playhead = Phasor.ar(
				trig: t_trigger,
				rate: prate,
				start: 0,
				end: BufFrames.kr(0),
				resetPos: skipto;
			);
			//  playhead position
			position = Lag3.ar(playhead, stiffness);
			position_deci = position / BufFrames.kr(0);
			//  playback engine
			playback = BufRd.ar(
				numChannels: tBuff.numChannels,
				bufnum: 0,
				phase: position,
				loop: doloop;
			);
			// noise stuff
		  v_noise = BHiPass.ar(Crackle.ar([2,2],[t_noise,t_noise]), 8000, 8);
			v_dust = BBandPass.ar(Dust2.ar([0.7,0.7],[t_dust,t_dust]), 800, 5);
			v_rumble = BBandPass.ar(WhiteNoise.ar([t_rumble,t_rumble]), [13.5,13.5], 1);
			v_motor = BBandPass.ar(WhiteNoise.ar(), 100, 0.1, t_motor) + BBandPass.ar(WhiteNoise.ar(), 150, 0.1, t_motor * 0.5);
			v_mix = v_noise + v_dust + v_rumble + v_motor;
			withnoise = playback + (v_mix * noise_level);

			Out.ar(0, withnoise);
			Out.kr(posBus.index, position_deci)
		}).add;
		
		// done and sync
		s.sync;
	
    // let's create an Dictionary (an unordered associative collection)
  	//   to store parameter values, initialized to defaults
  	// for user control
	  params = Dictionary.newFrom([
  		\prate, 0.5,
  		\stiffness, 0.0,
  		\doloop, 1,
  		\skipto, 0.0,
  		\t_trigger, 0,
  		\noise_level, 0.5,
  		\t_noise, 0.35, 
  		\t_dust, 1.0, 
  		\t_rumble, 0.9, 
  		\t_motor, 0.5
  		;
  	]);
	
  	turntable = Synth("turntable", target:context.xg);

  	// "Commands" are how the Lua interpreter controls the engine. FROM LUA TO SC
  	// The format string is analogous to an OSC message format string,
  	// and the 'msg' argument contains data.

  	// We'll just loop over the keys of the dictionary, 
  	// and add a command for each one, which updates corresponding value:
  	params.keysDo({ arg key;
  		this.addCommand(key, "f", { arg msg;
  		  //postln("setting command " ++ key ++ " to " ++ msg[1]);
  		  params[key] = msg[1];
  		  turntable.set(key, msg[1]);
  		});
  	});
	
  	// command to load file into buffer
  	// "fileload" will be name of Lua file parameter
  	// i.e. engine.fileload(filename,number_of_samples)
  	this.addCommand("fileload","si", { arg msg;
      // empty buffer
      tBuff.free;
	    // write to the buffer
    	tBuff = Buffer.read(context.server,msg[1],numFrames:msg[2]);
	    postln("and put it in buffer number "++tBuff.bufnum);
	    turntable.set(
	        \prate, 0.0, \goto, 0.0, \t_trigger, 1
	    );
	    // post a friendly message
	    postln("loaded "++tBuff.numFrames++" samples of "++msg[1]);
	    isLoaded = true;
	  });
	
	  // end commands
	
	  // polls FROM SC TO LUA
	  this.addPoll("get_position", {
			var pos = posBus.getSynchronous;
			pos;
	  });

	  this.addPoll("file_loaded", {
	    isLoaded;
	  }, periodic:false
	  );
	
	} // end alloc
	
	// NEW: when the script releases the engine,
	//   free Server resources and nodes!
	// IMPORTANT
	free {
		Buffer.freeAll;
		turntable.free;
		posBus.free;
	} // end free

} // end crone
