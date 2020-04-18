# (keep it alive)

Setting: N/A

## Gameplay

Arena: 3 x 3 (or later larger?) grid of tiles.

Tiles contain:
 - player
 - "it"
 - bullet barrages
 - powerups? - screen clear, extra life, time slow, temporary invincibility ...

The player can move around freely, instantly moving across tiles with the arrow keys. The player can also pick up and drop "it" at any time (must be on the same tile to pick up). When "it" is held, movement is limited – to move, the arrow key must be held for a short while (indicator!) before the movement is done. While "it" is held, the player's stamina is decreasing, otherwise it replenishes (faster than it is spent?).

Bullets barrages spawn around the arena, moving across a column or row of tiles. Purple bullets hurt the player, yellow bullets hurt "it".

Time is split into "beats" (synchronised with the music?), bullets move across tiles one tile at a time on some multiples of the beat counter. (I.e. show bullet "preparing" to move to the next tile visually on beat 1, actually move on beat 2).

The player starts with 5 lives and must survive 5(?) minutes (classic) or indefinitely (score attack). Lives are lost when:
 - the player is hit by a purple bullet
 - "it" is hit by a yellow bullet
 - the player is holding "it" and their stamina hits 0

## TODO

 - gfx
 - sfx
 - music
 - ui
 - the game

 x waves
 . difficulty scaling
 - proc music
 - powerups
 - score/classic timer?
 - classic "levels"?
