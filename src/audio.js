export class EngineAudio {
  constructor() { this.enabled = true; this.ctx = null; }
  async unlock() {
    if (!this.enabled) return;
    try {
      if (!this.ctx) {
        this.ctx = new (window.AudioContext || window.webkitAudioContext)();
        this.osc = this.ctx.createOscillator(); this.osc.type = 'sawtooth';
        this.filter = this.ctx.createBiquadFilter(); this.filter.type = 'lowpass'; this.filter.frequency.value = 240;
        this.gain = this.ctx.createGain(); this.gain.gain.value = 0;
        this.osc.connect(this.filter).connect(this.gain).connect(this.ctx.destination); this.osc.start();
      }
      await this.ctx.resume();
    } catch { this.enabled = false; }
  }
  update(speed, active, boost) {
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    this.osc.frequency.setTargetAtTime(35 + speed * 1.9 + (boost ? 18 : 0), now, .08);
    this.gain.gain.setTargetAtTime(this.enabled && active ? .018 : 0, now, .1);
  }
  toggle() { this.enabled = !this.enabled; if (this.enabled) this.unlock(); else this.update(0, false, false); return this.enabled; }
  crash() {
    if (!this.ctx || !this.enabled) return;
    const o = this.ctx.createOscillator(), g = this.ctx.createGain(), now = this.ctx.currentTime;
    o.type = 'square'; o.frequency.setValueAtTime(80, now); o.frequency.exponentialRampToValueAtTime(20, now + .15);
    g.gain.setValueAtTime(.04, now); g.gain.exponentialRampToValueAtTime(.001, now + .2);
    o.connect(g).connect(this.ctx.destination); o.start(); o.stop(now + .22);
  }
}
