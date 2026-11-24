import test from 'node:test';
import assert from 'node:assert/strict';
import { RacePhysics } from '../src/physics.js';
test('cannon-es reports a traffic collision rather than visual-only contact',()=>{let hits=0;const p=new RacePhysics(()=>hits++);p.addTraffic(0,1.65,-4.5);for(let i=0;i<50;i++)p.step(1/60,0,1,()=>10);assert.ok(hits>0);});
test('steering stays inside road and reset restores spawn',()=>{const p=new RacePhysics(()=>{});for(let i=0;i<120;i++)p.step(1/60,1,1,()=>0);assert.ok(p.player.position.x<=5.7);p.reset();assert.equal(p.player.position.x,1.65);assert.equal(p.player.position.z,0);});
