//laptop stuff
Server.default.options.inDevice_(1);
Server.default.options.outDevice_(2);
s.boot;

//PANIC
Buffer.freeAll;

//read a sample
b = Buffer.read(s, "/Users/adam/Desktop/basement/01.mp3", action: postln("done"));
b.query;
//unload a sample
r.stop;
r.run(false);
r.run;
r.free;
b.free;
Synth.stop(r);

//synthdef
(
r = SynthDef("out", {
	arg out=0, rate = 1, doloop = 1.0,
	t_trigger, stiffness = 1.1, goto = 0;
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
	position_deci.poll(1);
	Out.ar(out, playback);
}).play;
)

//testing
r.set("rate", 0.5);
r.set("rate",4);
r.set("rate", -2);
r.set(\t_trigger,1);