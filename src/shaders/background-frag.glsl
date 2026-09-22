#version 300 es
precision highp float;
uniform vec3 u_Resolution;
uniform vec3 u_Halo;
uniform float u_Time;
uniform float u_Glow;
in vec2 fs_UV;
out vec4 out_Col;
/* NOISE */
void main() {
  vec2 q=fs_UV-0.5;
  q.x*=u_Resolution.x/u_Resolution.y;
  vec2 direction=normalize(vec2(0.78,0.62));
  float along=dot(q,direction), across=dot(q,vec2(-direction.y,direction.x));
  vec3 p=vec3(along*1.2-u_Time*0.19,across*5.5,0.7);
  float warp=noise3(p*0.7);
  float n=noise3(p+vec3(0.0,warp*2.0,0.0));
  float fine=noise3(p*vec3(1.7,2.5,1.0)+warp);
  float ribbons=pow(clamp(n*0.65+fine*0.35,0.0,1.0),3.0);
  vec3 color=mix(vec3(0.13,0.016,0.002),vec3(0.55,0.095,0.003),n);
  color+=vec3(1.6,0.65,0.008)*ribbons;
  vec2 halo=fs_UV-u_Halo.xy;halo.x*=u_Resolution.x/u_Resolution.y;
  float glow=exp(-dot(halo,halo)/max(u_Halo.z*u_Halo.z,0.001)*1.7);
  color+=vec3(0.22,0.055,0.002)*glow*u_Glow;
  out_Col=vec4(color,1.0);
}
