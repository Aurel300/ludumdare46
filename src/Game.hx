class Game {
  public static final IFRAME_LENGTH_MS = 2000.;
  public static final MAX_HP = 5;
  public static final MAX_STAMINA = 50.;
  public static final RATE_STAMINA_USE = 0.3;
  public static final RATE_STAMINA_REPLENISH = 0.5;
  public static final RATE_STAMINA_REPLENISH_S = 0.2;
  public static final BASE_TEMPO = 190.;
  public static final LINEAR_TEMPO = 0.2; // per beat

  public static final PROG_MUL = 8;
  public static final PROGRESSION = [
      0 => () -> { diff = 1; },
     10 => () -> { diff = 1; baseBpm = BASE_TEMPO + 30.; },
     20 => () -> { diff = 2; baseBpm = BASE_TEMPO - 20.; },
     25 => () -> { diff = 2; baseBpm = BASE_TEMPO - 10.; },
     40 => () -> { diff = 2; baseBpm = BASE_TEMPO; },
     43 => () -> { diff = 2; baseBpm = BASE_TEMPO + 10.; },
     46 => () -> { diff = 2; baseBpm = BASE_TEMPO + 20.; },
     60 => () -> { diff = 3; baseBpm = BASE_TEMPO; },
     65 => () -> { diff = 3; baseBpm = BASE_TEMPO + 40.; },
     70 => () -> { diff = 3; baseBpm = BASE_TEMPO + 80.; },
     75 => () -> { diff = 3; baseBpm = BASE_TEMPO + 120.; },
     90 => () -> { diff = 1; baseBpm = BASE_TEMPO + 240.; },
    100 => () -> { diff = 2; baseBpm = BASE_TEMPO + 120.; },
    110 => () -> { diff = 4; baseBpm = BASE_TEMPO + 40.; },
    130 => () -> { diff = 5; baseBpm = BASE_TEMPO + 20.; },
  ];

  public static var rng:Chance = new Chance(0x3821BEBA);
  public static var arena:Arena;
  // state
  public static var playerHp:Int;
  public static var playerStamina:Float;
  public static var playerIframes:Float;
  public static var playerSframes:Bool;
  public static var playerX:Int;
  public static var playerY:Int;
  public static var itX:Int;
  public static var itY:Int;
  public static var itHeld:Bool;
  public static var waves:Array<Wave>;
  public static var waveUp:Wave;
  public static var waveDown:Wave;
  // difficulty
  public static var diff:Int;
  // beats
  public static var justBeat:Bool; // pseudo-event
  public static var currentBeat:Int;
  public static var beatMax:Int;
  public static var tempo:Float; // ms per beat
  public static var baseBpm:Float;
  public static var tempoBpm:Float;
  public static var tempoCtr:Float; // ms counter
  public static var totalBeat:Int;
  // controls
  public static var ctrlMovingTimer:Float;
  public static var ctrlMoved:Bool;

  static inline function makeTempo(bpm:Float):Float {
    return 1000. / (bpm / 60.);
  }

  public static function init():Void {
    rng = new Chance(Std.int(Math.random() * 0x7FFFFFFF));
    input.keyboard.down.on(function (key):Void {
      if (Render.screen != GamePlaying) return;
      switch (key) { // TODO: check pause, etc first
        case ArrowUp: playerMove(0, -1, true);
        case ArrowDown: playerMove(0, 1, true);
        case ArrowLeft: playerMove(-1, 0, true);
        case ArrowRight: playerMove(1, 0, true);
        case Space:
          if (itHeld)
            itHeld = false;
          else if (playerX == itX && playerY == itY && !playerSframes)
            itHeld = true;
        case _:
      }
    });
  }

  public static function damage(type:BulletType, x:Int, y:Int):Bool {
    var didHit = (switch (type) {
      case HurtsPlayer: playerX == x && playerY == y;
      case HurtsIt: itX == x && itY == y;
      case HurtsBoth: (playerX == x && playerY == y) || (itX == x && itY == y);
    });
    if (didHit && playerIframes == 0) {
      playerHp--;
      playerIframes = IFRAME_LENGTH_MS;
      Render.shake(10);
      if (playerHp <= 0) {
        Render.screen = GameOver;
      }
    }
    return didHit;
  }

  static function playerMove(dx:Int, dy:Int, tap:Bool):Void {
    if (tap && itHeld)
      return;
    var nx = playerX + dx;
    var ny = playerY + dy;
    if (nx < 0 || ny < 0 || nx >= arena.w || ny >= arena.h) return;
    var facing = false;
    arena.get(playerX, playerY).filter(f -> switch (f) {
      case Player(ff):
        facing = ff;
        false;
      case Barrage(t = (HurtsPlayer | HurtsBoth), dir, _) if (dir == Dir.fromDeltaOpp(dx, dy)):
        !damage(t, playerX, playerY);
      case _: true;
    });
    playerX = nx;
    playerY = ny;
    arena.get(playerX, playerY).push(Player(dx > 0 || (dx >= 0 && facing)));
    if (itHeld) {
      arena.get(itX, itY).filter(f -> switch (f) {
        case It: false;
        case Barrage(t = (HurtsIt | HurtsBoth), dir, _) if (dir == Dir.fromDeltaOpp(dx, dy)):
          !damage(t, itX, itY);
        case _: true;
      });
      itX = playerX;
      itY = playerY;
      arena.get(itX, itY).push(It);
    }
  }

  public static function start(mode:GameMode):Void {
    var initW;
    var initH;
    switch (mode) {
      case Classic(w, h, time):
        initW = w;
        initH = h;
      case Infinite(w, h):
        initW = w;
        initH = h;
    }
    arena = new Arena(initW, initH, 1);
    currentBeat = 0;
    beatMax = 4;
    tempo = makeTempo(tempoBpm = baseBpm = BASE_TEMPO);
    tempoCtr = 0;
    totalBeat = 0;
    playerHp = MAX_HP;
    playerStamina = MAX_STAMINA;
    playerIframes = 0;
    playerSframes = false;
    playerX = itX = initW >> 1;
    playerY = itY = initH >> 1;
    arena.get(playerX, playerY).push(Player(true));
    arena.get(itX, itY).push(It);
    itHeld = false;
    waves = [];
    waveUp = null;
    waveDown = null;
    diff = 0;
    ctrlMovingTimer = 0;
    ctrlMoved = false;
  }

  public static function tick(delta:Float):Void {
    var tempoMul = tempoBpm / BASE_TEMPO;
    // beats
    tempoCtr += delta;
    justBeat = false;
    if (playerIframes > 0) {
      playerIframes -= delta;
      if (playerIframes < 0) playerIframes = 0;
    }
    if (tempoCtr >= tempo) {
      tempoCtr -= tempo;
      currentBeat++;
      currentBeat %= beatMax;
      justBeat = true;
    }
    // stamina
    if (itHeld) {
      playerStamina -= RATE_STAMINA_USE * tempoMul; // tempo, delta
      if (playerStamina < 0) {
        playerStamina = 0;
        itHeld = false;
        playerSframes = true;
        Render.shake(5);
      }
    } else {
      playerStamina += (playerSframes ? RATE_STAMINA_REPLENISH_S * tempoMul : RATE_STAMINA_REPLENISH * tempoMul);
      if (playerStamina >= MAX_STAMINA) {
        playerStamina = MAX_STAMINA;
        playerSframes = false;
      }
    }
    // hold controls
    if (itHeld) {
      var moveX = (input.keyboard.held[ArrowLeft] ? -1 : 0) + (input.keyboard.held[ArrowRight] ? 1 : 0);
      var moveY = (input.keyboard.held[ArrowUp] ? -1 : 0) + (input.keyboard.held[ArrowDown] ? 1 : 0);
      var move = false;
      if (moveX != 0 && moveY != 0) {
        // pass
      } else if (moveX != 0 || moveY != 0) {
        move = true;
      } else {
        ctrlMoved = false;
      }
      if (move && !ctrlMoved) {
        ctrlMovingTimer += 0.05 * tempoMul; // tempo? delta? on beats only?
        if (ctrlMovingTimer >= 1) {
          ctrlMoved = true;
          playerMove(moveX, moveY, false);
          ctrlMovingTimer = 0;
        }
      } else {
        ctrlMovingTimer = 0;
      }
    }
    // logic
    arena.tick();
    if (justBeat) {
      if (PROGRESSION.exists(Std.int(totalBeat / PROG_MUL))) {
        PROGRESSION[Std.int(totalBeat / PROG_MUL)]();
        tempoCtr = 0;
      }
      tempoBpm = baseBpm + totalBeat * LINEAR_TEMPO;
      tempo = makeTempo(tempoBpm);
      totalBeat++;
      waves = waves.filter(w -> {
        var ret = w.beat();
        if (!ret) {
          if (w == waveUp) waveUp = null;
          if (w == waveDown) waveDown = null;
        }
        ret;
      });
      if (waveUp == null && currentBeat == 0) {
        var s = Wave.spawn(diff, arena.w, arena.h);
        if (s != null)
          waves.push(waveUp = s);
      }
      /*
      if (waveDown == null && currentBeat == 2) {
        var s = Wave.spawn(0, arena.w, arena.h);
        if (s != null)
          waves.push(waveDown = s);
      }
      */
    }
  }
}

enum GameMode {
  Classic(initW:Int, initH:Int, time:Int);
  Infinite(initW:Int, initH:Int);
}
