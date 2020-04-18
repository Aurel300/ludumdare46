class Arena {
  public var wm:Int; // with margins
  public var hm:Int;
  public var w:Int; // without margins
  public var h:Int;
  public var margin:Int; // player-inaccessible
  public var tiles:Array<Tile>;

  public function new(w:Int, h:Int, margin:Int) {
    this.w = w;
    this.h = h;
    this.wm = w + margin * 2;
    this.hm = h + margin * 2;
    this.margin = margin;
    tiles = [ for (y in 0...this.hm) for (x in 0...this.wm) {
      var t = new Tile(x - margin, y - margin, this);
      t.inMargin = (x < margin || y < margin || x >= this.wm - margin || y >= this.hm - margin);
      t;
    } ];
  }

  public inline function get(x:Int, y:Int):Tile {
    if (x + margin < 0 || y + margin < 0 || x + margin >= wm || y + margin >= hm)
      return Tile.nullTile;
    return tiles[(y + margin) * wm + (x + margin)];
  }

  public function tick():Void {
    for (t in tiles)
      t.tick();
  }
}
