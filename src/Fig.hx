@:using(Fig.FigTools)
enum Fig {
  Player(facingRight:Bool);
  It;
  Barrage(type:BulletType, dir:Dir, beat:Int);
  // Powerup
  // Coin
  // ...
}

class FigTools {
  public static function tick(f:Fig, at:Tile):Bool {
    return (switch (f) {
      case Barrage(type, dir, beat):
        if (Game.justBeat && Game.currentBeat == beat) {
          if (Game.damage(type, at.x, at.y)) false;
          else {
            at.arena.get(at.x + dir.x, at.y + dir.y).pushNext(f);
            false;
          }
        } else true;
      case _: true;
    });
  }
}
