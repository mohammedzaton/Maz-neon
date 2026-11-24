import * as THREE from 'three';
const mat = (color, extra={}) => new THREE.MeshStandardMaterial({ color, roughness: .48, metalness: .5, ...extra });
const materials = { tire: mat('#080b12',{roughness:.9,metalness:.05}), glass:mat('#0b1930',{roughness:.14,metalness:.85}), metal:mat('#8495ad'), black:mat('#060912') };
function box(parent, w,h,d, material, x=0,y=0,z=0) {
  const m=new THREE.Mesh(new THREE.BoxGeometry(w,h,d), material); m.position.set(x,y,z); parent.add(m); return m;
}
export function makeCar(color, detailed=true) {
  const group = new THREE.Group(); group.userData.paint = mat(color,{metalness:.7,roughness:.28});
  box(group,1.86,.43,4.1,group.userData.paint,0,.65,0);
  box(group,1.95,.17,4.24,materials.black,0,.4,0);
  const hood=box(group,1.8,.12,1.35,group.userData.paint,0,.91,-1.22); hood.rotation.x=.035;
  box(group,1.48,.52,1.62,materials.glass,0,1.09,.04);
  box(group,1.55,.09,1.14,group.userData.paint,0,1.4,.16);
  box(group,.12,.55,1.65,group.userData.paint,-.76,1.08,.06);
  box(group,.12,.55,1.65,group.userData.paint,.76,1.08,.06);
  const head = new THREE.MeshBasicMaterial({color:'#c1faff'}), tail = new THREE.MeshBasicMaterial({color:'#ff2a62'});
  box(group,.65,.1,.035,head,-.52,.72,-2.07); box(group,.65,.1,.035,head,.52,.72,-2.07);
  box(group,.72,.08,.035,tail,-.5,.75,2.07); box(group,.72,.08,.035,tail,.5,.75,2.07);
  box(group,1.2,.1,.06,materials.black,0,.56,2.12);
  group.userData.wheels=[];
  const geo = new THREE.CylinderGeometry(.38,.38,.25,12);
  for (const x of [-.97,.97]) for (const z of [-1.28,1.28]) {
    const wheel = new THREE.Mesh(geo,materials.tire); wheel.rotation.z=Math.PI/2; wheel.position.set(x,.38,z); group.add(wheel); group.userData.wheels.push(wheel);
    const rim = new THREE.Mesh(new THREE.CylinderGeometry(.23,.23,.26,8),materials.metal);rim.rotation.z=Math.PI/2;rim.position.copy(wheel.position);group.add(rim);
  }
  if(detailed) {
    box(group,2.02,.08,.42,materials.black,0,1.15,1.66);
    for(const x of [-.68,.68]) box(group,.08,.35,.1,materials.black,x,.98,1.66);
    box(group,.055,.014,3.9,new THREE.MeshBasicMaterial({color:'#e0fffa'}),-.34,.877,-.04);
    box(group,.055,.014,3.9,new THREE.MeshBasicMaterial({color:'#e0fffa'}),.34,.877,-.04);
  }
  group.userData.glow = new THREE.Mesh(new THREE.PlaneGeometry(2.6,4.8),new THREE.MeshBasicMaterial({color,transparent:true,opacity:.2,depthWrite:false,side:THREE.DoubleSide}));
  group.userData.glow.rotation.x=-Math.PI/2;group.userData.glow.position.y=.035; group.add(group.userData.glow);
  return group;
}
export class RaceScene {
  constructor(canvas) {
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: devicePixelRatio < 2, powerPreference:'high-performance' });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio,1.65)); this.renderer.setClearColor('#040814');
    this.renderer.toneMapping=THREE.ACESFilmicToneMapping;this.renderer.toneMappingExposure=1.18;
    this.scene=new THREE.Scene(); this.scene.fog=new THREE.FogExp2('#080e24',.0085);
    this.camera=new THREE.PerspectiveCamera(60,1,.1,650);
    this.scene.add(new THREE.HemisphereLight('#829cff','#121026',2.6));
    const key=new THREE.DirectionalLight('#e6eaff',3.5);key.position.set(-8,12,10);this.scene.add(key);
    const pink=new THREE.DirectionalLight('#e043b4',1.7);pink.position.set(10,4,-15);this.scene.add(pink);
    this.player=makeCar('#20f6dc');this.scene.add(this.player);
    this.light=new THREE.PointLight('#20f6dc',12,9,2);this.light.position.set(0,.8,1);this.player.add(this.light);
    this.tiles=[];this.makeRoad();this.makeSky();this.makeCity();this.traffic=[];
    window.addEventListener('resize',()=>this.resize());this.resize();
  }
  resize() { const w=innerWidth,h=innerHeight;this.renderer.setSize(w,h,false);this.camera.aspect=w/h;this.camera.updateProjectionMatrix(); }
  makeRoad() {
    const asphalt=mat('#172032',{roughness:.48,metalness:.3}); const ground=mat('#090f1e',{roughness:.6});
    box(this.scene,1100,.15,1000,ground,0,-.18,-200);
    box(this.scene,14,.12,600,asphalt,0,-.04,-235);
    const white = new THREE.MeshBasicMaterial({color:'#63718d'}), cyan=new THREE.MeshBasicMaterial({color:'#16e7df'}), pink=new THREE.MeshBasicMaterial({color:'#ff3c8b'});
    for(let i=0;i<25;i++) {
      const g=new THREE.Group();g.position.z=45-i*18;
      for(const x of [-3.5,0,3.5])box(g,.095,.015,5,white,x,.032,0);
      for(const x of [-7.2,7.2]) {
        box(g,.14,.06,17.9,x<0?cyan:pink,x,.08,0);
        box(g,.6,.26,17.9,materials.black,x*1.06,.08,0);
        box(g,.09,.16,1.8,x<0?cyan:pink,x*1.06,.25,0);
      }
      this.tiles.push(g);this.scene.add(g);
    }
    for(let i=0;i<11;i++) {
      const g = new THREE.Group();g.position.z=30-i*40;
      for(const x of [-9,9]) {
        box(g,.16,7,.16,mat('#17233c'),x,3.5,0);
        box(g,2.1,.08,.3,new THREE.MeshBasicMaterial({color:'#a7d9ff'}),x+(x<0?1:-1),7,0);
      }
      this.tiles.push(g);g.userData.lamp=true;this.scene.add(g);
    }
  }
  makeSky() {
    const stars=new Float32Array(420*3);let seed=29;
    const random=()=>{seed=(seed*16807)%2147483647;return(seed-1)/2147483646;};
    for(let i=0;i<420;i++){stars[i*3]=(random()-.5)*700;stars[i*3+1]=25+random()*150;stars[i*3+2]=-80-random()*400;}
    const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.BufferAttribute(stars,3));
    this.scene.add(new THREE.Points(geometry,new THREE.PointsMaterial({color:'#8e9fca',size:.5,transparent:true,opacity:.7})));
    const sun=new THREE.Mesh(new THREE.CircleGeometry(36,64),new THREE.ShaderMaterial({transparent:true,depthWrite:false,uniforms:{},vertexShader:'varying vec2 vUv; void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',fragmentShader:'varying vec2 vUv;void main(){float a=1.;if(vUv.y<.55 && mod(vUv.y*38.,1.)<.28)discard;vec3 c=mix(vec3(.7,.07,.42),vec3(.32,.15,.65),vUv.y);gl_FragColor=vec4(c,.72);}' }));sun.position.set(-36,52,-410);this.scene.add(sun);
  }
  makeCity() {
    let seed=512;const rnd=()=>{seed=(seed*16807)%2147483647;return(seed-1)/2147483646;};
    const geo=new THREE.BoxGeometry(1,1,1), m=new THREE.Matrix4();
    const buildings=new THREE.InstancedMesh(geo,mat('#10172d',{roughness:.8,metalness:.25}),100);
    const windows=new THREE.InstancedMesh(geo,new THREE.MeshBasicMaterial({color:'#4562a5'}),700);
    let windowIndex=0;
    for(let i=0;i<100;i++) {
      const side=i%2?1:-1,x=side*(18+rnd()*95),z=45-rnd()*470,w=5+rnd()*11,h=8+rnd()*65,d=6+rnd()*12;
      m.makeScale(w,h,d);m.setPosition(x,h/2,z);buildings.setMatrixAt(i,m);
      for(let j=0;j<7;j++) {m.makeScale(.2,.55,d+.04);m.setPosition(x-w*.35+j*w*.115,2+rnd()*(h-3),z);windows.setMatrixAt(windowIndex++,m);}
      if(i%9===0){const stripe=box(this.scene,.12,h*.8,d+.06,new THREE.MeshBasicMaterial({color:i%3?'#24c8ca':'#b52a91'}),x-w/2,h/2,z);}
    }
    this.scene.add(buildings,windows);
  }
  addTraffic(color) { const c=makeCar(color,false);this.scene.add(c);this.traffic.push(c);return c; }
  setCar(color) { this.player.userData.paint.color.set(color);this.player.userData.glow.material.color.set(color);this.light.color.set(color); }
  update(dt,{speed=0,distance=0,steer=0,x=0,boost=false,active=false,menu=false,time=0,shake=0}) {
    for(const g of this.tiles){const period=g.userData.lamp?440:450;g.position.z=((g.position.z+speed*dt+period-55)%period+period)%period+55-period;}
    if(menu) {
      this.player.position.set(2.5,0,-2);this.player.rotation.set(0,-.25+Math.sin(time*.22)*.12,0);
      this.camera.position.lerp(new THREE.Vector3(10,4.4,10),.035);this.camera.lookAt(0,1,-6);
    } else {
      this.player.position.set(x,Math.sin(time*23)*.013*speed/50,0);this.player.rotation.y=THREE.MathUtils.lerp(this.player.rotation.y,-steer*.11,dt*10);this.player.rotation.z=-steer*.025;
      const offset=innerWidth<700?1:0;
      this.camera.position.lerp(new THREE.Vector3(x*.28+(Math.random()-.5)*shake,4.6+offset,10.6),1-Math.exp(-dt*7));
      this.camera.lookAt(x*.4,.9,-22);
    }
    const fov=60+(boost?9:0);this.camera.fov=THREE.MathUtils.lerp(this.camera.fov,fov,dt*5);this.camera.updateProjectionMatrix();
    this.light.intensity=boost?25:12;
    this.renderer.render(this.scene,this.camera);
  }
}
