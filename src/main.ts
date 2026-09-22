import {vec3, vec4, mat4} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import vertex from './shaders/lambert-vert.glsl?raw';
import fragment from './shaders/lambert-frag.glsl?raw';
import noise from './shaders/noise.glsl?raw';
import backgroundVertex from './shaders/background-vert.glsl?raw';
import backgroundFragment from './shaders/background-frag.glsl?raw';

const defaults = { strength: 0.6, scale: 4.5, detail: 0.6, octaves: 4,
  speed: 0.65, temperature: 0.0, exposure: 1.0, glow: 0.8, subdivisions: 5, paused: false };

function main() {
  const canvas = document.getElementById('canvas') as HTMLCanvasElement;
  const gl = canvas.getContext('webgl2', {antialias: true});
  if (!gl) throw new Error('This demo requires a browser with WebGL 2 enabled.');
  setGL(gl);
  const camera = new Camera(vec3.fromValues(0, 0, 5.4), vec3.create());
  const renderer = new OpenGLRenderer(canvas);
  let sphere: Icosphere;
  let time = 0;
  const controls = {...defaults, reset: () => {
    Object.assign(controls, defaults);
    time = 0;
    rebuild();
    camera.controls.lookAt([0, 0, 0], [0, 0, 5.4], [0, 1, 0]);
  }};
  function rebuild() {
    if (sphere) sphere.destroy();
    sphere = new Icosphere(vec3.create(), 1, controls.subdivisions);
    sphere.create();
  }
  rebuild();
  const compile = (v: string, f: string) => new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, v.replace('/* NOISE */', noise)),
    new Shader(gl.FRAGMENT_SHADER, f.replace('/* NOISE */', noise)),
  ]);
  const fire = compile(vertex, fragment);
  const background = compile(backgroundVertex, backgroundFragment);
  const gui = new DAT.GUI({width: 280});
  const shape = gui.addFolder('01 / Surface');
  shape.add(controls, 'strength', 0, 1.6, 0.01).name('Displacement').listen();
  shape.add(controls, 'scale', 1.5, 7, 0.1).name('Noise scale').listen();
  shape.add(controls, 'detail', 0, 1.8, 0.01).name('Fine distortion').listen();
  shape.add(controls, 'octaves', 1, 6, 1).name('fBM octaves').listen();
  shape.add(controls, 'subdivisions', 3, 7, 1).name('Mesh detail').onFinishChange(rebuild).listen();
  shape.open();
  const appearance = gui.addFolder('02 / Energy');
  appearance.add(controls, 'temperature', -0.25, 0.35, 0.01).name('Temperature').listen();
  appearance.add(controls, 'exposure', 0.4, 2, 0.01).name('Exposure').listen();
  appearance.add(controls, 'glow', 0, 2, 0.01).name('Atmospheric glow').listen();
  appearance.add(controls, 'speed', 0, 2, 0.01).name('Animation speed').listen();
  appearance.open();
  gui.add(controls, 'paused').name('Pause animation').listen();
  gui.add(controls, 'reset').name('Restore defaults');
  if (innerWidth < 680) gui.close();
  const stats = Stats();
  stats.domElement.style.cssText = 'position:fixed;left:24px;bottom:22px;top:auto;opacity:.65';
  document.body.appendChild(stats.domElement);
  function resize() {
    const ratio = Math.min(window.devicePixelRatio || 1, 1.5);
    renderer.setSize(Math.round(innerWidth * ratio), Math.round(innerHeight * ratio));
    camera.setAspectRatio(innerWidth / innerHeight);
    camera.fovy = 2 * Math.atan(Math.tan(Math.PI / 8) / Math.min(camera.aspectRatio, 1));
    camera.updateProjectionMatrix();
  }
  window.addEventListener('resize', resize);
  resize();
  const viewProj = mat4.create();
  const center = vec4.create();
  let previous = performance.now();
  function tick(now: number) {
    stats.begin();
    const delta = Math.min((now - previous) / 1000, 0.05);
    previous = now;
    if (!controls.paused) time += delta * controls.speed;
    camera.update();
    gl.viewport(0, 0, canvas.width, canvas.height);
    renderer.clear();
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    vec4.transformMat4(center, vec4.fromValues(0, 0, 0, 1), viewProj);
    background.setVec3('u_Resolution', canvas.width, canvas.height, 0);
    background.setVec3('u_Halo', center[0]/center[3]*0.5+0.5, center[1]/center[3]*0.5+0.5,
      center[3] > 0 ? (1.4 + controls.strength*0.3)*camera.projectionMatrix[5]/center[3]*0.5 : 0);
    background.setFloat('u_Time', time);
    background.setFloat('u_Glow', center[3] > 0 ? controls.glow : 0);
    gl.disable(gl.DEPTH_TEST);
    gl.depthMask(false);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.depthMask(true);
    gl.enable(gl.DEPTH_TEST);
    fire.setFloat('u_Time', time);
    fire.setFloat('u_Strength', controls.strength);
    fire.setFloat('u_Scale', controls.scale);
    fire.setFloat('u_Detail', controls.detail);
    fire.setFloat('u_Temperature', controls.temperature);
    fire.setFloat('u_Exposure', controls.exposure);
    fire.setInt('u_Octaves', controls.octaves);
    const eye = camera.controls.eye;
    fire.setVec3('u_Eye', eye[0], eye[1], eye[2]);
    renderer.render(camera, fire, [sphere]);
    stats.end();
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}
try { main(); } catch (error) {
  document.getElementById('error')!.textContent = String(error);
  console.error(error);
}
