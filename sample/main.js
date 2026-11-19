import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

// 1. Scene, Camera, Renderer
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e1e22);

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 2, 5);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
document.body.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.target.set(0, 1, 0);

// 2. Lighting & Grid
scene.add(new THREE.AmbientLight(0xffffff, 1.2));
const dirLight = new THREE.DirectionalLight(0xffffff, 2);
dirLight.position.set(3, 6, 4);
scene.add(dirLight);
scene.add(new THREE.GridHelper(10, 10, 0x444444, 0x2a2a2a));

// 3. Bone Storage & Rest Pose Cache
const bones = {};
const restQuaternions = {};
let skeletonHelper = null;

// Exact bone names from your test.glb hierarchy
const EXPECTED_BONES = [
  'Forearm', 'Wrist',
  'Index', 'Index_MCP', 'Index_PIP', 'Index_DIP',
  'Middle', 'Middle_MCP', 'Middle_PIP', 'Middle_DIP',
  'Ring', 'Ring_MCP', 'Ring_PIP', 'Ring_DIP',
  'Pinky', 'Pinky_MCP', 'Pinky_PIP', 'Pinky_DIP',
  'Thumb_CMC', 'Thumb_MCP', 'Thumb_IP'
];

// 4. Load test.glb
const loader = new GLTFLoader();
loader.load(
  './test.glb',
  (gltf) => {
    const model = gltf.scene;
    scene.add(model);

    // Visualize bones even if mesh skinning is minimal
    skeletonHelper = new THREE.SkeletonHelper(model);
    scene.add(skeletonHelper);

    console.log('--- Loaded Scene Hierarchy ---');
    console.log(model);

    model.traverse((obj) => {
      if (obj.isBone) {
        bones[obj.name] = obj;
        // Save Blender rest quaternion so delta rotations compose accurately
        restQuaternions[obj.name] = obj.quaternion.clone();
        console.log(`Found Bone: ${obj.name}`, obj.quaternion);
      }
    });

    // Verify all expected bones exist
    const missing = EXPECTED_BONES.filter((name) => !bones[name]);
    if (missing.length > 0) {
      console.warn('Missing expected bones:', missing);
    } else {
      console.log('All 21 expected bones mapped successfully!');
    }
  },
  undefined,
  (error) => {
    console.error('Error loading test.glb:', error);
  }
);

// 5. Quaternion Interpolation Helper (matches Blender's Quaternion WXYZ mode)
const _identityQuat = new THREE.Quaternion();
const _deltaQuat = new THREE.Quaternion();

// Smoothly interpolates (slerps) from rest pose (t = 0) to Blender's WXYZ quaternion (t = 1)
function setBoneQuaternionCurl(boneName, targetQuat, t) {
  const bone = bones[boneName];
  const rest = restQuaternions[boneName];
  if (!bone || !rest) return;

  _deltaQuat.slerpQuaternions(_identityQuat, targetQuat, t);
  bone.quaternion.copy(rest).multiply(_deltaQuat);
}

// 6. Core Pose Update Function
// Exact WXYZ values from Blender's Transform panel (Three.js constructor order: x, y, z, w)
const FINGER_MAX_CURL = new THREE.Quaternion(-0.8, 0.0, 0.0, 1.0).normalize();

const THUMB_MAX_CURL = {
  Thumb_CMC: new THREE.Quaternion(-0.5, -0.3, 0.0, 1.0).normalize(),
  Thumb_MCP: new THREE.Quaternion(-0.8, -0.3, 0.0, 1.0).normalize(),
  Thumb_IP:  new THREE.Quaternion(-0.8,  0.0, 0.0, 1.0).normalize(),
};

function updateHandPose(sensorState) {
  // Curl four fingers across MCP, PIP, and DIP joints using {-0.8, 0.0, 0.0}
  const fingers = ['Index', 'Middle', 'Ring', 'Pinky'];
  fingers.forEach((finger) => {
    const flex = sensorState[finger.toLowerCase()];
    setBoneQuaternionCurl(`${finger}_MCP`, FINGER_MAX_CURL, flex);
    setBoneQuaternionCurl(`${finger}_PIP`, FINGER_MAX_CURL, flex);
    setBoneQuaternionCurl(`${finger}_DIP`, FINGER_MAX_CURL, flex);
  });

  // Smoothly slerp thumb across CMC, MCP, and IP joints
  const thumbFlex = sensorState.thumb;
  setBoneQuaternionCurl('Thumb_CMC', THUMB_MAX_CURL.Thumb_CMC, thumbFlex);
  setBoneQuaternionCurl('Thumb_MCP', THUMB_MAX_CURL.Thumb_MCP, thumbFlex);
  setBoneQuaternionCurl('Thumb_IP',  THUMB_MAX_CURL.Thumb_IP,  thumbFlex);

  // Wrist orientation from IMU pitch/roll
  if (bones['Wrist'] && restQuaternions['Wrist']) {
    const euler = new THREE.Euler(
      THREE.MathUtils.degToRad(sensorState.pitch),
      THREE.MathUtils.degToRad(sensorState.roll),
      0,
      'YXZ'
    );
    _deltaQuat.setFromEuler(euler);
    bones['Wrist'].quaternion.copy(restQuaternions['Wrist']).multiply(_deltaQuat);
  }
}

// 7. Wire HTML Sliders to updateHandPose()
const sliderIds = ['thumb', 'index', 'middle', 'ring', 'pinky', 'pitch', 'roll'];

function syncFromSliders() {
  const state = {
    thumb:  parseFloat(document.getElementById('slider-thumb').value),
    index:  parseFloat(document.getElementById('slider-index').value),
    middle: parseFloat(document.getElementById('slider-middle').value),
    ring:   parseFloat(document.getElementById('slider-ring').value),
    pinky:  parseFloat(document.getElementById('slider-pinky').value),
    pitch:  parseFloat(document.getElementById('slider-pitch').value),
    roll:   parseFloat(document.getElementById('slider-roll').value),
  };

  // Update UI labels
  ['thumb', 'index', 'middle', 'ring', 'pinky'].forEach((f) => {
    document.getElementById(`val-${f}`).textContent = `${Math.round(state[f] * 100)}%`;
  });
  document.getElementById('val-pitch').textContent = `${state.pitch}°`;
  document.getElementById('val-roll').textContent = `${state.roll}°`;

  updateHandPose(state);
}

sliderIds.forEach((id) => {
  document.getElementById(`slider-${id}`).addEventListener('input', syncFromSliders);
});

document.getElementById('reset-btn').addEventListener('click', () => {
  sliderIds.forEach((id) => {
    document.getElementById(`slider-${id}`).value = 0;
  });
  syncFromSliders();
});

// 8. Resize & Render Loop
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

function animate() {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}
animate();