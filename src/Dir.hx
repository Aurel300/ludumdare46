enum abstract Dir(Int) from Int to Int {
  public static final ALL = [Up, Right, Down, Left];

  public static function fromDelta(x:Int, y:Int):Dir {
    return (switch [x, y] {
      case [0, -1]: Up;
      case [1, 0]: Right;
      case [0, 1]: Down;
      case _: Left;
    });
  }

  public static function fromDeltaOpp(x:Int, y:Int):Dir {
    return (switch [x, y] {
      case [0, -1]: Down;
      case [1, 0]: Left;
      case [0, 1]: Up;
      case _: Right;
    });
  }

  var Up = 0;
  var Right;
  var Down;
  var Left;

  public var cw(get, never):Dir;
  function get_cw():Dir {
    return (this + 1) % 4;
  }

  public var acw(get, never):Dir;
  function get_acw():Dir {
    return (this + 3) % 4;
  }

  public var x(get, never):Int;
  function get_x():Int {
    return (switch (this) {
      case Left: -1;
      case Right: 1;
      case _: 0;
    });
  }

  public var y(get, never):Int;
  function get_y():Int {
    return (switch (this) {
      case Up: -1;
      case Down: 1;
      case _: 0;
    });
  }
}
