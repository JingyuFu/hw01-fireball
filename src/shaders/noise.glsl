// Continuous 3D value noise with quintic interpolation; no textures.
uniform highp int u_Octaves;
float hash3(vec3 p) {
  p = fract(p * 0.1031);
  p += dot(p, p.yzx + 33.33);
  return fract((p.x + p.y) * p.z);
}
float noise3(vec3 p) {
  vec3 i = floor(p), f = fract(p);
  vec3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
  return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),u.x),
                 mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),u.x),u.y),
             mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),u.x),
                 mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),u.x),u.y),u.z);
}
float fbm(vec3 p) {
  float sum=0.0, weight=0.5, total=0.0;
  for(int i=0; i<6; ++i) {
    if(i>=u_Octaves) break;
    sum+=weight*noise3(p); total+=weight;
    p=p*2.03+vec3(7.1,13.7,3.8); weight*=0.5;
  }
  return sum/total;
}
