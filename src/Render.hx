class Render {
  public static inline final W:Int = 300;
  public static inline final H:Int = 240;
  public static inline final WH:Int = 300 >> 1;
  public static inline final HH:Int = 240 >> 1;

  public static var rng = new Chance(0xBEBA1337);
  public static var cameraX:Float;
  public static var cameraY:Float;
  public static var cameraTX:Float;
  public static var cameraTY:Float;
  public static var cameraXI:Int; // rounded
  public static var cameraYI:Int;
  public static var shakeAmount:Int;
  public static var surf:Surface;
  public static var vertexCount:Int;
  public static var bufferPosition:Buffer;
  public static var bufferUV:Buffer;
  public static var bufferAlpha:Buffer;
  //public static var uniformLight:Uniform;
  public static var texW:Int = 512;
  public static var texH:Int = 512;
  public static var screen = Intro;
  public static var texRegions:Map<String, {x:Int, y:Int, w:Int, h: Int}>;
  // intro
  public static var introTimer:Int = 0;
  public static var introTut:Bool = false;
  // game
  public static var sweepTX:Int;
  public static var sweepTY:Int;
  public static var sweepDir:Dir;
  public static var sweepTimer:Int;
  public static var bgH:Array<{x:Float, vx:Float, c:Int, w:Int}>;
  public static var bgV:Array<{y:Float, vy:Float, c:Int, h:Int}>;
  public static var particles:Array<{x:Float, y:Float, vx:Float, vy:Float, reg:String, frame:Int, fh:Bool, fv:Bool}>;

  static final tileW = 70;
  static final tileH = 50;
  static final tileWH = tileW >> 1;
  static final tileHH = tileH >> 1;
  static final tileP = 5;
  static final tileWP = tileW + tileP;
  static final tileHP = tileH + tileP;
  static var arenaX:Int = 0;
  static var arenaY:Int = 0;

  public static function shake(am:Int):Void {
    shakeAmount += am;
    // TODO: limit ?
  }

  public static function sweep(fx:Int, fy:Int, dir:Dir):Void {
    sweepTX = fx;
    sweepTY = fy;
    sweepDir = dir;
    switch (dir) {
      case Up: sweepTY--;
      case Left: sweepTX--;
      case _:
    }
    sweepTimer = 6;
  }

  public static function spawnP(reg:String, x:Int, y:Int, vxb:Float, vyb:Float):Void {
    var tcX = arenaX + (x + 1) * tileWP + tileWH;
    var tcY = arenaY + (y + 1) * tileHP + tileHH;
    for (i in 0...5 + Std.random(10)) {
      particles.push({
        x: tcX + rng.rangeF(-30, 30),
        y: tcY + rng.rangeF(-15, 15),
        vx: rng.rangeF(-.9, .9) + vxb,
        vy: rng.rangeF(-.2, -.05) + vyb,
        reg: reg, frame: 0, fh: rng.bool(), fv: rng.bool()
      });
    }
  }

  public static function init(canvas:js.html.CanvasElement):Void {
    surf = new Surface({
      el: canvas,
      buffers: [
        bufferPosition = new Buffer("aPosition", F32, 3),
        bufferUV = new Buffer("aUV", F32, 2),
        bufferAlpha = new Buffer("aAlpha", F32, 2),
      ],
      uniforms: [
        //uniformLight = new Uniform("uLight", 4)
      ]
    });
    Main.aShade.loadSignal.on(asset -> {
      surf.loadProgram(asset.pack["vert.c"].text, asset.pack["frag.c"].text);
      var tr:haxe.DynamicAccess<Dynamic> = haxe.Json.parse(asset.pack["game.json"].text);
      texRegions = [ for (k => v in tr) k => v ];
      function rep(name:String, n:Int, xn:Int, yn:Int, m:Int, xm:Int, ym:Int):Void {
        var base = texRegions[name];
        for (j in 0...m) {
          for (i in 0...n) {
            texRegions[m < 2 ? '${name}_$i' : '${name}_$i/$j'] = {
              x: base.x + i * xn * base.w + j * xm * base.w,
              y: base.y + i * yn * base.h + j * ym * base.h,
              w: base.w,
              h: base.h
            };
          }
        }
      }
      function off(name:String, rname:String, xo:Int, yo:Int):Void {
        var base = texRegions[name];
        texRegions[rname] = {
          x: base.x + xo,
          y: base.y + yo,
          w: base.w,
          h: base.h
        };
      }
      rep("bullet_L", 4, 0, 1, 1, 0, 0);
      rep("bullet_U", 4, 1, 0, 1, 0, 0);
      off("bullet_L_0", "ibullet_L_0", 89, 0);
      off("bullet_L_1", "ibullet_L_1", 89, 0);
      off("bullet_L_2", "ibullet_L_2", 89, 0);
      off("bullet_L_3", "ibullet_L_3", 89, 0);
      off("bullet_LS1", "ibullet_LS1", 89, 0);
      off("bullet_LS2", "ibullet_LS2", 89, 0);
      off("bullet_LS3", "ibullet_LS3", 89, 0);
      off("bullet_U_0", "ibullet_U_0", 60, 0);
      off("bullet_U_1", "ibullet_U_1", 60, 0);
      off("bullet_U_2", "ibullet_U_2", 60, 0);
      off("bullet_U_3", "ibullet_U_3", 60, 0);
      off("bullet_US1", "ibullet_US1", 60, 0);
      off("bullet_US2", "ibullet_US2", 60, 0);
      off("bullet_US3", "ibullet_US3", 60, 0);
      rep("smoke_dark", 5, 1, 0, 1, 0, 0);
      rep("smoke_light", 5, 1, 0, 1, 0, 0);
      rep("star", 4, 1, 0, 1, 0, 0);
      rep("burst_blue", 5, 1, 0, 1, 0, 0);
      rep("burst_purple", 5, 1, 0, 1, 0, 0);
    });
    Main.aPng.loadSignal.on(asset -> {
      surf.updateTexture(0, asset.pack["game.png"].image);
    });
    Glewb.rate(delta -> {
      if (Main.aPng.loading || Main.aShade.loading || Main.aWav.loading || texRegions == null)
        return;
      surf.render(0x5692b5, () -> {
        vertexCount = 0;
        tick(delta);
      });
    });
    input.keyboard.up.on(key -> if (screen == GameOver && key == KeyR) restart());
    input.mouse.move.on(e -> {
      msx = Std.int(e.x / Fullscreen.lastSc);
      msy = Std.int(e.y / Fullscreen.lastSc);
    });
    input.mouse.up.on(e -> {
      if (screen.match(Intro | GameOver) && msAction != null) {
        msAction();
        msAction = null;
      }
    });
  }

  static function restart():Void {
    shakeAmount = 0;
    cameraX = cameraTX = WH;
    cameraY = cameraTY = HH;
    sweepTimer = 0;
    bgH = [];
    bgV = [];
    particles = [];
    screen = GamePlaying;
    Game.start(Classic(3, 3, 0));
  }

  static var msx:Int = 0;
  static var msy:Int = 0;
  static var msAction:Void->Void;
  static var visPhase = 0;
  public static function tick(delta:Float):Void {
    visPhase++;
    Music.autoTick(delta);
    Fullscreen.tick();
    var pal = texRegions["pal"];
    switch (screen) {
      case Intro:
        Music.selectMusic(PatIntro);
        var hx = Math.cos(introTimer / 29.) * 20.;
        var hy = Math.sin(introTimer / 70.) * 15.;
        var tx = 0.;
        if (introTimer < 80) hy -= (Math.pow((80 - introTimer) / 80, 2)) * H;
        if (introTimer < 110) tx -= (Math.pow((110 - introTimer) / 110, 2)) * W;
        drawRM(Std.int(WH + hx), Std.int(HH - 20 + hy), "title");
        var msel = Text.line(introTut ? (HH - 2) : (HH - 2), msy);
        Text.render(Std.int(8 + tx), introTut ? (HH - 2) : (HH - 2), introTut ? '$$bHow to play $$b

Move around with ` @ $$$$ #.
Hold $$bspace$$b to drag $$b$$sIT$$s$$b with you.
Your stamina drains when you hold $$b$$sIT$$s$$b!
Purple bullets hurt $$byou$$b, blue bullets hurt $$b$$sIT$$s$$b.
Keep $$b$$sIT$$s$$b (and yourself) alive. Good luck!

${msel == 8 ? ">>" : ">"} Main menu' : '$$bJarHeads$$b
A game by $$bAurel B%l&$$b <thenet.sk>
Made for Ludum Dare 46
${msel == 3 ? ">>" : ">"} How to play
${msel == 4 ? ">>" : ">"} New game
${msel == 5 ? ">>" : ">"} Music: ${Music.playing ? "on" : "off"}
${msel == 6 ? ">>" : ">"} Sound: ${Sfx.enabled ? "on" : "off"}
${msel == 7 ? ">>" : ">"} Fullscreen: ${Fullscreen.enabled ? "on" : "off"}
${msel == 8 ? ">>" : ">"} More games');
        msAction = tx > -5. ? (introTut ? (switch (msel) {
          case 8: () -> introTut = false;
          case _: null;
        }) : (switch (msel) {
          case 3: () -> introTut = true;
          case 4: () -> restart();
          case 5: () ->
            if (Music.playing) Music.stop();
            else Music.play();
          case 6: () -> Sfx.enabled = !Sfx.enabled;
          case 7: () -> Fullscreen.enabled = !Fullscreen.enabled;
          case 8: () -> js.Browser.window.open("https://www.thenet.sk/");
          case _: null;
        })) : null;
        introTimer++;
      case GameOver:
        Music.selectMusic(PatOver);
        var msel = Text.line(HH + 22, msy);
        Text.render(8, HH + 22, '$$bGame over!$$b
Final score: $$b${Game.score}$$b

${msel == 3 ? ">>" : ">"} Restart game
   (or press $$bR$$b to restart)
${msel == 5 ? ">>" : ">"} Submit score
${msel == 6 ? ">>" : ">"} Main menu');
        msAction = (switch (msel) {
          case 3: () -> restart();
          case 5: null; // () -> ...
          case 6: () -> { introTimer = 0; screen = Intro; };
          case _: null;
        });
      case GamePlaying:
        Music.selectMusic(PatGame);
        // logic
        Game.tick(delta);
        // make bg
        if (Game.justBeat && Game.waveUp != null) {
          var size = Game.currentBeat == 0 ? 70 : 30;
          var c = 7 - Game.currentBeat;
          switch (Game.waveUp.mainDir) {
            case Up:
              bgV.push({y: H, vy: -0.002, c: c, h: size});
            case Right:
              bgH.push({x: -size, vx: 0.002, c: c, w: size});
            case Down:
              bgV.push({y: -size, vy: 0.002, c: c, h: size});
            case Left:
              bgH.push({x: W, vx: -0.002, c: c, w: size});
          }
        }
        bgH = [ for (b in bgH) {
          if (b.x < -b.w || b.x > W) continue;
          drawFree(Std.int(b.x), 0, b.w, H, pal.x + 4, pal.y + 1 + b.c * 3, 1, 1);
          b.x += b.vx * Game.tempoBpm * delta;
          b;
        } ];
        bgV = [ for (b in bgV) {
          if (b.y < -b.h || b.y > H) continue;
          drawFree(0, Std.int(b.y), W, b.h, pal.x + 4, pal.y + 1 + b.c * 3, 1, 1);
          b.y += b.vy * Game.tempoBpm * delta;
          b;
        } ];
        // render
        cameraTX = WH - (Game.playerX * 20 - (Game.arena.w - 1) * 10);
        cameraTY = HH - (Game.playerY * 16 - (Game.arena.h - 1) * 8);
        cameraX = cameraX * .9 + cameraTX * .1;
        cameraY = cameraY * .9 + cameraTY * .1;
        cameraXI = Math.round(cameraX + rng.rangeF(-shakeAmount, shakeAmount) * .4);
        cameraYI = Math.round(cameraY + rng.rangeF(-shakeAmount, shakeAmount) * .4);
        if (shakeAmount > 0) shakeAmount--;
        var iframePhase = (Game.playerIframes % 300 < 150);
        var sframePhase = (!Game.playerSframes || visPhase % 30 < 15);
        // coordinates
        arenaX = -((Game.arena.wm * tileWP - tileP) >> 1);
        arenaY = -((Game.arena.hm * tileHP - tileP) >> 1);
        var ti = 0;
        // draw tile bg
        for (y in 0...Game.arena.hm) for (x in 0...Game.arena.wm) {
          var tile = Game.arena.tiles[ti++];
          if (!tile.inMargin) {
            var toy = 0;
            if (Game.playerX == x - 1 && Game.playerY == y - 1) toy = -2;
            //else if (Game.itX == x - 1 && Game.itY == y - 1) toy = -1;
            drawRC(arenaX + x * tileWP, arenaY + toy + y * tileHP, "tile");
          }
        }
        // draw tile figs
        ti = 0;
        var plOffY = texRegions["player_off"].h;
        for (y in 0...Game.arena.hm) for (x in 0...Game.arena.wm) {
          var tx = arenaX + x * tileWP;
          var ty = arenaY + y * tileHP;
          var tcX = arenaX + x * tileWP + tileWH;
          var tcY = arenaY + y * tileHP + tileHH;
          var tile = Game.arena.tiles[ti++];
          for (f in tile.figs.concat(tile.figsNext)) {
            switch (f) {
              case Player(_) if (iframePhase):
                if (Game.playerX == Game.itX && Game.playerY == Game.itY)
                  drawRC(tx, ty - plOffY, Game.itHeld ? "pair_up" : "pair_down");
                else
                  drawRC(tx, ty - plOffY, "player_lone");
              case It if (iframePhase):
                if (Game.playerX == Game.itX && Game.playerY == Game.itY) continue;
                drawRC(tx, ty - plOffY, "it_lone");
              case Barrage(t, Up, beat):
                if (beat == Game.currentBeat) {
                  var len = Std.int((1 - Game.tempoCtr / Game.tempo) * 50);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    var r = texRegions['${prefix}bullet_US2'];
                    drawRC(tx + 3 + i * 13, ty + tileHP - 13, '${prefix}bullet_US1');
                    draw(tx + 3 + i * 13 + cameraXI, ty + tileHP - 13 + 8 + cameraYI, r.x, r.y, r.w, len);
                    drawRC(tx + 3 + i * 13, ty + tileHP - 13 + 8 + len, '${prefix}bullet_US3');
                  }
                } else {
                  var bp = 0;
                  var toy = 0;
                  if (beat == (Game.currentBeat + 1) % 4 || beat == (Game.currentBeat + 2) % 4)
                    toy += 2;
                  if (beat == (Game.currentBeat + 1) % 4 && Game.tempoCtr + 2000/60. >= Game.tempo)
                    bp = 3;
                  else if (beat == (Game.currentBeat + 1) % 4)
                    bp = (visPhase % 10 < 5 ? 1 : 2);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    drawRC(tx + 3 + i * 13, ty - 13 + toy, '${prefix}bullet_U_$bp');
                  }
                }
              case Barrage(t, Down, beat):
                if (beat == Game.currentBeat) {
                  var len = Std.int((1 - Game.tempoCtr / Game.tempo) * 50);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    var r = texRegions['${prefix}bullet_US2'];
                    drawRC(tx + 3 + i * 13, ty - tileHP - 13 + 61, '${prefix}bullet_US1', false, true);
                    draw(tx + 3 + i * 13 + cameraXI, ty - tileHP - 13 + 11 + (50 - len) + cameraYI, r.x, r.y, r.w, len, false, true);
                    drawRC(tx + 3 + i * 13, ty - tileHP - 13 + (50 - len), '${prefix}bullet_US3', false, true);
                  }
                } else {
                  var bp = 0;
                  var toy = 0;
                  if (beat == (Game.currentBeat + 1) % 4 || beat == (Game.currentBeat + 2) % 4)
                    toy -= 2;
                  if (beat == (Game.currentBeat + 1) % 4 && Game.tempoCtr + 2000/60. >= Game.tempo)
                    bp = 3;
                  else if (beat == (Game.currentBeat + 1) % 4)
                    bp = (visPhase % 10 < 5 ? 1 : 2);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    drawRC(tx + 3 + i * 13, ty - 13 + toy, '${prefix}bullet_U_$bp', false, true);
                  }
                }
              case Barrage(t, Left, beat):
                if (beat == Game.currentBeat) {
                  var len = Std.int((1 - Game.tempoCtr / Game.tempo) * 70);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    var r = texRegions['${prefix}bullet_LS2'];
                    drawRC(tx + tileWP - 11, ty - 4 + i * 8, '${prefix}bullet_LS1');
                    draw(tx + tileWP + 8 - 11 + cameraXI, ty - 4 + i * 8 + cameraYI, r.x, r.y, len, r.h);
                    drawRC(tx + tileWP + 8 + len - 11, ty - 4 + i * 8, '${prefix}bullet_LS3');
                  }
                } else {
                  var bp = 0;
                  var tox = 0;
                  if (beat == (Game.currentBeat + 1) % 4 || beat == (Game.currentBeat + 2) % 4)
                    tox += 2;
                  if (beat == (Game.currentBeat + 1) % 4 && Game.tempoCtr + 2000/60. >= Game.tempo)
                    bp = 3;
                  else if (beat == (Game.currentBeat + 1) % 4)
                    bp = (visPhase % 10 < 5 ? 1 : 2);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    drawRC(tx + tox - 11, ty - 4 + i * 8, '${prefix}bullet_L_$bp');
                  }
                }
              case Barrage(t, Right, beat):
                if (beat == Game.currentBeat) {
                  var len = Std.int((1 - Game.tempoCtr / Game.tempo) * 70);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    var r = texRegions['${prefix}bullet_LS2'];
                    drawRC(tx - tileWP - 8 + 81, ty - 4 + i * 8, '${prefix}bullet_LS1', true);
                    draw(tx - tileWP - 8 + 11 + cameraXI + (70 - len), ty - 4 + i * 8 + cameraYI, r.x, r.y, len, r.h, true);
                    drawRC(tx - tileWP - 8 + (70 - len), ty - 4 + i * 8, '${prefix}bullet_LS3', true);
                  }
                } else {
                  var bp = 0;
                  var tox = 0;
                  if (beat == (Game.currentBeat + 1) % 4 || beat == (Game.currentBeat + 2) % 4)
                    tox -= 2;
                  if (beat == (Game.currentBeat + 1) % 4 && Game.tempoCtr + 2000/60. >= Game.tempo)
                    bp = 3;
                  else if (beat == (Game.currentBeat + 1) % 4)
                    bp = (visPhase % 10 < 5 ? 1 : 2);
                  for (i in 0...5) {
                    var prefix = (t == HurtsPlayer ? "" : (t == HurtsIt ? "i" : t == HurtsBoth && (i % 2) == (visPhase >> 3) % 2 ? "i" : ""));
                    drawRC(tx + tox - 8, ty - 4 + i * 8, '${prefix}bullet_L_$bp', true);
                  }
                }
              case _:
            }
          }
        }
        // player sweeps
        if (sweepTimer > 0) {
          var tx = arenaX + (sweepTX + 1) * tileWP;
          var ty = arenaY + (sweepTY + 1) * tileHP;
          var st = sweepTimer >= 3 ? 1 : 2;
          switch (sweepDir) {
            case Up: drawRC(tx, ty - plOffY, 'sweep_U$st');
            case Right: drawRC(tx, ty - plOffY, 'sweep_R$st');
            case Down: drawRC(tx, ty - plOffY, 'sweep_D$st');
            case Left: drawRC(tx, ty - plOffY, 'sweep_L$st');
            case _:
          }
          sweepTimer--;
        }
        // particles
        particles = [ for (p in particles) {
          if (p.frame >= 5) continue;
          drawRCM(Std.int(p.x), Std.int(p.y), '${p.reg}_${p.frame}', p.fh, p.fv);
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.02;
          p.frame += Math.random() > .8 ? 1 : 0;
          p;
        } ];
        // ui
        drawR(0, 0, "ui_top");
        if (iframePhase) {
          for (i in 0...Game.playerHp) {
            drawR(35 + i * 36, 0, "ui_hp_piece");
          }
        }
        if (sframePhase) {
          var hlen = Std.int((Game.playerStamina / Game.MAX_STAMINA) * 186);
          var r = texRegions["ui_hold1"];
          draw(26, 15, r.x, r.y, hlen, r.h);
          drawR(26 + hlen, 15, "ui_hold2");
        }
        var scoreT = '$$b${Game.score}';
        var scoreW = Text.width(scoreT);
        Text.render(W - 8 - scoreW, 4, scoreT);
        Text.render(8, H - 38, (Game.diff == 5 ? "$s" : "") + "$bBPM" + StringTools.lpad("", "!", Game.diff - 1));
        Text.renderDigits(8, H - 28, Game.tempoBpm);
    }
  }

  // with camera
  inline static function drawC(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, /*?alpha:Float = 1.0, ?dalpha:Float = 1.0, */?flip:Bool = false):Void {
    draw(x + cameraXI, y + cameraYI, tx, ty, tw, th, /*alpha, dalpha, */flip);
  }
  // with camera, centred
  inline static function drawCM(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, /*?alpha:Float = 1.0, ?dalpha:Float = 1.0, */?flip:Bool = false):Void {
    draw(x + cameraXI - (tw >> 1), y + cameraYI - (th >> 1), tx, ty, tw, th, /*alpha, dalpha, */flip);
  }

  static function drawR(x:Int, y:Int, n:String, ?flip:Bool = false, ?vflip:Bool = false):Void {
    if (!texRegions.exists(n)) {
      return;
    }
    var r = texRegions[n];
    draw(x, y, r.x, r.y, r.w, r.h, flip, vflip);
  }
  inline static function drawRC(x:Int, y:Int, n:String, ?flip:Bool = false, ?vflip:Bool = false):Void {
    drawR(x + cameraXI, y + cameraYI, n, flip, vflip);
  }
  static function drawRM(x:Int, y:Int, n:String, ?flip:Bool = false, ?vflip:Bool = false):Void {
    if (!texRegions.exists(n)) {
      return;
    }
    var r = texRegions[n];
    draw(x - (r.w >> 1), y - (r.h >> 1), r.x, r.y, r.w, r.h, flip, vflip);
  }
  inline static function drawRCM(x:Int, y:Int, n:String, ?flip:Bool = false, ?vflip:Bool = false):Void {
    drawRM(x + cameraXI, y + cameraYI, n, flip, vflip);
  }

  public static function draw(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, /*?alpha:Float = 1.0, ?dalpha:Float = 1.0, */?flip:Bool = false, ?vflip:Bool = false):Void {
    surf.indexBuffer.writeUI16(vertexCount);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 2);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 3);
    surf.indexBuffer.writeUI16(vertexCount + 2);

    var gx1:Float = ((flip ? x + tw : x) - WH) / WH;
    var gx2:Float = ((flip ? x : x + tw) - WH) / WH;
    var gy1:Float = (H - (vflip ? y + th : y) - HH) / HH;
    var gy2:Float = ((H - (vflip ? y : y + th)) - HH) / HH;

    bufferPosition.writeF32(gx1);
    bufferPosition.writeF32(gy1);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx2);
    bufferPosition.writeF32(gy1);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx1);
    bufferPosition.writeF32(gy2);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx2);
    bufferPosition.writeF32(gy2);
    bufferPosition.writeF32(0);

    var gtx1 = (tx) / texW;
    var gtx2 = (tx + tw) / texW;
    var gty1 = (ty) / texH;
    var gty2 = (ty + th) / texH;

    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty2);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty2);

    vertexCount += 4;
    if (vertexCount > 400) {
      surf.renderFlush();
      vertexCount = 0;
    }
  }

  public static function drawFree(x:Int, y:Int, w:Int, h:Int, tx:Int, ty:Int, tw:Int, th:Int):Void {
    surf.indexBuffer.writeUI16(vertexCount);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 2);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 3);
    surf.indexBuffer.writeUI16(vertexCount + 2);

    var gx1:Float = ((x + w) - WH) / WH;
    var gx2:Float = (x - WH) / WH;
    var gy1:Float = (H - y - HH) / HH;
    var gy2:Float = ((H - (y + h)) - HH) / HH;

    bufferPosition.writeF32(gx1);
    bufferPosition.writeF32(gy1);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx2);
    bufferPosition.writeF32(gy1);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx1);
    bufferPosition.writeF32(gy2);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx2);
    bufferPosition.writeF32(gy2);
    bufferPosition.writeF32(0);

    var gtx1 = (tx) / texW;
    var gtx2 = (tx + tw) / texW;
    var gty1 = (ty) / texH;
    var gty2 = (ty + th) / texH;

    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty2);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty2);

    vertexCount += 4;
    if (vertexCount > 400) {
      surf.renderFlush();
      vertexCount = 0;
    }
  }
}

enum RenderScreen {
  Intro;
  GamePlaying;
  GameOver;
}
