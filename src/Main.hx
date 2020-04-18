class Main {
  // public static var aPng:Asset;
  // public static var aWav:Asset;
  public static var aShade:Asset;
  // public static var aMusic:Asset;
  public static var input:Input;
  public static var ren:Render;

  public static function main():Void window.onload = _ -> {
    var canvas = document.querySelector("canvas");
    input = new Input(document.body, canvas);
    Game.initInput(input);
    // Save.init();
    Debug.init();
    /*Debug.button("reload png", () -> aPng.reload());*/
    Debug.button("reload shade", () -> aShade.reload());
    aShade = Asset.load(null, "shade.glw");
    /*aPng = Asset.load(null, "png.glw");
    aWav = Asset.load(null, "wav.glw");
    aMusic = Asset.load(null, "music.glw");
    Music.init();
    var inited = false;
    aShade.loadSignal.on(asset -> {
      Set.init(asset.pack["sets.txt"].text);
    });
    var loaded = 0;*/
    Game.start(Classic(3, 3, 0));
    ren = new Render(cast canvas);
    ren.start();
    /*
    for (asset in [aPng, aWav, aShade, aMusic]) asset.loadSignal.on(_ -> {
      loaded++;
      if (loaded == 4)
        ren.start();
    });
    */
  };
}
