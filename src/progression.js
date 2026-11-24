export const CAR_SPECS = Object.freeze([
  { id: 'pulse', name: 'PULSE GT', cost: 0, maxSpeed: 53, accel: 16, handling: 1, color: '#20f6dc', description: 'Balanced street machine' },
  { id: 'vortex', name: 'VORTEX R', cost: 400, maxSpeed: 60, accel: 20, handling: 1.12, color: '#ff437e', description: 'Sharper, faster, fearless' },
  { id: 'spectre', name: 'SPECTRE X', cost: 1000, maxSpeed: 67, accel: 23, handling: 1.25, color: '#b6ff45', description: 'Built for the midnight run' },
]);
const integer = value => Number.isFinite(value) ? Math.max(0, Math.min(1e9, Math.floor(value))) : 0;
export function createProfile() { return { version: 1, coins: 0, bestDistance: 0, owned: ['pulse'], selected: 'pulse', totalRaces: 0 }; }
export function sanitizeProfile(value) {
  const p = value && typeof value === 'object' ? value : {};
  const owned = [...new Set(['pulse', ...(Array.isArray(p.owned) ? p.owned : []).filter(id => CAR_SPECS.some(c => c.id === id))])];
  return { version: 1, coins: integer(p.coins), bestDistance: integer(p.bestDistance), totalRaces: integer(p.totalRaces), owned, selected: owned.includes(p.selected) ? p.selected : 'pulse' };
}
export function loadProfile(storage) { try { return sanitizeProfile(JSON.parse(storage.getItem('maz-neon-rush-v1'))); } catch { return createProfile(); } }
export function saveProfile(storage, profile) { try { storage.setItem('maz-neon-rush-v1', JSON.stringify(sanitizeProfile(profile))); return true; } catch { return false; } }
export function raceReward({ distance = 0, nearMisses = 0, finished = false }) { return integer(Math.floor(integer(distance) / 25) + integer(nearMisses) * 5 + (finished ? 75 : 0)); }
export function purchaseCar(profile, id) {
  const p = sanitizeProfile(profile), car = CAR_SPECS.find(c => c.id === id);
  if (!car) return { profile: p, ok: false, reason: 'Unknown car' };
  if (p.owned.includes(id)) return { profile: p, ok: false, reason: 'Already owned' };
  if (p.coins < car.cost) return { profile: p, ok: false, reason: 'Not enough coins' };
  return { profile: { ...p, coins: p.coins - car.cost, owned: [...p.owned, id], selected: id }, ok: true };
}
export function selectCar(profile, id) {
  const p = sanitizeProfile(profile);
  return p.owned.includes(id) ? { profile: { ...p, selected: id }, ok: true } : { profile: p, ok: false, reason: 'Car locked' };
}
export function finishRace(profile, race) {
  const p = sanitizeProfile(profile), reward = raceReward(race);
  return { reward, profile: sanitizeProfile({ ...p, coins: p.coins + reward, bestDistance: Math.max(p.bestDistance, integer(race.distance)), totalRaces: p.totalRaces + 1 }) };
}
