Engine_turntable : CroneEngine {

	  var params;
    var turntable;
    var tBuff;
    var position_deci;
    
    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

	// we need to make sure the server is running before asking it to do anything
	alloc { // allocate memory to the following:

    var s = Server.local;
    // ( server, frames, channels, bufnum )
    tBuff = Buffer.new(context.server, 0, 2, 0);

    // add SynthDefs
		CroneDefs.add("turntable", {
			arg t_trigger,
			prate, doloop,	stiffness, goto;
			var playback, playhead, position;
			playhead = Phasor.ar(
				trig: t_trigger,
				rate: prate,
				start: 0,
				end: BufFrames.kr(0),
				resetPos: goto
			);
			position = Lag3.ar(playhead, stiffness);
			position_deci = position / BufFrames.kr(0);
			playback = BufRd.ar(
				numChannels: tBuff.numChannels,
				bufnum: 0,
				phase: position,
				loop: doloop;
			);
			Out.ar(0, playback);
		}).add;
		
		
		Server.default.sync;
	
  // let's create an Dictionary (an unordered associative collection)
	//   to store parameter values, initialized to defaults
	// for user control
	params = Dictionary.newFrom([
		\prate, 0.5,
		\stiffness, 0.5,
		\doloop, 1,
		\goto, 0.0,
		\t_poll, 0,
		\t_trigger, 0
		;
	]);
	
	turntable = Synth("turntable", target:context.xg);

	// "Commands" are how the Lua interpreter controls the engine.
	// The format string is analogous to an OSC message format string,
	//   and the 'msg' argument contains data.

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
	    // post a friendly message
	    postln("loading "++msg[2]++" samples of "++msg[1]);
	    // write to the buffer
    	tBuff = Buffer.read(context.server,msg[1],numFrames:msg[2]);
	    postln("and put it in buffer number "++tBuff.bufnum);
	    turntable.set(
	        \prate, 0.0, \goto, 0.0, \t_trigger, 1
	    )
	});
	
	// end commands
	
	// polls
	
	this.addPoll("get_position", {
			var pos = position_deci;
			pos
	});
	
	this.addPoll("file_loaded", func:{
		var isLoaded = false;
		if (BufFrames.kr(tBuff) > 0, {
			isLoaded = true
	  });
		isLoaded;
	  }, periodic:false;
	);
	
	} // end alloc
	
	// NEW: when the script releases the engine,
	//   free Server resources and nodes!
	// IMPORTANT
	free {
		Buffer.freeAll;
		turntable.free;
	} // end free

} // end crone