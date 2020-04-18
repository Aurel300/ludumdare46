@:using(Fig.FigTools)
enum Fig {
  Player(facingRight:Bool);
  It;
  Barrage(hurtsPlayer:Bool, dir:Dir, beat:Int);
  // Powerup
  // Coin
  // ...
}

class FigTools {
  public static function tick(f:Fig, at:Tile):Bool {
    return (switch (f) {
      case Barrage(hurtsPlayer, dir, beat):
        if (Game.justBeat && Game.currentBeat == beat) {
          if (Game.damage(hurtsPlayer, at.x, at.y)) false;
          else {
            at.arena.get(at.x + dir.x, at.y + dir.y).pushNext(f);
            false;
          }
        } else true;
      case _: true;
    });
  }
}
