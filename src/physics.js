import * as CANNON from 'cannon-es';
export class RacePhysics {
  constructor(onHit) {
    this.world = new CANNON.World({ gravity: new CANNON.Vec3(0, 0, 0) });
    this.player = new CANNON.Body({ mass: 1200, fixedRotation: true, shape: new CANNON.Box(new CANNON.Vec3(.84, .45, 1.8)), position: new CANNON.Vec3(1.65, .8, 0), collisionResponse: false });
    this.player.linearDamping = .1; this.player.allowSleep = false;
    this.player.addEventListener('collide', e => { if (e.body.userData?.traffic) onHit(e.body.userData.index); });
    this.world.addBody(this.player); this.traffic = [];
  }
  addTraffic(index, x, z) {
    const body = new CANNON.Body({ type: CANNON.Body.KINEMATIC, mass: 0, shape: new CANNON.Box(new CANNON.Vec3(.86, .45, 1.8)), position: new CANNON.Vec3(x, .8, z), collisionResponse: false });
    body.userData = { traffic: true, index }; this.world.addBody(body); this.traffic.push(body); return body;
  }
  reset() { this.player.position.set(1.65,.8,0); this.player.velocity.set(0,0,0); this.player.aabbNeedsUpdate = true; }
  step(dt, steer, handling, relativeSpeed) {
    this.player.velocity.set(steer * 8.5 * handling,0,0);
    for (const body of this.traffic) body.velocity.set(0,0,relativeSpeed(body.userData.index));
    this.world.step(1 / 60, dt, 5);
    this.player.position.x = Math.max(-5.7, Math.min(5.7, this.player.position.x));
    this.player.position.z = 0;
  }
}
