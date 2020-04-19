using StringTools;

class Sfx {
  public static var rng = new Chance(0xDEAFF00D);
  public static var enabled:Bool = true;

  public static function enable(to:Bool):Void {
    enabled = to;
    if (!to) {
      for (id => asset in Asset.ids) {
        if (id.endsWith(".wav")) {
          Asset.ids[id].sound.stop();
        }
      }
    }
  }

  public static function play(id:String, ?varyPitch:Float = 0.35):Void {
    if (!enabled)
      return;
    var channel = Asset.ids[id + ".wav"].sound.play();
    Asset.ids[id + ".wav"].sound.volume(switch (id) {
      case "pickup" | "drop":
        varyPitch = 0.1;
        0.3;
      case _: 0.5;
    });
    if (varyPitch > 0)
      Asset.ids[id + ".wav"].sound.rate(rng.rangeF(1.0 - varyPitch, 1.0 + varyPitch), channel);
  }
}
