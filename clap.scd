// INTRODUCTION A SUPERCOLLIDER - ZENIKA, 19 NOVEMBRE 2020

// SuperCollider = plateforme pour la synthèse audio & la composition algorithmique
// https://github.com/supercollider/supercollider
// Créé en 1996 par James McCartney, open sourcé en 2002
// Maintenu par une petite équipe de volontaires
// Architecture client (langage SuperCollider spécifique pour le musicien) - serveur (C++)
// Le serveur est aussi le back-end pour plusieurs autres logiciels : Sonic PI, TidalCycles
// Autres logiciels similaires mais programmation grpahique : Max / MSP, Pure Data, Reaktor, etc.

// 1 : regardez la vidéo d'une interprétation de Clapping Music de Steve Reich (1972)
// https://www.youtube.com/watch?v=QNZQzpWCTlA

// 2 : pour évaluer une ligne ou un bloc (délimité par des parenthèses sur des lignes)
// mettez-vous sur la ligne ou la parenthèse et appuyez sur cmd+entrée (Mac) ou ctrl+entrée (PC)

// à tout moment, vous pouvez vous mettre sur un mot clé du langage et taper sur cmd+d ou ctrl+d pour avoir la documentation associée

// 3 : évaluez ce bloc, vous devriez entendre un clap
(
~clap = Buffer.read(server: s, path: Document.current.dir +/+ "samples" +/+ "clap.wav", action: { |buf| buf.play; });
)

// 4 : évaluez ce bloc pour charger les différents claps de chacun des interprêtes
(
~clap1SampleNames = ["clap1-1.wav", "clap1-2.wav", "clap1-3.wav", "clap1-4.wav"];
~clap2SampleNames = ["clap2-1.wav", "clap2-2.wav", "clap2-3.wav", "clap2-4.wav"];
~clap1Samples = ~clap1SampleNames.collect({ |fileName|
	Buffer.read(server: s, path: Document.current.dir +/+ "samples" +/+ fileName);
});
~clap2Samples = ~clap2SampleNames.collect({ |fileName|
	Buffer.read(server: s, path: Document.current.dir +/+ "samples" +/+  fileName);
});
)

// 5 : on crée un synthé basique pour jouer un échantillon sonore / sample
(
SynthDef(\samplePlayer, { |out = 0, bufnum|
	Out.ar(out, PlayBuf.ar(numChannels: 2, bufnum: bufnum, doneAction: Done.freeSelf));
}).add;
)

// évaluez la ligne suivante
Synth(\samplePlayer, [out: 0, bufnum: ~clap]); // on entend notre synthé qui joue un clap

// les routines permettent de séquencer "à la main" deux événements
(
Routine.new({
	Synth(\samplePlayer, [out: 0, bufnum: ~clap]);
	1.0.wait; // attendre 1 temps = 1 seconde au tempo par défaut de 60 bpm
	Synth(\samplePlayer, [out: 0, bufnum: ~clap]);
}).play;
)

// il y a tout une librairie de patterns qui permettent de séquencer plus facilement
// voir le Pattern Guide dans l'aide en ligne
~pattern = Pn(Pseq([1, 2]), 2); // valeur 1, puis 2, repété 2 fois
~stream = ~pattern.asStream;
~stream.next;

// on rentre dans le dur, on joue Clapping Music !

~claps = [1,1,1,0,1,1,0,1,0,1,1,0];

// le début

(
TempoClock.default.tempo = 100/60;

Routine.new({
	~pattern = Pseq(~claps);

	4.do({
		var stream, time;
		stream = ~pattern.asStream;

		12.do( {|j|
			if (stream.next == 1) {
				Synth(\samplePlayer, [out: 0, bufnum: ~clap1Samples.choose]);
				Synth(\samplePlayer, [out: 0, bufnum: ~clap2Samples.choose]);
			};
			(1/ 4).wait; // des double-croches = 1/4 de temps
		});
	});
}).play;
)

// puis le déphasage

(
TempoClock.default.tempo = 100/60;

Routine.new({
	~pattern = Pseq(~claps);

	4.do({
		var stream, time;
		stream = ~pattern.asStream;

		12.do( {|j|
			if (stream.next == 1) {
				Synth(\samplePlayer, [out: 0, bufnum: ~clap1Samples.choose]);
				Synth(\samplePlayer, [out: 0, bufnum: ~clap2Samples.choose]);
			};
			(1/ 4).wait;
		});
	});

	(1..12).do( {|i|
		4.do({
			var streamg, streamd;
			~patterng = Pseq(~claps);
			~patternd = Pslide(list: ~claps, len: 12, start: i);
			streamg = ~patterng.asStream;
			streamd = ~patternd.asStream;

			12.do( {
				if (streamg.next == 1) {
					Synth(\samplePlayer, [out: 0, bufnum: ~clap1Samples.choose]);
				};
				if (streamd.next == 1) {
					Synth(\samplePlayer, [out: 1, bufnum: ~clap2Samples.choose]);
				};
				(1 / 4).wait; // 1 double croche à 100 bpm
			});
		});
	});
}).play;
)

// une variation de Clapping Music ?

~claps = { [0,1].choose } ! 12;

// avec des notes plutôt que des claps ?

// on construit un orgue hammond simplifié
// un orgue hammond a 9 tirettes pour moduler le son : https://en.wikipedia.org/wiki/Hammond_organ

(
SynthDef(\hammond,{ |out = 0, freq = 440, amp = 0.1, pan = 0, drawbars = #[1,0,1,0,1,0,1,0,1]|
	var sound;

	sound = Mix.fill(9, {|i| SinOscFB.ar(freq: freq * (i+1) * (1 + (LFNoise1.ar(10) * 0.001)),  feedback: drawbars[i] / 2) * drawbars[i] / 9 }); // on mixe 9 oscillateurs en sinus
	sound =  BLowPass.ar(sound, 8000); // un petit filtre pour pas que ce soit trop criard
	sound = sound * EnvGen.ar(Env.linen(0.02,0.1,1.0), doneAction: Done.freeSelf); // enveloppe pour adoucir l'attaque et la fin du son
	Out.ar(out, Pan2.ar(sound * amp, pan)); // panoramique et volume général
}).add;
)

// tester notre orgue avec différentes valeurs pour drawbars
(
Pbind(*[
	instrument: \hammond,
	degree: Pseq([7,5,4,0], 3),
	dur: 0.5,
	root: 0,
	octave: 5,
	scale: Scale.major,
	drawbars: [[1, 0, 1, 1, 1, 0, 0, 0, 0]]
]).play
)

// on adapte Clapping Music pour que ce soit des notes tirées au hasard plutôt que des claps

0.5.coin; // une chance sur 2 d'avoir la valeur "true"

// on tire les notes au hasard, nil pour un silence
(
~claps =  {
	if (0.5.coin) {
		nil
	} {
		// on choisit un degré dans la gamme majeure qui compte 12 notes
		(0..11).choose
	}
} ! 12;
)

(
TempoClock.default.tempo = 100/60;

// on tire les tirettes de chaque orgue au hasard

Routine.new({
	var drawbarsg = { 1.0.rand } ! 9;
	var drawbarsd = { 1.0.rand } ! 9;
	~pattern = Pseq(~claps);

	4.do({
		var stream, time;
		stream = ~pattern.asStream;

		12.do({
			var degree;
			degree = stream.next;
			if (degree != nil) {
				(instrument: \hammond, dur: 1/4, octave: 3, degree: degree, drawbars: [drawbarsg], pan: -1).play;
				(instrument: \hammond, dur: 1/4, octave: 3, degree: degree, drawbars: [drawbarsd], pan: 1).play;
			};
			(1/ 4).wait;
		});
	});

	(1..12).do( {|i|
		4.do({
			var streamg, streamd;
			~patterng = Pseq(~claps);
			~patternd = Pslide(list: ~claps, len: 12, start: i);
			streamg = ~patterng.asStream;
			streamd = ~patternd.asStream;

			12.do( {
				var degreeg, degreed;
				degreeg = streamg.next;
				degreed = streamd.next;

				if (degreeg != nil) {
					(instrument: \hammond, dur: 1/4, octave: 3, degree: degreeg, drawbars: [drawbarsg], pan: -1).play;
				};
				if (degreed != nil) {
					(instrument: \hammond, dur: 1/4, octave: 3, degree: degreed, drawbars: [drawbarsd], pan: 1).play;
				};
				(1 / 4).wait; // 1 double croche à 100 bpm
			});
		});
	});
}).play;
)