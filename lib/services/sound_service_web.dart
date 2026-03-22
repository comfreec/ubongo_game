import 'dart:js_interop';
import 'settings_service.dart';

@JS('AudioContext')
extension type AudioContext._(JSObject _) implements JSObject {
  external factory AudioContext();
  external JSObject createOscillator();
  external JSObject createGain();
  external JSObject get destination;
  external double get currentTime;
}

@JS()
extension type OscillatorNode._(JSObject _) implements JSObject {
  external JSObject get frequency;
  external set type(String t);
  external void connect(JSObject dest);
  external void start([double when]);
  external void stop([double when]);
}

@JS()
extension type GainNode._(JSObject _) implements JSObject {
  external JSObject get gain;
  external void connect(JSObject dest);
}

@JS()
extension type AudioParam._(JSObject _) implements JSObject {
  external void setValueAtTime(double value, double time);
  external void exponentialRampToValueAtTime(double value, double time);
  external void linearRampToValueAtTime(double value, double time);
}

class SoundService {
  static AudioContext? _ctx;

  static AudioContext _getCtx() {
    _ctx ??= AudioContext();
    return _ctx!;
  }

  static void playPlace() {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      final ctx = _getCtx();
      final osc = OscillatorNode._(ctx.createOscillator());
      final gain = GainNode._(ctx.createGain());
      final now = ctx.currentTime;
      osc.type = 'sine';
      AudioParam._(osc.frequency).setValueAtTime(600, now);
      AudioParam._(osc.frequency).exponentialRampToValueAtTime(300, now + 0.08);
      AudioParam._(gain.gain).setValueAtTime(0.3, now);
      AudioParam._(gain.gain).exponentialRampToValueAtTime(0.001, now + 0.1);
      osc.connect(gain as JSObject);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.1);
    } catch (_) {}
  }

  static void playRemove() {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      final ctx = _getCtx();
      final osc = OscillatorNode._(ctx.createOscillator());
      final gain = GainNode._(ctx.createGain());
      final now = ctx.currentTime;
      osc.type = 'sine';
      AudioParam._(osc.frequency).setValueAtTime(300, now);
      AudioParam._(osc.frequency).exponentialRampToValueAtTime(150, now + 0.08);
      AudioParam._(gain.gain).setValueAtTime(0.2, now);
      AudioParam._(gain.gain).exponentialRampToValueAtTime(0.001, now + 0.1);
      osc.connect(gain as JSObject);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.1);
    } catch (_) {}
  }

  static void playSuccess() {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      final ctx = _getCtx();
      final now = ctx.currentTime;
      final notes = [523.0, 659.0, 784.0];
      for (int i = 0; i < notes.length; i++) {
        final osc = OscillatorNode._(ctx.createOscillator());
        final gain = GainNode._(ctx.createGain());
        final t = now + i * 0.15;
        osc.type = 'triangle';
        AudioParam._(osc.frequency).setValueAtTime(notes[i], t);
        AudioParam._(gain.gain).setValueAtTime(0.0, t);
        AudioParam._(gain.gain).linearRampToValueAtTime(0.4, t + 0.05);
        AudioParam._(gain.gain).exponentialRampToValueAtTime(0.001, t + 0.3);
        osc.connect(gain as JSObject);
        gain.connect(ctx.destination);
        osc.start(t);
        osc.stop(t + 0.3);
      }
    } catch (_) {}
  }

  static void playFail() {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      final ctx = _getCtx();
      final osc = OscillatorNode._(ctx.createOscillator());
      final gain = GainNode._(ctx.createGain());
      final now = ctx.currentTime;
      osc.type = 'sawtooth';
      AudioParam._(osc.frequency).setValueAtTime(300, now);
      AudioParam._(osc.frequency).exponentialRampToValueAtTime(80, now + 0.5);
      AudioParam._(gain.gain).setValueAtTime(0.3, now);
      AudioParam._(gain.gain).exponentialRampToValueAtTime(0.001, now + 0.5);
      osc.connect(gain as JSObject);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.5);
    } catch (_) {}
  }
}
