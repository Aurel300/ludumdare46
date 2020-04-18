precision highp float;
precision highp int;

// uniform sampler2D uSampler;
// uniform vec4 uLight;

varying highp vec2 vUV;
varying highp vec2 vAlpha;

void main(void) {
  // vec4 col = texture2D(uSampler, vUV);

  // if (col.w < 0.5)
  //   discard;

  /*
  float alpha = vAlpha.x * col.w;
  float light = vAlpha.y;

  int subX = int(floor(mod(gl_FragCoord.x, 4.0)));
  int subY = int(floor(mod(gl_FragCoord.y, 4.0)));
  int sub = subX + subY * 4;
  int limit = 0;
  //// if (sub ==  0) limit = 0;
  else if (sub ==  1) limit = 12;
  else if (sub ==  2) limit = 3;
  else if (sub ==  3) limit = 15;
  else if (sub ==  4) limit = 8;
  else if (sub ==  5) limit = 4;
  else if (sub ==  6) limit = 11;
  else if (sub ==  7) limit = 7;
  else if (sub ==  8) limit = 2;
  else if (sub ==  9) limit = 14;
  else if (sub == 10) limit = 1;
  else if (sub == 11) limit = 13;
  else if (sub == 12) limit = 10;
  else if (sub == 13) limit = 6;
  else if (sub == 14) limit = 9;
  else if (sub == 15) limit = 15;

  float dx = gl_FragCoord.x - uLight.x;
  float dy = 240.0 - gl_FragCoord.y - uLight.y;
  float dist = sqrt(dx * dx / uLight.z + dy * dy / uLight.w);
  dist -= float(limit) * 1.1;

  if (dist > 140.0) {
    light *= 0.1;
  } else if (dist > 80.0) {
    light *= 1.0 - ((dist - 80.0) / 60.0) * 0.9;
  }

  if (vAlpha.y < -.5) light = 1.0;

  gl_FragColor = (light * col + (1.0 - light) * vec4(50. / 255., 30. / 255., 51. / 255., col.w)) * vec4(1, 1, 1, alpha);
  */
  gl_FragColor = vec4(vUV.x * 100., vUV.y * 100., 1, 1);
}
