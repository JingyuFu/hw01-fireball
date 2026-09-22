#version 300 es
precision highp float;
uniform mat4 u_Model;
uniform mat4 u_ViewProj;
uniform float u_Time;
uniform float u_Strength;
uniform float u_Scale;
uniform float u_Detail;
in vec4 vs_Pos;
in vec4 vs_Nor;
out vec3 fs_Surface;
out vec3 fs_World;
out float fs_Heat;
/* NOISE */
void main() {
  vec3 p=vs_Pos.xyz;
  vec3 flow=vec3(0.05,-0.65,0.03)*u_Time;
  float broad=noise3(p*1.8+flow);
  float fine=fbm(p*u_Scale+flow);
  float tail=smoothstep(-0.25,1.0,p.y);
  // Keep one rounded head and taper continuously into a tapered trailing region.
  float taper=1.0-0.57*tail;
  float low=u_Strength*0.13*(broad-0.5);
  float high=u_Strength*u_Detail*0.075*(fine-0.5);
  vec3 shaped=p+normalize(vs_Nor.xyz)*(low+high)*(0.25+0.75*tail);
  shaped.xz*=taper;
  shaped.y=p.y*1.23+0.52*tail-0.23;
  shaped.y+=tail*u_Strength*(0.11*sin(p.x*5.0+u_Time)+0.17*(fine-0.5));
  // Narrow, unequal tongues roughen only the trailing half of the droplet.
  // Anisotropic noise stretches the peaks along the flight direction.
  float fringe=smoothstep(0.08,0.72,p.y);
  vec3 strandUV=vec3(p.x*19.0,p.y*5.0-u_Time*0.85,p.z*19.0);
  float strands=noise3(strandUV);
  float tips=pow(smoothstep(0.25,0.76,strands),2.0);
  float smallTips=pow(smoothstep(0.30,0.78,noise3(strandUV*1.73+7.3)),3.0);
  float roughness=u_Strength*(0.65+u_Detail);
  shaped.y+=fringe*roughness*(0.72*tips+0.22*smallTips-0.16);
  shaped.xz*=1.0+fringe*roughness*0.20*(strands-0.5);

  // Rotate the long axis toward the upper right, like the assignment image.
  float a=-0.72;
  shaped.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*shaped.xy;
  fs_Surface=p;
  fs_Heat=(p.y+1.0)*0.5+0.10*(broad-0.5)+0.055*(fine-0.5);
  vec4 world=u_Model*vec4(shaped,1.0);
  fs_World=world.xyz;
  gl_Position=u_ViewProj*world;
}
