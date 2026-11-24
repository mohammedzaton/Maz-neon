import nipplejs from 'nipplejs';
export class Controls {
  constructor() {
    this.keys = new Set(); this.touchSteer = 0; this.boost = false; this.brake = false; this.buttons = new Map();
    const mapped = new Set(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','KeyA','KeyD','KeyW','KeyS','Space','ShiftLeft']);
    window.addEventListener('keydown', e => { if (mapped.has(e.code)) { e.preventDefault(); this.keys.add(e.code); } });
    window.addEventListener('keyup', e => this.keys.delete(e.code));
    window.addEventListener('blur', () => this.reset());
    this.joystick = nipplejs.create({ zone: document.querySelector('#joystick'), mode: 'static', position: { left: '50%', top: '50%' }, color: '#20f6dc', size: 110, restOpacity: .5 });
    this.joystick.on('move', (_, data) => { this.touchSteer = Math.max(-1, Math.min(1, data.vector.x)); });
    this.joystick.on('end', () => { this.touchSteer = 0; });
    this.bindHold('#boost', 'boost'); this.bindHold('#brake', 'brake');
  }
  bindHold(selector, key) {
    const button = document.querySelector(selector);
    button.addEventListener('pointerdown', e => { e.preventDefault(); button.setPointerCapture(e.pointerId); this[key] = true; button.classList.add('held'); });
    for (const event of ['pointerup', 'pointercancel', 'lostpointercapture']) button.addEventListener(event, () => { this[key] = false; button.classList.remove('held'); });
    this.buttons.set(key, button);
  }
  get steer() { return Math.max(-1, Math.min(1, this.touchSteer + (this.keys.has('ArrowRight') || this.keys.has('KeyD') ? 1 : 0) - (this.keys.has('ArrowLeft') || this.keys.has('KeyA') ? 1 : 0))); }
  get boosting() { return this.boost || this.keys.has('Space') || this.keys.has('ShiftLeft'); }
  get braking() { return this.brake || this.keys.has('ArrowDown') || this.keys.has('KeyS'); }
  reset() { this.keys.clear(); this.touchSteer = 0; this.boost = false; this.brake = false; for (const button of this.buttons.values()) button.classList.remove('held'); }
}
