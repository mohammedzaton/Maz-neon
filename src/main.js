import './style.css';
import { Capacitor } from '@capacitor/core';
import { App } from '@capacitor/app';
import { RaceScene } from './scene.js';
import { CanvasScene } from './canvas-scene.js';
import { Controls } from './controls.js';
import { RacePhysics } from './physics.js';
import { EngineAudio } from './audio.js';
import { RewardAds } from './ads.js';
import { CAR_SPECS, loadProfile, saveProfile, finishRace, selectCar, purchaseCar, sanitizeProfile } from './progression.js';
const $=id=>document.getElementById(id);
const show=(id,value)=>{$(id).hidden=!value;};
let toastTimer;
function toast(message){$('toast').textContent=message;$('toast').classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('show'),2400);}
function fatal(error){show('fatal',true);$('fatal-message').textContent='تعذّر تشغيل الرسوم ثلاثية الأبعاد. جرّب تحديث Android System WebView أو فتح اللعبة على جهاز يدعم WebGL 2.';console.error(error);}
try { boot(); } catch(error){fatal(error);}
function boot(){
  let profile;try{profile=loadProfile(localStorage);}catch{profile=sanitizeProfile(null);}
  let scene;
  try{scene=new RaceScene($('game'));}catch(error){console.warn('WebGL unavailable; using software perspective renderer.');scene=new CanvasScene($('game'));}
  const controls=new Controls(), audio=new EngineAudio(), ads=new RewardAds();
  let state='home', mode='sprint', spec=CAR_SPECS[0], run=null, nextCountdown=0, previous=performance.now(), time=0, seed=25, lastReward=0, doubled=false;
  const random=()=>{seed=(seed*16807)%2147483647;return(seed-1)/2147483646;};
  const physics=new RacePhysics(hit), traffic=[];
  const lanes=[-5.15,-1.72,1.72,5.15], colors=['#556ddc','#d24664','#e4c567','#737d98','#3f9ea8','#ece5d9'];
  for(let i=0;i<11;i++){
    const mesh=scene.addTraffic(colors[i%colors.length]);
    const body=physics.addTraffic(i,lanes[i%4],-55-i*38);
    traffic.push({mesh,body,passed:false,hit:false,speed:17+i%3*3});
  }
  function save(){let ok=false;try{ok=saveProfile(localStorage,profile);}catch{}if(!ok)toast('مساحة الحفظ غير متاحة؛ التقدم الحالي مؤقت.');updateProfile();}
  function updateProfile(){
    spec=CAR_SPECS.find(c=>c.id===profile.selected)||CAR_SPECS[0];scene.setCar(spec.color);
    $('coins').textContent=profile.coins.toLocaleString();$('best').textContent=(profile.bestDistance/1000).toFixed(2)+' KM';
    $('home-car').textContent=spec.name;$('home-top-speed').textContent=Math.round(spec.maxSpeed*3.6);renderGarage();
  }
  function renderGarage(){
    $('car-list').replaceChildren();
    for(const car of CAR_SPECS){
      const owned=profile.owned.includes(car.id), selected=profile.selected===car.id;
      const card=document.createElement('article');card.className='car-card'+(selected?' active':'');card.style.setProperty('--paint',car.color);
      // All interpolated values below are static application-owned catalog data.
      card.innerHTML=`<div class="swatch"></div><h3>${car.name}</h3><p>${car.description}</p><dl><div><dt>TOP SPEED</dt><dd>${Math.round(car.maxSpeed*3.6)}</dd></div><div><dt>HANDLING</dt><dd>${Math.round(car.handling*100)}%</dd></div></dl>`;
      const button=document.createElement('button');button.className=selected?'secondary':'primary';button.disabled=selected||(!owned&&profile.coins<car.cost);button.textContent=selected?'SELECTED':owned?'SELECT CAR':`◆ ${car.cost} · UNLOCK`;
      button.onclick=()=>{const result=owned?selectCar(profile,car.id):purchaseCar(profile,car.id);if(result.ok){profile=result.profile;save();toast(owned?'RIDE SELECTED':'NEW CAR UNLOCKED');}else toast(result.reason);};card.append(button);$('car-list').append(card);
    }
  }
  function resetTraffic(){
    seed=25+profile.totalRaces*79;
    traffic.forEach((t,i)=>{t.body.position.set(lanes[Math.floor(random()*4)],.8,-70-i*38);t.body.velocity.set(0,0,0);t.body.aabbNeedsUpdate=true;t.hit=false;t.passed=false;});
  }
  function start(){
    for(const id of ['home','results','pause-screen','garage','settings'])show(id,false);
    controls.reset();audio.unlock();updateProfile();physics.reset();resetTraffic();
    run={distance:0,speed:0,health:100,nitro:100,nearMisses:0,invulnerable:0,finished:false};
    nextCountdown=3.05;state='countdown';show('hud',true);show('countdown',true);document.body.classList.add('racing');
    $('mode-name').textContent=mode==='sprint'?'MIDNIGHT SPRINT · 3 KM':'ENDLESS HIGHWAY';updateHud();
  }
  function home(){
    state='home';controls.reset();show('home',true);show('hud',false);show('results',false);show('pause-screen',false);show('countdown',false);document.body.classList.remove('racing','boosting');
    updateProfile();traffic.forEach(t=>t.mesh.visible=false);
  }
  function pause(){if(state!=='racing')return;state='paused';controls.reset();show('pause-screen',true);document.body.classList.remove('boosting');}
  function resume(){if(state!=='paused')return;state='racing';controls.reset();show('pause-screen',false);audio.unlock();previous=performance.now();}
  function finish(completed=false){
    if(!run||!['racing','paused'].includes(state))return;
    state='result';run.finished=completed;controls.reset();show('hud',false);show('pause-screen',false);show('results',true);document.body.classList.remove('boosting');
    const record=run.distance>profile.bestDistance;const result=finishRace(profile,run);profile=result.profile;lastReward=result.reward;doubled=false;save();
    $('result-title').innerHTML=completed?'SPRINT CLEARED<span>.</span>':'NICE RUN<span>.</span>';
    $('result-eyebrow').textContent=completed?'YOU OWNED THE MIDNIGHT':'EVERY RUN MAKES YOU FASTER';
    $('result-distance').textContent=(run.distance/1000).toFixed(2)+' KM';$('result-near').textContent=run.nearMisses;$('result-coins').textContent='+'+lastReward;show('record-note',record);
    show('reward-ad',ads.enabled&&lastReward>0);$('reward-ad').disabled=false;
  }
  function hit(index){
    if(state!=='racing'||!run||run.invulnerable>0||traffic[index].hit)return;
    const t=traffic[index];t.hit=true;run.health=Math.max(0,run.health-34);run.speed*=.57;run.invulnerable=1.15;audio.crash();
    $('hit-flash').classList.add('show');setTimeout(()=>$('hit-flash').classList.remove('show'),180);toast('CONTACT · −34 INTEGRITY');
    if(run.health<=0)finish(false);
  }
  function updateHud(){
    $('speed').textContent=String(Math.round(run.speed*3.6)).padStart(3,'0');$('distance').innerHTML=(run.distance/1000).toFixed(2)+' <span>KM</span>';
    $('near').textContent=run.nearMisses;$('health').style.width=run.health+'%';$('health').style.background=run.health<40?'#fe3f83':'#20f6dc';
    $('nitro').style.width=run.nitro+'%';$('nitro-percent').textContent=Math.floor(run.nitro)+'%';$('progress').style.width=(mode==='sprint'?Math.min(100,run.distance/30):Math.min(100,run.distance/100))+'%';
  }
  $('start').onclick=start;$('retry').onclick=start;$('result-home').onclick=home;$('pause').onclick=pause;$('resume').onclick=resume;$('quit').onclick=()=>finish(false);
  document.querySelector('.brand').onclick=e=>{e.preventDefault();home();};
  $('garage-open').onclick=()=>{renderGarage();show('garage',true);};$('garage-close').onclick=()=>show('garage',false);
  $('settings-open').onclick=()=>show('settings',true);$('settings-close').onclick=()=>show('settings',false);
  $('sound').onclick=()=>{$('sound').textContent=audio.toggle()?'SOUND ON':'SOUND OFF';};
  $('quality').onchange=()=>{scene.renderer.setPixelRatio($('quality').value==='low'?1:$('quality').value==='high'?Math.min(devicePixelRatio,2):Math.min(devicePixelRatio,1.65));scene.resize();};
  $('ad-privacy').onclick=()=>ads.privacy().catch(e=>toast(e.message));
  $('reward-ad').onclick=async()=>{
    if(doubled||ads.busy)return;$('reward-ad').disabled=true;
    try{await ads.reward(()=>{if(doubled)return;doubled=true;profile=sanitizeProfile({...profile,coins:profile.coins+lastReward});save();$('result-coins').textContent='+'+lastReward*2;toast('REWARD EARNED');});}
    catch{toast('الإعلان غير متاح الآن. عملات السباق محفوظة.');}
    finally{$('reward-ad').disabled=doubled;}
  };
  document.querySelectorAll('[data-mode]').forEach(button=>button.onclick=()=>{mode=button.dataset.mode;document.querySelectorAll('[data-mode]').forEach(b=>b.classList.toggle('selected',b===button));});
  window.addEventListener('keydown',e=>{if(e.code==='Escape'){if(state==='racing')pause();else if(state==='paused')resume();}});
  document.addEventListener('visibilitychange',()=>{if(document.hidden){pause();if(state==='countdown'){state='countdown-paused';show('countdown',false);}controls.reset();audio.update(0,false,false);}else if(state==='countdown-paused'){state='countdown';show('countdown',true);previous=performance.now();}});
  if(Capacitor.isNativePlatform()){
    App.addListener('appStateChange',({isActive})=>{if(!isActive){pause();controls.reset();audio.update(0,false,false);}});
    App.addListener('backButton',()=>{if(state==='racing')pause();else if(state==='paused')resume();else if(['result','countdown'].includes(state))home();else{show('garage',false);show('settings',false);}});
  }
  function frame(now){
    const dt=Math.min((now-previous)/1000,.05);previous=now;time+=dt;
    let boost=false;let displaySpeed=state==='home'?9:0;
    if(state==='countdown'){
      nextCountdown-=dt;$('countdown').textContent=Math.ceil(Math.max(nextCountdown,0))||'GO';
      if(nextCountdown<=0){state='racing';show('countdown',false);}
    }
    if(state==='racing'){
      boost=controls.boosting&&run.nitro>1&&!controls.braking;
      const target=controls.braking?17:spec.maxSpeed+(boost?19:0);
      run.speed+=(target-run.speed)*Math.min(1,dt*(controls.braking?2.5:spec.accel/28));
      run.nitro=Math.max(0,Math.min(100,run.nitro+(boost?-29:12)*dt));run.distance+=run.speed*dt;run.invulnerable=Math.max(0,run.invulnerable-dt);
      physics.step(dt,controls.steer,spec.handling,i=>Math.max(5,run.speed-traffic[i].speed));
      for(const t of traffic){
        if(!t.passed&&t.body.position.z>3.5){t.passed=true;const gap=Math.abs(t.body.position.x-physics.player.position.x);if(!t.hit&&gap>1.65&&gap<3.15){run.nearMisses++;run.nitro=Math.min(100,run.nitro+7);toast('NEAR MISS · +5 COINS');}}
        if(t.body.position.z>36){t.body.position.z=-390-random()*55;t.body.position.x=lanes[Math.floor(random()*4)];t.body.aabbNeedsUpdate=true;t.passed=false;t.hit=false;}
      }
      updateHud();displaySpeed=run.speed;if(mode==='sprint'&&run.distance>=3000)finish(true);
    }
    for(const t of traffic){t.mesh.visible=state!=='home';t.mesh.position.set(t.body.position.x,0,t.body.position.z);}
    const moving=state==='racing';document.body.classList.toggle('boosting',moving&&boost);
    audio.update(run?.speed||0,moving,boost);
    scene.update(dt,{speed:displaySpeed,x:physics.player.position.x,steer:moving?controls.steer:0,boost:moving&&boost,active:moving,menu:state==='home',time,shake:moving&&run.invulnerable>.8?.2:0});
    requestAnimationFrame(frame);
  }
  home();requestAnimationFrame(frame);
  if(import.meta.env.DEV)window.__MAZ_DEBUG__={get state(){return state;},get run(){return run;},get profile(){return profile;},get physics(){return physics;}};
}
