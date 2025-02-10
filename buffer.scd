//laptop stuff
Server.default.options.inDevice_(3);
Server.default.options.outDevice_(3);
s.boot;

//unload buffers
Buffer.freeAll;

//read a sample
b = Buffer.read(s, "/Users/adam/Desktop/basement/01.mp3", action: postln("done"));
b.query;

//synthdef
(
r = SynthDef("out", {
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
)

//testing
r.set("rate", 0.0);
r.set("rate",1);
r.set("rate", -2);
r.set(\t_trigger,1);
r.set(\t_poll,1);