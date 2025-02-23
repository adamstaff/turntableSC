s.boot;
(
SynthDef(\dust, { arg out=0, noise = 0.35, dust = 1.0, rumble = 0.9, level = 1, motor = 0.5;
	var v_noise = BHiPass.ar(Crackle.ar([2,2],[noise,noise]), 8000, 8);
	var v_dust = BBandPass.ar(Dust2.ar([0.7,0.7],[dust,dust]), 800, 5);
	var v_rumble = BBandPass.ar(WhiteNoise.ar([rumble,rumble]), [13.5,13.5], 1);
	var v_motor = BBandPass.ar(WhiteNoise.ar(), 100, 0.1, motor) +
	BBandPass.ar(WhiteNoise.ar(), 150, 0.1, motor * 0.5);

	var v_mix = v_noise + v_dust + v_rumble + v_motor;

	Out.ar(out, v_mix * level)
}).play;
)