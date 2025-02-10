Engine_turntable : CroneEngine {

	var params;

	alloc { // allocate memory to the following:

		// add SynthDefs
		SynthDef("turntable", {
			arg out=0, rate, doloop;
			var playback;
			var lag = Lag3.kr(rate, 1.1);
			playback = PlayBuf.ar(2, 0, lag, loop: doloop);

		Out.ar(out, playback);
		}	).play;

  Server.default.sync;
		
	// let's create an Dictionary (an unordered associative collection)
	//   to store parameter values, initialized to defaults.
	params = Dictionary.newFrom([
		\turntBuff,
		\rate, 1,
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
  // "loadfile" will be name of Lua file parameter
  // i.e. engine.loadfile(filename,number_of_samples)
	this.addCommand("loadfile","isi", { arg msg;
    // empty buffer
    turntBuff.free;
    // post a friendly message
    postln("loading "++msg[2]++" samples of "++msg[1]);
    // write to the buffer
    turntBuff = Buffer.read(context.server,msg[1],numFrames:msg[2]);
    // set correct buffer number & stop turntable
    turntable.set(
        \bufnum,0,
        \rate, 0
    );;
	};

}