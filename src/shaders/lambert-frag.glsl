#version 300 es
precision highp float;
uniform float u_Time;
uniform float u_Scale;
uniform float u_Temperature;
uniform float u_Exposure;
uniform vec3 u_Eye;
in vec3 fs_Surface;
in vec3 fs_World;
in float fs_Heat;
out vec4 out_Col;
/* NOISE */
vec3 fireRamp(float t) {
  vec3 c=mix(vec3(1.0,1.0,0.98),vec3(1.0,0.98,0.40),smoothstep(0.36,0.55,t));
  c=mix(c,vec3(1.0,0.64,0.025),smoothstep(0.49,0.66,t));
  c=mix(c,vec3(0.94,0.23,0.008),smoothstep(0.63,0.80,t));
  c=mix(c,vec3(0.24,0.038,0.005),smoothstep(0.77,0.94,t));
  return mix(c,vec3(0.035,0.009,0.004),smoothstep(0.91,1.0,t));
}
void main() {
  float n=fbm(fs_Surface*u_Scale+vec3(0.0,-u_Time*0.65,0.0));
  // One longitudinal gradient. Noise only softly moves the color boundaries.
  float t=clamp(fs_Heat+0.085*(n-0.5)-u_Temperature,0.0,1.0);
  vec3 normal=normalize(cross(dFdx(fs_World),dFdy(fs_World)));
  float facing=abs(dot(normal,normalize(u_Eye-fs_World)));
  vec3 color=fireRamp(t);
  color*=1.0-0.12*(1.0-facing)*smoothstep(0.5,0.85,t);
  out_Col=vec4(clamp(color*u_Exposure,0.0,1.0),1.0);
}
