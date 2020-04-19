class Main {
  public static var aPng:Asset;
  public static var aWav:Asset;
  public static var aShade:Asset;
  public static var input:Input;
  public static var ren:Render;

  public static function main():Void window.onload = _ -> {
    var canvas = document.querySelector("canvas");
    Debug.init();
    Music.init();
    input = new Input(document.body, canvas);
    Game.init();
    // Save.init();
    Debug.button("reload png", () -> aPng.reload());
    Debug.button("reload shade", () -> aShade.reload());
    aShade = Asset.load(null, "shade.glw");
    aShade.loadSignal.on(asset -> {
      Wave.init(asset.pack["waves.txt"].text);
    });
    aPng = Asset.load(null, "png.glw");
    aWav = Asset.load(null, "wav.glw");
    /*
    Music.init();
    var inited = false;
    aShade.loadSignal.on(asset -> {
      Set.init(asset.pack["sets.txt"].text);
    });
    var loaded = 0;*/
    // Game.start(Classic(3, 3, 0));
    Render.init(cast canvas);
    Music.play();
    /*
    for (asset in [aPng, aWav, aShade, aMusic]) asset.loadSignal.on(_ -> {
      loaded++;
      if (loaded == 4)
        ren.start();
    });
    */
  };
}
