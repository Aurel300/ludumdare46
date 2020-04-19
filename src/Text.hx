class Text {
  public static function render(x:Int, y:Int, text:String):Void {
    var ox = x;
    var bold = false;
    var shake = false;
    var pos = 0;
    while (pos < text.length) {
      var cc = text.charCodeAt(pos++);
      var adv = 6;
      switch (cc) {
        case "\n".code:
          x = ox;
          y += 12;
          continue;
        case "$".code:
          switch (text.charCodeAt(pos++)) {
            case "b".code: bold = !bold; continue;
            case "s".code: shake = !shake; continue;
            case "$".code: cc = "$".code;
            case _: continue;
          }
        case "1".code: adv = 5;
        case "I".code: adv = 5;
        case "M".code: adv = 7;
        case "T".code if (bold): adv = 5;
        case "V".code: adv = 7;
        case "W".code: adv = 7;
        case "Y".code if (!bold): adv = 7;
        case "f".code: adv = 5;
        case "i".code: adv = 5;
        case "l".code: adv = 5;
        case "m".code: adv = 8;
        case "v".code: adv = 7;
        case "w".code if (bold): adv = 8;
        case "w".code: adv = 7;
        case "x".code: adv = 7;
        case _:
      }
      if (bold) adv++;
      if (bold && cc >= "A".code && cc <= "Z".code) adv++;
      var btx = 112;
      var bty = bold ? 266 : 218;
      var tx = ((cc - 32) % 32) * 10;
      var ty = ((cc - 32) >> 5) * 16;
      Render.draw(x + (shake ? Std.int(Math.random() * 2 - 1) : 0), y + (shake ? Std.int(Math.random() * 4 - 2) : 0), btx + tx, bty + ty, 10, 16);
      x += adv;
    }
  }

  public static inline function line(base:Int, y:Int):Int {
    return Std.int((y - base) / 12);
  }

  public static function renderDigits(x:Int, y:Int, val:Float):Void {
    var pos = 0;
    var text = '${Math.round(val * 100)}';
    while (pos < text.length - 2) {
      var cc = text.charCodeAt(pos++);
      var tx = ((cc - "0".code) % 32) * 12;
      Render.draw(x, y, 112 + tx, 320, 9, 24);
      x += (cc == "1".code ? 6 : 9);
    }
    Render.draw(x, y, 112 + 12 * 10, 320, 9, 24);
    x += 4;
    while (pos < text.length) {
      var cc = text.charCodeAt(pos++);
      var tx = ((cc - "0".code) % 32) * 10;
      Render.draw(x, y, 112 + tx, 344, 7, 24);
      x += (cc == "1".code ? 6 : 7);
    }
  }

  public static function width(text:String):Int {
    var max = 0;
    var x = 0;
    var bold = false;
    var pos = 0;
    while (pos < text.length) {
      var cc = text.charCodeAt(pos++);
      var adv = 6;
      switch (cc) {
        case "\n".code:
          x = 0;
          continue;
        case "$".code:
          switch (text.charCodeAt(pos++)) {
            case "b".code: bold = !bold; continue;
            case "$".code: cc = "$".code;
            case _: continue;
          }
        case "I".code: adv = 5;
        case "M".code: adv = 7;
        case "T".code if (bold): adv = 5;
        case "V".code: adv = 7;
        case "W".code: adv = 7;
        case "Y".code if (!bold): adv = 7;
        case "f".code: adv = 5;
        case "i".code: adv = 5;
        case "l".code: adv = 5;
        case "m".code: adv = 8;
        case "v".code: adv = 7;
        case "w".code if (bold): adv = 8;
        case "w".code: adv = 7;
        case "x".code: adv = 7;
        case _:
      }
      if (bold) adv++;
      if (bold && cc >= "A".code && cc <= "Z".code) adv++;
      x += adv;
      if (x > max)
        max = x;
    }
    return max;
  }
}
