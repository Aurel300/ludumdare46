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
  public static var vertexCount = 0;
  public static var bufferPosition:Buffer;
  public static var bufferUV:Buffer;
  public static var bufferAlpha:Buffer;
  //public static var uniformLight:Uniform;
  public static var texW:Int = 512;
  public static var texH:Int = 512;
  public static var renderCalls = 0;
  public static var screen = Intro;

  // debug
  public static var debugText:String->Void;
  public static var debugHp:String->Void;

  public static function shake(am:Int):Void {
    shakeAmount += am;
    // TODO: limit ?
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
    });
    /*
    Main.aPng.loadSignal.on(asset -> {
      //trace("png loaded");
      surf.updateTexture(0, asset.pack["game.png"].image);
    });
    */
    Glewb.rate(delta -> {
      //if (Main.aPng.loading)
      //  return;
      surf.render(0xCCCCCC, () -> {
        vertexCount = 0;
        renderCalls = 1;
        // Text.baseShake++;
        // Text.shakePhase = 0;
        tick(delta);
        // debugRender('$renderCalls');
      });
    });
    debugText = Debug.text("Text");
    debugHp = Debug.text("HP");

      /*
    Main.input.mouse.up.on(e -> {
      var x = (e.x / 2);
      var y = (e.y / 2);
      if (x >= W - 3 - 32 && x < W - 3 - 32 + 16 && y >= 3 && y < 3 + 16)
        Sfx.enable(!Sfx.enabled);
      if (x >= W - 3 - 16 && x < W - 3 - 16 + 16 && y >= 3 && y < 3 + 16)
        Music.enable(!Music.enabled);
    });
      */
    input.keyboard.up.on(function (key):Void {
      switch [screen, key] {
        case [Intro | GameOver, Space]:
          shakeAmount = 0;
          cameraX = cameraTX = WH;
          cameraY = cameraTY = HH;
          screen = GamePlaying;
          Game.start(Classic(3, 3, 0));
        case _:
      }
    });
  }

  public static function tick(delta:Float):Void {
    switch (screen) {
      case Intro:
        debugText("space to start");
      case GamePlaying:
        debugText("game in progress");
        // logic
        Game.tick(delta);
        // debug
        debugHp('${Game.playerHp}' + (Game.playerIframes > 0 ? " (inv)" : ""));
        // render
        cameraTX = WH - (Game.playerX * 20 - (Game.arena.w - 1) * 10);
        cameraTY = HH - (Game.playerY * 16 - (Game.arena.h - 1) * 8);
        cameraX = cameraX * .9 + cameraTX * .1;
        cameraY = cameraY * .9 + cameraTY * .1;
        cameraXI = Math.round(cameraX + rng.rangeF(-shakeAmount, shakeAmount) * .4);
        cameraYI = Math.round(cameraY + rng.rangeF(-shakeAmount, shakeAmount) * .4);
        if (shakeAmount > 0) shakeAmount--;
        var iframePhase = (Game.playerIframes % 300 < 150);
        var sframePhase = (!Game.playerSframes || Game.playerStamina % 10 < 5);
        // coordinates
        var tileW = 70;
        var tileH = 50;
        var tileWH = tileW >> 1;
        var tileHH = tileH >> 1;
        var tileP = 5;
        var tileWP = tileW + tileP;
        var tileHP = tileH + tileP;
        var arenaX = -((Game.arena.wm * tileWP - tileP) >> 1);
        var arenaY = -((Game.arena.hm * tileHP - tileP) >> 1);
        var ti = 0;
        // draw tile bg
        for (y in 0...Game.arena.hm) for (x in 0...Game.arena.wm) {
          var tile = Game.arena.tiles[ti++];
          if (!tile.inMargin) {
            drawC(arenaX + x * tileWP, arenaY + y * tileHP, 0, 0, tileW, tileH);
          }
        }
        // draw tile figs
        ti = 0;
        for (y in 0...Game.arena.hm) for (x in 0...Game.arena.wm) {
          var tcX = arenaX + x * tileWP + tileWH;
          var tcY = arenaY + y * tileHP + tileHH;
          var tile = Game.arena.tiles[ti++];
          for (f in tile.figs.concat(tile.figsNext)) {
            switch (f) {
              case Player(_) if (iframePhase):
                drawCM(tcX, tcY, 1, 0, 10, 15);
              case It if (iframePhase):
                drawCM(tcX, tcY + (Game.itHeld ? -10 : 10), 0, 1, 20, 10);
              case Barrage(pl, Up, beat):
                var off = Game.currentBeat == beat ? Std.int((1 - Game.tempoCtr / Game.tempo) * tileH) : 0;
                drawCM(tcX, tcY + tileHH + (off >> 1), pl ? 1 : 0, pl ? 0 : 1, tileW - 10, 10 + off);
              case Barrage(pl, Down, beat):
                var off = Game.currentBeat == beat ? Std.int((1 - Game.tempoCtr / Game.tempo) * tileH) : 0;
                drawCM(tcX, tcY - tileHH - (off >> 1), pl ? 1 : 0, pl ? 0 : 1, tileW - 10, 10 + off);
              case Barrage(pl, Left, beat):
                var off = Game.currentBeat == beat ? Std.int((1 - Game.tempoCtr / Game.tempo) * tileW) : 0;
                drawCM(tcX + tileWH + (off >> 1), tcY, pl ? 1 : 0, pl ? 0 : 1, 10 + off, tileH - 10);
              case Barrage(pl, Right, beat):
                var off = Game.currentBeat == beat ? Std.int((1 - Game.tempoCtr / Game.tempo) * tileW) : 0;
                drawCM(tcX - tileWH - (off >> 1), tcY, pl ? 1 : 0, pl ? 0 : 1, 10 + off, tileH - 10);
              case _:
            }
          }
        }
        // ui
        draw(5, 7, 0, 0, 200, 5);
        if (iframePhase)
          draw(5, 5, 1, 0, Std.int((Game.playerHp / Game.MAX_HP) * 200), 5);
        draw(5, 17, 0, 0, 200, 5);
        if (sframePhase)
          draw(5, 15, 1, 1, Std.int((Game.playerStamina / Game.MAX_STAMINA) * 200), 5);
      case GameOver:
        debugText("game over, space to restart");
    }
    /*
    if (player == null || player.room == null)
      return;
    for (actor in player.room.actors)
      actor.tick(delta);
    Music.tick(
      player.room.id == 0 ? -1 : ((player.hp > 3 || player.hp == 0) ? 0 : (player.hp > 1 ? 1 : 2)),
      player.room.id == 0 ? -1 : (player.room.enemies > 0 ? 1 : 0),
      player.room.melody
    );
    cameraX = cameraX * .95 + (player.room.x * Tile.TW + (player.x:Float) - WH) * .05;
    cameraVX = cameraVX * .993 + (player.direction ? 40 : -40) * .007;
    cameraY = cameraY * .95 + (player.room.y * Tile.TH + (player.y:Float) - HH) * .05;
    lightX = lightX * .95 + (player.x.round() + player.room.x * Tile.TW - (cameraX + cameraVX)) * .05;
    lightY = lightY * .95 + (player.y.round() + player.room.y * Tile.TH - (cameraY)) * .05;
    uniformLight.dataF32[0] = lightX;
    uniformLight.dataF32[1] = lightY;
    uniformLight.dataF32[2] = lightRadius + Math.sin(lightPhase / 100.0) * 0.2 + Math.random() * 0.01;
    uniformLight.dataF32[3] = 0.7 * lightRadius + Math.sin(130 + lightPhase / 140.0) * 0.2 + Math.random() * 0.01;
    lightPhase++;
    lightRadius = 0.4 + (player.hp / player.skills.maxHp) * 0.4;
    var rendered = 0;
    var shX = 0.0;
    var shY = 0.0;
    if (shakeAmount > 0) {
      var min = shakeAmount / 25;
      if (min < 1) min = 1;
      shX = Particle.ch.float(min) * Particle.ch.float(min) * Particle.ch.sign();
      shY = Particle.ch.float(min) * Particle.ch.float(min) * Particle.ch.sign();
      if (shakeAmount > 60)
        shakeAmount -= 3;
      else if (shakeAmount > 30)
        shakeAmount -= 2;
      else
        shakeAmount--;
    }
    function renderRoom(room:Room):Void {
      room.tick();
      room.enemies = 0;
      room.alpha = room.alpha * .93 + (room == player.room ? 1.0 : .3) * .07;
      var ox:Int = room.x * Tile.TW - Math.round(cameraX + cameraVX + shX);
      var oy:Int = room.y * Tile.TH - Math.round(cameraY + shY);
      if (ox < -room.w * Tile.TW || ox >= W || oy < -room.h * Tile.TH || oy >= H)
        return;
      rendered++;
      for (layer in -2...3) {
        var i = -1;
        for (y in 0...room.h) for (x in 0...room.w) {
          i++;
          if (room.tiles[i].edge == Outside)
            continue;
          for (vis in room.tiles[i].vis[layer + 2]) {
            //var selected = (layer == 0 && room == player.room && x == player.punchX && y == player.punchY && room.tiles[i].edge == Edge);
            draw(
              ox + x * Tile.TW + vis.tox,
              oy + y * Tile.TH + vis.toy,
              vis.tx, vis.ty, vis.tw, vis.th,
              1.0, room.alpha, vis.tflip
            );
            if (vis.text != null)
              Text.render(ox + x * Tile.TW + vis.tox, oy + y * Tile.TH + vis.toy, vis.text, .2, 1.3 + room.alpha);
          }
        }
        if (layer == 0) {
          for (actor in room.actors) {
            if (actor == player)
              continue;
            if (actor.type == Enemy)
              room.enemies++;
            draw(
              ox + actor.x.round() + actor.tox,
              oy + actor.y.round() + actor.toy,
              actor.baseTx + actor.tx,
              actor.baseTy + actor.ty,
              actor.tw, actor.th, actor.alpha, room.alpha + actor.glow, actor.tflip
            );
          }
          if (room == player.room)
            draw(
              ox + player.x.round() + player.tox,
              oy + player.y.round() + player.toy,
              player.baseTx + player.tx,
              player.baseTy + player.ty,
              player.tw, player.th, player.alpha, room.alpha + player.glow, player.tflip
            );
          room.particles = [ for (p in room.particles) {
            draw(
              ox + p.x.round(),
              oy + p.y.round(),
              p.tx + ((p.frameOff + Std.int(p.phase / p.xpp)) % p.frameMod) * 16, p.ty,
              16, 16, p.dalpha, room.alpha + p.glow, p.tflip
            );
            p.x += p.vx;
            p.y += p.vy;
            p.vx += p.ax;
            p.vy += p.ay;
            p.dalpha += p.dalphaV;
            p.phase++;
            if (p.phase >= p.frames * p.xpp || p.dalpha < 0)
              continue;
            p;
          } ];
        }
      }
    }
    for (room in Room.map) {
      if (room == player.room)
        continue;
      renderRoom(room);
    }
    renderRoom(player.room);

    for (i in 0...player.skills.maxHp) {
      draw(
        3 + i * 12,
        3 - (i == (lightPhase >> 3) % Std.int(5 + (player.hp / player.skills.maxHp) * 80) ? 2 : 0),
        224 + (player.hp > i ? 16 : 0), 96,
        16, 16, 0.9, -1, false
      );
    }
    Text.render(player.skills.maxHp * 12 + 10, 5, 'score: $$b${Game.score}$$b $$s${Game.difficulty == 0 ? "" : 'x${(2 + Game.difficulty) >> 1}.${Game.difficulty % 2 == 0 ? "0" : "5"}'}$$s', .4);
    if (toasts.length > 0) {
      var cur = toasts[0];
      //trace(cur);
      Text.render(WH - (Text.width(cur.text) >> 1), Math.round(cur.y), cur.text, .9);
      cur.y = cur.y * .95 + (cur.ph < 300 ? H - 16 : H + 4) * .05;
      cur.ph++;
      if (cur.ph > 400)
        toasts.shift();
    }
    draw(
      W - 3 - 32, 3,
      320, 264 + (Sfx.enabled ? 0 : 16),
      16, 16, 0.5, -1, false
    );
    draw(
      W - 3 - 16, 3,
      336, 264 + (Music.enabled ? 0 : 16),
      16, 16, 0.5, -1, false
    );

    debugRooms('${rendered}');
    */
  }

  // with camera
  inline static function drawC(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, ?alpha:Float = 1.0, ?dalpha:Float = 1.0, ?flip:Bool = false):Void {
    draw(x + cameraXI, y + cameraYI, tx, ty, tw, th, alpha, dalpha, flip);
  }
  // with camera, centred
  inline static function drawCM(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, ?alpha:Float = 1.0, ?dalpha:Float = 1.0, ?flip:Bool = false):Void {
    draw(x + cameraXI - (tw >> 1), y + cameraYI - (th >> 1), tx, ty, tw, th, alpha, dalpha, flip);
  }

  static function draw(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, ?alpha:Float = 1.0, ?dalpha:Float = 1.0, ?flip:Bool = false):Void {
    surf.indexBuffer.writeUI16(vertexCount);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 2);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 3);
    surf.indexBuffer.writeUI16(vertexCount + 2);

    var gx1:Float = ((flip ? x + tw : x) - WH) / WH;
    var gx2:Float = ((flip ? x : x + tw) - WH) / WH;
    var gy1:Float = (H - y - HH) / HH;
    var gy2:Float = ((H - y - th) - HH) / HH;

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

    bufferUV.writeF32(tx);
    bufferUV.writeF32(ty);
    bufferUV.writeF32(tx);
    bufferUV.writeF32(ty);
    bufferUV.writeF32(tx);
    bufferUV.writeF32(ty);
    bufferUV.writeF32(tx);
    bufferUV.writeF32(ty);/*
    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty2);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty2);*/

    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);
    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);
    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);
    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);

    vertexCount += 4;

    if (vertexCount > 400) {
      surf.renderFlush();
      vertexCount = 0;
      renderCalls++;
    }
  }
}

enum RenderScreen {
  Intro;
  GamePlaying;
  GameOver;
}
