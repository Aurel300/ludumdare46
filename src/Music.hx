import js.html.audio.*;
import js.lib.*;
import haxe.ds.Vector;

import Math.min;
import Math.max;

class Music {
  public static final SAMPLERATE = 44100;
  public static final SAMPLES = 512;

  public static var outputContext:AudioContext;
  public static var outputOscillator:OscillatorNode;
  public static var outputNode:ScriptProcessorNode;
  public static var playing:Bool = false;

  static var pulsePower = 0.0;
  static var sampleCtr = 0;

  static var tmp = false;

  public static function sampleData(ev:AudioProcessingEvent):Void {
    var outLeft:Float32Array = ev.outputBuffer.getChannelData(0);
    var outRight:Float32Array = ev.outputBuffer.getChannelData(1);
    var volume = .45;
    for (i in 0...SAMPLES) {
      var val = 0.;
      var valL = 0.;
      var valR = 0.;
      val += insKickA.buf[i + insKickA.pos] * insKickA.vol;
      val += insKickB.buf[i + insKickB.pos] * insKickB.vol;
      val += insSnare.buf[i + insSnare.pos] * insSnare.vol;
      val += insSnareOpen.buf[i + insSnareOpen.pos] * insSnareOpen.vol;
      val += insBassA.buf[i + insBassA.pos] * insBassA.vol;
      valL += insBassB.buf[i + insBassB.pos] * insBassB.vol * insBassB.pan;
      valR += insBassB.buf[i + insBassB.pos] * insBassB.vol * (1 - insBassB.pan);
      val += insBassC.buf[i + insBassC.pos] * insBassC.vol;
      val += insTriA.buf[i + insTriA.pos] * insTriA.vol;
      val += insLeadA.buf[i + insLeadA.pos] * insLeadA.vol;
      val += insPadA.buf[i + insPadA.pos] * insPadA.vol;
      val += insPadB.buf[i + insPadB.pos] * insPadB.vol;
      outLeft[i] = (val + valL) * volume;
      outRight[i] = (val + valR) * volume;
    }
    insKickA.tick();
    insKickB.tick();
    insSnare.tick();
    insSnareOpen.tick();
    insBassA.tick();
    insBassB.tick();
    insBassC.tick();
    insTriA.tick();
    insLeadA.tick();
    insPadA.tick();
    insPadB.tick();
  }

  static final N = -1;
  static var penta = [9, 12, 14, 16, 19, 21, 24, 26, 28, 31, 33].map(s -> s - 9);
  static var activePattern:Pattern;
  static var patIntro:Pattern = (sbeat, ipos) -> {
    var beat = (sbeat >> 1) % 64;
    switch (sbeat % 32) {
      case 0: insKickA.trigger(ipos, 1, 0);
      case 8: insSnareOpen.trigger(ipos, .7, 0);
      case 16: insKickA.trigger(ipos, .7, 0);
      case 18: insKickA.trigger(ipos, 1, 0);
      case 24: insSnareOpen.trigger(ipos, .8, 0);
      case 31: insKickB.trigger(ipos, .4, 0);
      case _:
    }
    if (sbeat % 2 == 0) {
      if (beat >= 12) insSnare.trigger(ipos, .4, 0);
      (beat >= 32 ? insTriA : insLeadA).trigger(ipos, beat % 4 == 0 ? .8 : .6, penta[[
        0, 5, 3, 4, 0, 0, 4, 3, 2, 1, 0, 5, 0, 4, 0, 3,
        0, 5, N, 4, N, N, 4, 3, N, 1, 0, N, 0, 4, 0, 3
      ][beat % 32]]);
      insBassA.trigger(ipos, .6, penta[[
        N, N, N, N, N, N, N, N, N, N, 5, N, 5, N, 5, N,
        0, 5, 3, 4, 0, 0, 4, 3, 2, 1, 0, 5, 0, 4, 0, 3
      ][beat % 32]]);
      if (beat % 16 == 3 || beat % 16 == 8) {
        insTriA.fx(beat >= 32 ? 1 : 2);
        insLeadA.fx(beat >= 32 ? 1 : 2);
        insBassA.fx(beat >= 32 ? 1 : 2);
      }
    }
  };
  static var patGame:Pattern = (sbeat, ipos) -> {
    var beat = (sbeat >> 1) % 48;
    var sbeat = sbeat % 768;
    if (sbeat >= 8 && (sbeat >> 3) % 7 == 0) switch (sbeat % 8) {
      case 0: insKickA.trigger(ipos, 0.5, 0);
      case 1: insKickB.trigger(ipos, 0.6, 0);
      case 2: insSnare.trigger(ipos, 0.9, 0);
      case 3: insKickA.trigger(ipos, 0.7, 0);
      case 4: insKickB.trigger(ipos, 0.9, 0);
      case _:
    } else switch (sbeat % 8) {
      case 0: insKickA.trigger(ipos, 1.0, 0);
      case 2: insSnare.trigger(ipos, 0.9, 0);
      case 4: insKickA.trigger(ipos, 0.9, 0);
      case 6: insKickB.trigger(ipos, 0.7, 0);
      case _:
    }
    if ((sbeat >> 6) % 12 >= 8) {
      switch ((sbeat % 64 + 2) % 3) {
        case 1: insTriA.trigger(ipos, 0.8, 0);
        case 0: insTriA.vol = 0.05;
        case _:
      }
      var T = [
        0, 3, 6, 5, N,
        0, 3, 6, 5, N,
        0, 3, 6, 5, 3,
        0, 3, 6, 5, N,
        0, 3, 6, 5, N,
      ][Std.int((sbeat % 64) / 3)];
      if (T == 3 && sbeat % 64 == 0) insLeadA.trigger(ipos, 0.7, T + ((sbeat % 64) >> 3));
      if (T != -1) insTriA.pitchW(T + 12);
    } else if (sbeat >= 8 && (sbeat >> 3) % 35 != 0) {
      switch [(sbeat + 2) % 16, ((sbeat + 2) >> 4) % 4] {
        case [ 0, 0]: insBassA.trigger(ipos, 0.8, 0); insBassB.trigger(ipos, 0.6, 3);
        case [ 7, 0]: insBassA.trigger(ipos, 0.8, 3); insBassB.trigger(ipos, 0.6, 6);
        case [ 9, 0]: insBassA.trigger(ipos, 0.8, 2); insBassB.trigger(ipos, 0.6, 5);
        case [12, 0]: insBassA.vol = 0.05; insBassB.vol = 0.03;
        case [ 0, 1]: insBassA.trigger(ipos, 0.8, 0); insBassB.trigger(ipos, 0.6, 3);
        case [ 7, 1]: insBassA.trigger(ipos, 0.8, 3); insBassB.trigger(ipos, 0.6, 6);
        case [ 9, 1]: insBassA.trigger(ipos, 0.8, 2); insBassB.trigger(ipos, 0.6, 5);
        case [12, 1]: insBassA.vol = 0.05; insBassB.vol = 0.03;
        case [ 0, 2]: insBassA.trigger(ipos, 0.8, 0); insBassB.trigger(ipos, 0.6, 3);
        case [ 7, 2]: insBassA.trigger(ipos, 0.8, 6); insBassB.trigger(ipos, 0.6, 9);
        case [ 9, 2]: insBassA.trigger(ipos, 0.8, 2); insBassB.trigger(ipos, 0.6, 5);
        case [12, 2]: insBassA.vol = 0.05; insBassB.vol = 0.03;
        case [ 0, 3]: insBassA.trigger(ipos, 0.8, 0); insBassB.trigger(ipos, 0.6, 3);
        case [ 8, 3]: insBassA.trigger(ipos, 0.8, 3); insBassB.trigger(ipos, 0.6, 6);
        case [10, 3]: insBassA.trigger(ipos, 0.8, 2); insBassB.trigger(ipos, 0.6, 5);
        case [12, 3]: insBassA.vol = 0.05; insBassB.vol = 0.03;
        case _:
      }
    }
  };
  /*
  static var patOver:Pattern = (beat, ipos) -> {
    if (sbeat >= 144) switch (sbeat % 48) {
      case 3:  insKickB.trigger(ipos, 0.5, 0);
      case 11: insKickA.trigger(ipos, 0.5, 0);
      case 39: insKickA.trigger(ipos, 0.5, 0);
      case 43: insKickB.trigger(ipos, 0.5, 0);
      case _:
    }
    var arpVol = (sbeat >= 384 ? .5 : (sbeat >= 200 ? .9 : (sbeat >= 192 ? .4 : 0)));
    if (sbeat >= 384) {
      if (sbeat < 384 + 12) arpVol *= (sbeat - 384) / 12;
      if (sbeat % 6 == 0) insPadA.trigger(ipos, arpVol * .5, 0);
      var T = penta[[
        0, 3, 0, 3, N, 3, 2, 1, N, 5, 2, 4, 1, N, N, 1, N, 4, 4, 2,
        0, 3, 0, 3, 8, 3, 2, 1, 9, 5, 2, 4, N, 1, 11, 1, 12, N, 4, N,
        0, 3, 0, 3, N, 3, 2, 1, N, 5, 2, 4, 1, N, N, 1, N, 4, 4, 2,
        N, 3, 2, 1
      ][sbeat % 64]];
      if (T == null) insPadA.vol = arpVol * .02;
      else insPadA.vol = arpVol * .5;
      insPadA.pitchW(T);
    } else if (sbeat >= 288) {
      switch (beat % 8) {
        case 0: insPadA.trigger(ipos, arpVol * .2, 0);
        case 2: insPadA.trigger(ipos, arpVol * .175, 0);
        case 4: insPadA.trigger(ipos, arpVol * .15, 0);
        case 6: insPadA.trigger(ipos, arpVol * .175, 0);
      }
      var T = 12;
      if (beat >= 32) T = 16;
      else if (beat >= 16) T = 12;
      else T = 15;
      //T -= Std.int((sbeat - 0) / 12) * 2;
      // if (sbeat % 16 >= 8) T -= 12;
      if (T < 0) T = 0;
      insPadA.pitchW([T+0, T+1, T+3, T+9, T+8, T+3, T+0, T+1, 1+T, 0+T, 3+T, 8+T, 9+T, 3+T, 1+T, 0+T][sbeat % 16]);
    } else {
      switch (beat % 8) {
        case 0: insPadA.trigger(ipos, arpVol * .2, 0);
        case 2: insPadA.trigger(ipos, arpVol * .175, 0);
        case 4: insPadA.trigger(ipos, arpVol * .15, 0);
        case 6: insPadA.trigger(ipos, arpVol * .125, 0);
      }
      var T = 0;
      if (beat >= 32) T = 0;
      else if (beat >= 16) T = 3;
      else T = 4;
      if (sbeat >= 384) T += 12;
      insPadA.pitchW([T+0, T+1, T+3, T+9, T+8, T+3, T+0, T+1][sbeat % 8]);
    }
    if ((sbeat % 48) % 6 == 0) {
      (sbeat % 12 == 0 ? insSnare : insSnareOpen).trigger(ipos, min(.3, sbeat / 100), 0);
    }
    if (sbeat >= 48) switch (sbeat % 48) {
      case 0:  insBassB.trigger(ipos, 0.7, 0); insBassB.fx(2); insBassB.pan = .2;
      case 4:  insBassB.trigger(ipos, 0.7, 0); insBassB.fx(2); insBassB.pan = .3;
      case 12: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(2); insBassB.pan = .4;
      case 16: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(2); insBassB.pan = .5;
      case 24: insBassB.trigger(ipos, 0.7, 0); insBassB.fx(1); insBassB.pan = .6;
      case 28: insBassB.trigger(ipos, 0.7, 0); insBassB.fx(2); insBassB.pan = .7;
      case 40: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(2); insBassB.pan = .5;
      case 44: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(1); insBassB.pan = .3;
      case _:
    }
  };
  */
  static var patOver:Pattern = (sbeat, ipos) -> {
    var beat = (sbeat >> 1) % 48;
    var sbeat = sbeat % 768;
    if (sbeat >= 0) switch (sbeat % 48) {
      case 0:  insKickA.trigger(ipos, 1.0, 0);
      case 4:  insKickA.trigger(ipos, 0.9, 0);
      case 12: insKickB.trigger(ipos, 0.7, 0);
      case 16: insKickA.trigger(ipos, 0.6, 0);
      case 24: insKickB.trigger(ipos, 1.0, 0);
      case 28: insKickA.trigger(ipos, 0.9, 0);
      case 40: insKickB.trigger(ipos, 0.8, 0);
      case 44: insKickA.trigger(ipos, 0.5, 0);
      case _:
    }
    if (sbeat >= 144) switch (sbeat % 48) {
      case 3:  insKickB.trigger(ipos, 0.5, 0);
      case 11: insKickA.trigger(ipos, 0.5, 0);
      case 39: insKickA.trigger(ipos, 0.5, 0);
      case 43: insKickB.trigger(ipos, 0.5, 0);
      case _:
    }
    var arpVol = (sbeat >= 384 ? .5 : (sbeat >= 200 ? .9 : (sbeat >= 192 ? .4 : 0)));
    if (sbeat >= 384) {
      if (sbeat < 384 + 12) arpVol *= (sbeat - 384) / 12;
      if (sbeat % 6 == 0) insPadA.trigger(ipos, arpVol * .5, 0);
      var T = penta[[
        0, 3, 0, 3, N, 3, 2, 1, N, 5, 2, 4, 1, N, N, 1, N, 4, 4, 2,
        0, 3, 0, 3, 8, 3, 2, 1, 9, 5, 2, 4, N, 1, 11, 1, 12, N, 4, N,
        0, 3, 0, 3, N, 3, 2, 1, N, 5, 2, 4, 1, N, N, 1, N, 4, 4, 2,
        N, 3, 2, 1
      ][sbeat % 64]];
      if (T == null) insPadA.vol = arpVol * .02;
      else insPadA.vol = arpVol * .5;
      insPadA.pitchW(T);
    } else if (sbeat >= 288) {
      switch (beat % 8) {
        case 0: insPadA.trigger(ipos, arpVol * .2, 0);
        case 2: insPadA.trigger(ipos, arpVol * .175, 0);
        case 4: insPadA.trigger(ipos, arpVol * .15, 0);
        case 6: insPadA.trigger(ipos, arpVol * .175, 0);
      }
      var T = 12;
      if (beat >= 32) T = 16;
      else if (beat >= 16) T = 12;
      else T = 15;
      //T -= Std.int((sbeat - 0) / 12) * 2;
      // if (sbeat % 16 >= 8) T -= 12;
      if (T < 0) T = 0;
      insPadA.pitchW([T+0, T+1, T+3, T+9, T+8, T+3, T+0, T+1, 1+T, 0+T, 3+T, 8+T, 9+T, 3+T, 1+T, 0+T][sbeat % 16]);
    } else {
      switch (beat % 8) {
        case 0: insPadA.trigger(ipos, arpVol * .2, 0);
        case 2: insPadA.trigger(ipos, arpVol * .175, 0);
        case 4: insPadA.trigger(ipos, arpVol * .15, 0);
        case 6: insPadA.trigger(ipos, arpVol * .125, 0);
      }
      var T = 0;
      if (beat >= 32) T = 0;
      else if (beat >= 16) T = 3;
      else T = 4;
      if (sbeat >= 384) T += 12;
      insPadA.pitchW([T+0, T+1, T+3, T+9, T+8, T+3, T+0, T+1][sbeat % 8]);
    }
    if ((sbeat % 48) % 6 == 0) {
      (sbeat % 12 == 0 ? insSnare : insSnareOpen).trigger(ipos, min(.3, sbeat / 100), 0);
    }
    if (sbeat >= 48) switch (sbeat % 48) {
      case 0:  insBassB.trigger(ipos, 0.7, 0); insBassB.fx(2); insBassB.pan = .2;
      case 4:  insBassB.trigger(ipos, 0.7, 0); insBassB.fx(2); insBassB.pan = .3;
      case 12: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(2); insBassB.pan = .4;
      case 16: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(2); insBassB.pan = .5;
      case 24: insBassB.trigger(ipos, 0.7, 0); insBassB.fx(1); insBassB.pan = .6;
      case 28: insBassB.trigger(ipos, 0.7, 0); insBassB.fx(2); insBassB.pan = .7;
      case 40: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(2); insBassB.pan = .5;
      case 44: insBassB.trigger(ipos, 0.7, 3); insBassB.fx(1); insBassB.pan = .3;
      case _:
    }
  };

  public static inline function makeTempo(bpm:Float):Float {
    return 1000. / (bpm / 60.);
  }

  static var autoTempoCtr = 0.;
  public static var autoBpm = 320.;
  static var autoTempo = makeTempo(320.);
  static var autoBeat = 0;
  public static function autoTick(delta:Float):Void {
    autoTempo = makeTempo(autoBpm);
    autoTempoCtr += delta;
    if (autoTempoCtr >= autoTempo) {
      var frac = (autoTempo - (autoTempoCtr - delta)) / delta;
      var ipos = Std.int(SAMPLES - frac * SAMPLES);
      autoTempoCtr -= autoTempo;
      pulse(autoBeat++, ipos);
    }
  }

  static var selected:MusicId = PatIntro;
  public static function selectMusic(m:MusicId):Void {
    if (m == selected)
      return;
    selected = m;
    autoTempoCtr = 0.;
    autoBeat = 0;
    insKickA.pos = 0;
    insKickB.pos = 0;
    insSnare.pos = 0;
    insSnareOpen.pos = 0;
    insBassA.pos = 0;
    insBassB.pos = 0;
    insBassC.pos = 0;
    insTriA.pos = 0;
    insLeadA.pos = 0;
    insPadA.pos = 0;
    insPadB.pos = 0;
    switch (m) {
      case PatIntro:
        activePattern = patIntro;
        autoBpm = 320.;
      case PatGame:
        activePattern = patGame;
        autoBpm = 480.;
      case PatOver:
        activePattern = patOver;
        autoBpm = 400.;
    }
  }

  public static function pulse(beat:Int, ipos:Int):Void {
    activePattern(beat, ipos);
  }

  public static function play():Void {
    if (playing)
      return;
    if (activePattern == null)
      activePattern = patIntro;
    playing = true;
    outputContext = new AudioContext();
    outputOscillator = outputContext.createOscillator();
    var buf = outputContext.createBuffer(2, SAMPLES, 44100);
    outputNode = outputContext.createScriptProcessor(SAMPLES, 1, 2);
    outputNode.onaudioprocess = sampleData;
    outputOscillator.connect(outputNode);
    outputNode.connect(outputContext.destination);
    outputOscillator.start(0);
  }

  public static function stop():Void {
    if (playing) {
      outputOscillator.stop();
      outputOscillator.disconnect();
      outputNode.disconnect();
    }
    playing = false;
  }

  static var rng:Chance;
  public static function init():Void {
    rng = new Chance(0x7401727B);
    initNoise();
    initDrums();
    initPWM();
    initPad();
    activePattern = patIntro;
  }

  static var bufNoise:Array<Float32Array>;
  static var bufNoiseLP:Array<Float32Array>;
  static function initNoise():Void {
    bufNoise = [ for (len in [128, 256, 1024, 4096]) {
      var buf = new Float32Array(len);
      for (i in 0...len) buf[i] = rng.float();
      buf;
    } ];
    bufNoiseLP = bufNoise.map(buf -> {
      var len = buf.length;
      var lbuf = new Float32Array(len);
      for (i in 0...len) {
        lbuf[i] =
          buf[i] * .6 +
          buf[(i - 1 + len) % len] * .4 +
          buf[(i - 2 + len) % len] * .2 +
          buf[(i - 3 + len) % len] * .1;
      }
      lbuf;
    });
  }

  static inline function noise(res:Int, i:Int):Float {
    return bufNoise[res][i % bufNoise[res].length];
  }
  static inline function noiseLP(res:Int, i:Int):Float {
    return bufNoiseLP[res][i % bufNoiseLP[res].length];
  }

  static var insKickA:Instrument;
  static var insKickB:Instrument;
  static var insSnare:Instrument;
  static var insSnareOpen:Instrument;
  static function initDrums():Void {
    var klen = 20000;
    var bufKickA = new Float32Array(klen);
    var bufKickB = new Float32Array(klen);
    var bufSnare = new Float32Array(klen);
    var bufSnareOpen = new Float32Array(klen);
    var len = klen - SAMPLES;
    var snarePhase = 0;
    for (i in SAMPLES...klen) {
      var phase = i - SAMPLES;
      snarePhase += rng.float() > ((phase / len) * .5) ? 1 : 0;
      var freqA = 390. - (1 - 1500 / (phase + 1500)) * 350.;
      var freqB = 490. - (1 - 1500 / (phase + 1500)) * 450.;
      var wlenA = (44100 / freqA);
      var wlenB = (44100 / freqB);
      var vol = 1 - (phase / len);
      var nvol = max(0, 1 - (phase / 1100)) * .4;
      bufKickA[i] = nvol * noiseLP(2, phase) + vol * Math.sin((phase / wlenA) * Math.PI * 2);
      bufKickB[i] = nvol * noiseLP(2, phase) + vol * Math.sin((phase / wlenB) * Math.PI * 2);
      bufSnare[i] = Math.pow(vol, 5) * noiseLP(3, snarePhase);
      bufSnareOpen[i] = vol * noiseLP(3, snarePhase);
    }
    insKickA = new Instrument(bufKickA);
    insKickB = new Instrument(bufKickB);
    insSnare = new Instrument(bufSnare);
    insSnareOpen = new Instrument(bufSnareOpen);
  }

  static var tetStep = Math.pow(2, 1 / 12);
  static function scale(base:Float, notes:Int):Array<Float> {
    return [ for (i in 0...notes) {
      var f = base;
      base *= tetStep;
      f;
    } ];
  }

  static var insBassA:Poly;
  static var insBassB:Poly; // LR
  static var insBassC:Poly;
  static var insTriA:Poly;
  static var insLeadA:Poly;
  static function initPWM():Void {
    var klen = 20000;
    var len = klen - SAMPLES;
    var bufsBassA = [];
    var bufsTriA = [];
    var bufsLeadA = [];
    var wlensMi = [];
    for (bend in [0, -1, 1]) for (bfreq in scale(55, 26)) {
      var bufBassA = new Float32Array(klen);
      var bufTriA = new Float32Array(klen);
      var bufLeadA = new Float32Array(klen);
      var lfoFreq = 10.;
      var lfoWlen = (44100 / lfoFreq);
      if (bend == 0) wlensMi.push(44100 / (bfreq * 4));
      for (i in SAMPLES...klen) {
        var phase = i - SAMPLES;
        var freq = bfreq * (1 + max(-1, -(1500 / (phase + 1500))) * bend * .45);
        var wlenLo = (44100 / freq);
        var wlenMi = (44100 / (freq * 4));
        var duty = .5 + Math.sin((phase / lfoWlen) * Math.PI * 2) * (phase / len) * .3;
        var wpartLo = (phase % wlenLo) / wlenLo;
        var wpartMi = (phase % wlenLo) / wlenLo;
        var vol = min(1, phase / 2000) * max(0, 1 - (phase / 17000));
        var volLead = min(1, phase / 100) * max(0, 1 - (phase / 17000)) * 3;
        var volTri = min(1, phase / 300) * max(0, 1 - (phase / 12000)) * 1.2;
        // var nvol = max(0, 1 - (phase / 1100)) * .4;
        bufBassA[i] = vol * (wpartLo < duty ? -1 : 1) * .4;
        bufTriA[i] = volTri * (wpartLo - duty);
        bufLeadA[i] = volLead * (wpartMi - .5) * Math.sin((phase / wlenMi) * Math.PI * 2);
      }
      bufsBassA.push(bufBassA);
      bufsTriA.push(bufTriA);
      bufsLeadA.push(bufLeadA);
    }
    insBassA = new Poly(bufsBassA, 26);
    insBassB = new Poly(bufsBassA, 26);
    insBassC = new Poly(bufsBassA, 26);
    insTriA = new Poly(bufsTriA, 26);
    insTriA.wlens = wlensMi;
    insLeadA = new Poly(bufsLeadA, 26);
  }

  static var insPadA:Poly;
  static var insPadB:Poly;
  static function initPad():Void {
    var klen = 60000;
    var len = klen - SAMPLES;
    var bufsPadA = [];
    var wlens = [];
    for (bfreq in scale(110, 26)) {
      wlens.push(44100 / bfreq);
      var bufPadA = new Float32Array(klen);
      var lfoFreq = 10.;
      var lfoWlen = (44100 / lfoFreq);
      for (i in SAMPLES...klen) {
        var phase = i - SAMPLES;
        var val = 0.;
        var stepVol = 0.5;
        for (step in [0, 3, 12, 15, 24, 27]) {
          var freq = bfreq * (1); // + max(-1, -(1500 / (phase + 1500))) * bend * .45);
          var wlen = (44100 / freq);
          val += (((phase % wlen) / wlen) * 2 - 1) * stepVol;
          //val += Math.sin((phase / wlen) * Math.PI * 2) * stepVol;
          stepVol *= .7;
        }
        var vol = min(1, phase / 300) * max(0, 1 - (phase / 90000)) * min(1, max(0, (55000 - phase) / 5000));
        bufPadA[i] = vol * val;
      }
      bufsPadA.push(bufPadA);
    }
    insPadA = new Poly(bufsPadA, 26);
    insPadA.wlens = wlens;
    insPadB = new Poly(bufsPadA, 26);
    insPadB.wlens = wlens;
  }
}

class Instrument {
  public var buf:Float32Array;
  public var pos = 0;
  public var vol = 1.;
  public function new(buf:Float32Array) {
    this.buf = buf;
  }
  public inline function tick():Void {
    if (pos > 0) pos += Music.SAMPLES;
    if (pos >= buf.length - Music.SAMPLES) pos = 0;
  }
  public function trigger(ipos:Int, vol:Float, note:Int):Void {
    pos = ipos; //Music.SAMPLES;
    this.vol = vol;
  }
}

class Poly extends Instrument {
  public var bufs:Vector<Float32Array>;
  public var fxc:Int;
  public var curNote:Int;
  public var pan:Float = .5;
  public var wlens:Array<Float>;
  public function new(bufs:Array<Float32Array>, ?fx:Int) {
    super(bufs[0]);
    this.bufs = Vector.fromArrayCopy(bufs);
    if (fx == null) fx = bufs.length;
    this.fxc = fx;
    curNote = 0;
  }
  override public function trigger(ipos:Int, vol:Float, note:Int):Void {
    if (note == null) return;
    super.trigger(ipos, vol, note);
    buf = bufs[curNote = note];
  }
  public function pitch(note:Int):Void {
    buf = bufs[curNote = note];
  }
  public function pitchW(note:Int):Void {
    if (note == null) return;
    if (pos >= Music.SAMPLES) {
      pos -= Music.SAMPLES;
      var rem = (pos % wlens[curNote % fxc]) / wlens[curNote % fxc];
      pos = Std.int((Math.round(pos / wlens[note % fxc]) + rem) * wlens[note % fxc]);
      pos += Music.SAMPLES;
    }
    pitch(note);
  }
  public function fx(n:Int):Void {
    buf = bufs[(curNote % fxc) + n * fxc];
  }
}

typedef Pattern = Int->Int->Void;

enum MusicId {
  PatIntro;
  PatGame;
  PatOver;
}
