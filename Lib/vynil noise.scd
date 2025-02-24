(
    // add SynthDefs
		SynthDef("turntable", {
			arg t_trigger = 0, prate = 1, doloop = 1, stiffness = 1, skipto = 0,
			noise_level = 0.5, tnoise = 0.25, tdust = 1, trumble = 2, tmotor = 1;

			var playrate = Lag3.kr(prate, stiffness);
			// playhead
			var playhead = Phasor.ar(
				trig: t_trigger,
				rate: playrate,
				start: 0,
				end: BufFrames.kr(0),
				resetPos: skipto;
			);
			//  playhead position
			var position = playhead;
			var position_deci = position / BufFrames.kr(0);

			// noise stuff
		  var v_noise = BHiPass.ar(Crackle.ar([2,2],[tnoise,tnoise]), 6000, 8);
			var v_dust = BBandPass.ar(Dust2.ar([0.7,0.7],[tdust,tdust]), 800, 5);
			var v_rumble = BBandPass.ar(WhiteNoise.ar([trumble,trumble]), [13.5,13.5], 5);
			var v_motor = BBandPass.ar(WhiteNoise.ar(), 100, 0.1, tmotor) + BBandPass.ar(WhiteNoise.ar(), 150, 0.1, tmotor * 0.5);
			var noise_level2 = noise_level * playrate;
			var v_mix = (v_noise + v_dust + v_rumble + v_motor) * noise_level2;
			var withnoise = v_mix;

			Out.ar(0, withnoise);
		}).play;
)