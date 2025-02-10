Engine_turntable : CroneEngine {

	var params;

	alloc { // allocate memory to the following:

		// add SynthDefs
		SynthDef("turntable", {
			arg bufNum = 0, out=0,
			t_trigger, t_poll,
			rate = 1, doloop = 1.0,	stiffness = 1.1, goto = 0;
			var playback, playhead, position, position_deci;
			playhead = Phasor.ar(
				trig: t_trigger,
				rate: rate,
				start: 0,
				end: BufFrames.kr(b.bufnum),
				resetPos: goto
			);
			position = Lag3.ar(playhead, stiffness);
			position_deci = position / BufFrames.kr(b.bufnum);
			playback = BufRd.ar(
				numChannels: 2,
				bufnum: 0,
				phase: position,
				loop: doloop;
			);
			Poll.kr(t_poll, position_deci, "position");
			Out.ar(out, playback);
		}).play;

	Server.default.sync;
		
	// let's create an Dictionary (an unordered associative collection)
	//   to store parameter values, initialized to defaults
	// for user control
	params = Dictionary.newFrom([
		\turntBuf, {},
		\rate, 0.0,
		\stiffness, 2,
		\doloop, 1
		;
	]);

	// "Commands" are how the Lua interpreter controls the engine.
	// The format string is analogous to an OSC message format string,
	//   and the 'msg' argument contains data.

	// We'll just loop over the keys of the dictionary, 
	// and add a command for each one, which updates corresponding value:
	params.keysDo({ arg key;
		this.addCommand(key, "f", { arg msg;
			params[key] = msg[1];
		});
	});
	
	// command to load file into buffer
	// "fileload" will be name of Lua file parameter
	// i.e. engine.fileload(filename,number_of_samples)
	this.addCommand("loadfile","si", { arg msg;
	    // empty buffer
	   turntBuf.free;
	    // post a friendly message
	    postln("loading "++msg[2]++" samples of "++msg[1]);
	    // write to the buffer
    	turntBuff = Buffer.read(context.server,msg[1],numFrames:msg[2]);
	    // set correct buffer number & stop turntable
	    turntable.set(
	        \rate, 0.0, \goto, 0.0, \t_trigger, 1
	    );;
	};
	
	//command to poll the position
	this.addCommand("pos_poll","f", { arg msg;
	    turntable.set(
	    	\t_poll,1
	    )
	};

	//command to poll the position - decimal position
	this.addCommand("goto","f", { arg msg;
	    turntable.set(
	    	\goto,msg
	    )
	};

}
