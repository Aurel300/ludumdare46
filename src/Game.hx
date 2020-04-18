class Game {
  public static final IFRAME_LENGTH_MS = 2000.;
  public static final MAX_HP = 5;
  public static final MAX_STAMINA = 50.;
  public static final RATE_STAMINA_USE = 0.5;
  public static final RATE_STAMINA_REPLENISH = 0.7;
  public static final RATE_STAMINA_REPLENISH_S = 0.3;

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
  // beats
  public static var justBeat:Bool; // pseudo-event
  public static var currentBeat:Int;
  public static var beatMax:Int;
  public static var tempo:Float; // ms per beat
  public static var tempoBpm:Float;
  public static var tempoCtr:Float; // ms counter
  // controls
  public static var ctrlMovingTimer:Float;

  static inline function makeTempo(bpm:Float):Float {
    return 1000. / (bpm / 60.);
  }

  public static function init():Void {
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

  public static function damage(dmgPlayer:Bool, x:Int, y:Int):Bool {
    var didHit = (dmgPlayer ? (playerX == x && playerY == y) : (itX == x && itY == y));
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
      case Player(ff): facing = ff; false;
      case Barrage(true, dir, _) if (dir == Dir.fromDeltaOpp(dx, dy)): !damage(true, playerX, playerY);
      case _: true;
    });
    playerX = nx;
    playerY = ny;
    arena.get(playerX, playerY).push(Player(dx > 0 || (dx >= 0 && facing)));
    if (itHeld) {
      arena.get(itX, itY).filter(f -> switch (f) {
        case It: false;
        case Barrage(false, dir, _) if (dir == Dir.fromDeltaOpp(dx, dy)): !damage(false, itX, itY);
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
    tempo = makeTempo(tempoBpm = 240);
    tempoCtr = 0;
    playerHp = MAX_HP;
    playerStamina = MAX_STAMINA;
    playerIframes = 0;
    playerSframes = false;
    playerX = itX = initW >> 1;
    playerY = itY = initH >> 1;
    arena.get(playerX, playerY).push(Player(true));
    arena.get(itX, itY).push(It);
    itHeld = false;
    ctrlMovingTimer = 0;
  }

  public static function tick(delta:Float):Void {
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
      playerStamina -= RATE_STAMINA_USE; // tempo, delta
      if (playerStamina < 0) {
        playerStamina = 0;
        itHeld = false;
        playerSframes = true;
        Render.shake(5);
      }
    } else {
      playerStamina += (playerSframes ? RATE_STAMINA_REPLENISH_S : RATE_STAMINA_REPLENISH);
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
      }
      if (move) {
        ctrlMovingTimer += 0.05; // tempo? delta? on beats only?
        if (ctrlMovingTimer >= 1) {
          playerMove(moveX, moveY, false);
          ctrlMovingTimer = 0;
        }
      } else {
        ctrlMovingTimer = 0;
      }
    }
    // logic
    arena.tick();
    if (justBeat && currentBeat == 0) {
      // spawn bullets randomly (TODO: temporary)
      var spawn = rng.member([
        {x: -1, y: 0, d: Dir.Right},
        {x: -1, y: 1, d: Dir.Right},
        {x: -1, y: 2, d: Dir.Right},
        {x: 0, y: -1, d: Dir.Down},
        {x: 1, y: -1, d: Dir.Down},
        {x: 2, y: -1, d: Dir.Down},
        {x: arena.w, y: 0, d: Dir.Left},
        {x: arena.w, y: 1, d: Dir.Left},
        {x: arena.w, y: 2, d: Dir.Left},
        {x: 0, y: arena.h, d: Dir.Up},
        {x: 1, y: arena.h, d: Dir.Up},
        {x: 2, y: arena.h, d: Dir.Up},
      ]);
      arena.get(spawn.x, spawn.y).push(Barrage(rng.bool(), spawn.d, 0));
    }
  }
}

enum GameMode {
  Classic(initW:Int, initH:Int, time:Int);
  Infinite(initW:Int, initH:Int);
}
