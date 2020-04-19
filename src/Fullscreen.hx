class Fullscreen {
  public static var enabled(get, set):Bool;
  static function get_enabled():Bool {
    return js.Syntax.code("fsCheck()");
  }
  static function set_enabled(to:Bool):Bool {
    var cEl = js.Browser.document.querySelector("canvas");
    if (to) {
      js.Syntax.code("fsRequest()");
      shEl = js.Browser.document.getElementById("sh");
    } else {
      js.Syntax.code("fsCancel()");
      cEl.style.width = "600px";
      cEl.style.height = "480px";
      lastSc = 2;
    }
    return to;
  }
  static var tickPhase = 0;
  public static var lastSc = 2;
  static var shEl:js.html.Element;
  public static function tick():Void {
    tickPhase++;
    if (tickPhase < 10) return;
    tickPhase = 0;
    var cEl = js.Browser.document.querySelector("canvas");
    var bsc = 2;
    var padTop = 0;
    if (get_enabled()) {
      var fw = shEl.clientWidth;
      var fh = shEl.clientHeight;
      for (sc in 3...10) {
        if (300 * sc >= fw || 240 * sc >= fh)
          break;
        bsc = sc;
      }
      padTop = (fh - 240 * bsc) >> 1;
    }
    if (lastSc != bsc) {
      cEl.style.width = '${300 * bsc}px';
      cEl.style.height = '${240 * bsc}px';
      shEl.style.paddingTop = '${padTop}px';
      lastSc = bsc;
    }
  }
}
