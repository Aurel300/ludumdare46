using Lambda;

class Wave {
  public static var WAVES:Array<WaveDesc> = [];

  public static function init(d:String):Void {
    WAVES = [ for (d in d.split("\n").filter(l -> l.charAt(0) != "#").join("\n").split("\n---\n")) {
      var ss = d.split("\n");
      var minDiff = Std.parseInt(ss.shift());
      var maxDiff = Std.parseInt(ss.shift());
      var ss = ss.join("\n").split("\n*\n").map(sub -> sub.split("\n"));
      var spawn = [ for (sub in 0...ss.length) for (at in 0...ss[sub].length) {
        [ for (pos in 0...3) {
          at: at,
          pos: pos,
          other: sub,
          type: (switch (ss[sub][at].charAt(pos)) {
            case "P": Fixed(HurtsPlayer);
            case "I": Fixed(HurtsIt);
            case "B": Fixed(HurtsBoth);
            case "1": Polar(0);
            case "2": Polar(1);
            case ".": Skip;
            case c: throw 'invalid wave char $c';
          })
        } ];
      } ].flatten();
      {minDiff: minDiff, maxDiff: maxDiff, sub: ss.length, spawn: spawn};
    } ];
  }

  public static function spawn(diff:Int, w:Int, h:Int):Null<Wave> {
    var candidates = WAVES.filter(w -> {
      if (w.minDiff != null && diff < w.minDiff) return false;
      if (w.maxDiff != null && diff > w.maxDiff) return false;
      return true;
    });
    if (candidates.length == 0)
      return null;
    var desc = Game.rng.member(candidates);
    var dir = Game.rng.member(Dir.ALL);
    var reflect = Game.rng.bool();
    var polarity = Game.rng.bool() ? 0 : 1;
    var cw = Game.rng.bool();
    var spawns = [];
    function add(dir:Dir, reflect:Bool, other:Int):Void {
      var bx = 0; // base
      var by = 0;
      var mx = 0; // pos mult
      var my = 0;
      switch (dir) {
        case Up: by = h;
        case Right: bx = -1;
        case Down: reflect = !reflect; by = -1;
        case Left: reflect = !reflect; bx = w;
      }
      if (bx == 0) {
        mx = 1;
        if (reflect) {
          bx = w - 1;
          mx = -1;
        }
      } else {
        my = 1;
        if (reflect) {
          by = h - 1;
          my = -1;
        }
      }
      for (d in desc.spawn) if (d.other == other) spawns.push({
        at: d.at,
        x: bx + d.pos * mx,
        y: by + d.pos * my,
        d: dir,
        type: d.type
      });
    }
    var odir = dir;
    for (i in 0...desc.sub) {
      add(dir, reflect, i);
      dir = cw ? dir.cw : dir.acw;
    }
    spawns.sort((a, b) -> a.at - b.at);
    return new Wave(spawns, odir, Game.currentBeat, polarity);
  }

  public var desc:Array<WaveSpawn>;
  public var mainDir:Dir;
  public var onBeat:Int;
  public var polarity:Int;
  public var pos:Int;

  public function new(desc:Array<WaveSpawn>, mainDir:Dir, onBeat:Int, polarity:Int) {
    this.desc = desc;
    this.mainDir = mainDir;
    this.onBeat = onBeat;
    this.polarity = polarity;
    pos = 0;
  }

  // true -> wave has more spawns
  public function beat():Bool {
    if (Game.currentBeat == onBeat) {
      while (desc.length > 0 && pos >= desc[0].at) {
        var d = desc.shift();
        var bt = (switch (d.type) {
          case Fixed(t): t;
          case Polar(n): [BulletType.HurtsPlayer, BulletType.HurtsIt][(n + polarity) % 2];
          case Skip: continue;
        });
        Game.arena.get(d.x, d.y).push(Barrage(bt, d.d, onBeat));
      }
      pos++;
    }
    return desc.length > 0;
  }
}

typedef WaveDesc = {
  minDiff:Null<Int>,
  maxDiff:Null<Int>,
  sub:Int,
  spawn:Array<WaveDescSpawn>
};

typedef WaveDescSpawn = {
  at:Int,
  pos:Int,
  other:Int,
  type:WaveSpawnType
};

typedef WaveSpawn = {
  at:Int,
  x:Int,
  y:Int,
  d:Dir,
  type:WaveSpawnType
};

enum WaveSpawnType {
  Fixed(t:BulletType);
  Polar(n:Int);
  Skip;
}
