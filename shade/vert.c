precision highp float;
precision highp int;

attribute vec3 aPosition;
attribute vec2 aUV;
attribute vec2 aAlpha;

varying highp vec2 vUV;
varying highp vec2 vAlpha;

void main(void) {
  gl_PointSize = 1.0;
  gl_Position = vec4(aPosition.x, aPosition.y, 0.0, 1.0);
  vUV = aUV;
  vAlpha = aAlpha;
}
