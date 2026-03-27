const BLOCKS = [
  { id:'hull',    name:'HULL',     color:0x2a3a4a, emissive:0x0a1520, key:'1' },
  { id:'cockpit', name:'COCKPIT',  color:0x1a3a5a, emissive:0x001030, key:'2' },
  { id:'wing',    name:'WING',     color:0x1e2e3e, emissive:0x050f1a, key:'3' },
  { id:'engine',  name:'ENGINE',   color:0x3a2010, emissive:0x200800, key:'4' },
  { id:'thruster',name:'THRUSTER', color:0x102830, emissive:0x001520, key:'5' },
  { id:'weapon',  name:'WEAPON',   color:0x3a1010, emissive:0x200000, key:'6' },
  { id:'shield',  name:'SHIELD',   color:0x0a3020, emissive:0x001508, key:'7' },
  { id:'custom',  name:'CUSTOM',   color:0x4488aa, emissive:0x001122, key:'8' },
];

let tool = 'add';
let activeBlock = BLOCKS[0];
let customColor = 0x4488aa;
let symmetry = false;
let showGrid = true;
let voxels = new Map();
let history = [];
let future = [];
let hintTimer;

let launchMode = false;
let shipGroup  = null;
let ship = { pos: new THREE.Vector3(), vel: new THREE.Vector3(), quat: new THREE.Quaternion() };
let shipStats = { mass: 1, enginePower: 1, rcsPower: 1, brakeDrag: 0.9, weaponCount: 0 };
let blockHealth   = new Map();
let totalHullMax  = 1;
let totalShieldMax = 1;
let asteroids     = [];
let projectiles   = [];
let weaponCooldown = 0;
let flightKeys    = {};
let mouseFDx = 0;
let mouseFDy = 0;
let pointerLocked = false;
let starfield     = null;
let distantSystemStars = null;
let localStar = null;
let stellarTargets = [];
let streamedSectors = new Map();
let systemCache = new Map();
let sectorCache = new Map();
let flightBlocks  = new Map();
let launchSnapshot = null;
let placementRotation = { x: 0, y: 0, z: 0 };
let rotationStep = Math.PI / 2;
let orbitCam = { distance: 22, height: 10, smooth: 0.08 };
let hyperdriveCharge = 1;
let hyperdriveState = 'off';
let hyperdriveTimer = 0;
let hyperdriveGraceTimer = 0;
let universeInitialized = false;
let currentSectorCoord = null;
let currentSystemCoord = null;
let selectedSystemCoord = null;
let shipAlignTarget = null;
let starmapOpen = false;
let starmapMode = 'galaxy';
let selectedWarpTarget = null;
let selectedSystemObjectId = null;
let localPlanets = [];

const BLOCK_HP = { hull:100, cockpit:130, wing:60, engine:140, thruster:100, weapon:80, shield:200, custom:80 };
const THRUST = 0.009;
const STRAFE_F = 0.005;
const MAX_SPD = 10;
const DRAG = 0.003;
const TURN_SPD = 0.025;
const ROLL_SPD = 0.025;
const WPN_CD = 0.28;
const PROJ_SPD = 18;
const LIFT_F = 0.006;
const BRAKE_MULT = 0.88;
const MAX_PARTICLES = 520;
const FLIGHT_MOUSE_SENS = 0.0022;
const FLIGHT_CAM_DISTANCE = 18;
const FLIGHT_CAM_HEIGHT = 5.5;
const FLIGHT_CAM_LOOK_AHEAD = 30;
const FLIGHT_CAM_POS_SMOOTH = 0.28;
const FLIGHT_CAM_ROT_SMOOTH = 0.3;
const WORLD_SEED = 'vessel-sector-alpha';
const HOME_SYSTEM_COORD = { x: 6, y: 0, z: 2 };
const SECTOR_SIZE = 5000;
const SYSTEM_SIZE = 16;
const SYSTEM_CENTER_SECTOR = Math.floor(SYSTEM_SIZE / 2);
const SECTOR_STREAM_RADIUS = 1;
const STARMAP_SYSTEM_RADIUS = 2;
const STARMAP_COORD_SCALE = 1.8;
const STARMAP_MIN_DISTANCE = 2.6;
const STARMAP_MAX_DISTANCE = 140;
const STELLAR_TARGET_RADIUS = 2;
const MAX_GYRO_TURN_SPEED = 1.8;
const SYSTEM_OBJECT_RENDER_DISTANCE = 34000;
const WARP_STOP_THRESHOLD = 900;
const GALAXY_WORLD_SCALE = 20000;
const GALAXY_WORLD_Y_SCALE = 9000;
const HYPERDRIVE_SPOOL_TIME = 1.15;
const HYPERDRIVE_SPOOLDOWN_TIME = 0.7;
const HYPERDRIVE_ACCEL = 2.6;
const HYPERDRIVE_MAX_SPEED = 120;
const HYPERDRIVE_STEER_MULT = 0.35;
const HYPERDRIVE_ASTEROID_GRACE = 2.25;
const HYPERDRIVE_SPOOLDOWN_DRAG = 0.045;
const ASTEROID_SAFE_DISTANCE = 2400;
const ASTEROID_SECTOR_RADIUS = 1800;
const STAR_RENDER_DISTANCE = 4000000;

let camSettings = {
  invertY: false,
  invertX: false,
  invertZoom: false,
  sensitivity: 1.0,
  zoomSensitivity: 1.0,
};
