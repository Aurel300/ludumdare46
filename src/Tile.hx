class Tile {
  public static final nullTile:Tile = new Tile(0, 0, null);

  public var x:Int;
  public var y:Int;
  public var arena:Arena;
  public var figs:Array<Fig> = [];
  public var figsNext:Array<Fig> = [];
  public var inMargin:Bool = false;

  public function new(x:Int, y:Int, arena:Arena) {
    this.x = x;
    this.y = y;
    this.arena = arena;
  }

  public function tick():Void {
    if (arena == null) return;
    figs = figs.filter(Fig.FigTools.tick.bind(_, this)).concat(figsNext);
    figsNext.resize(0);
  }

  public inline function push(f:Fig):Void {
    if (arena == null) return;
    figs.push(f);
  }

  public inline function pushNext(f:Fig):Void {
    if (arena == null) return;
    figsNext.push(f);
  }

  public inline function filter(f:Fig->Bool):Void {
    if (arena == null) return;
    figs = figs.filter(f);
  }

  public inline function any(f:Fig->Bool):Bool {
    if (arena == null) return false;
    for (fig in figs)
      if (f(fig))
        return true;
    return false;
  }
}
