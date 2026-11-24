// Software-rendered perspective fallback for WebViews without WebGL 2.
// Physics, progression and controls remain identical to the 3D mode.
export class CanvasScene {
  constructor(canvas){
    const replacement=canvas.cloneNode();canvas.replaceWith(replacement);this.canvas=replacement;this.ctx=replacement.getContext('2d');
    if(!this.ctx)throw new Error('Canvas rendering unavailable');
    this.player={position:{x:0},color:'#20f6dc'};this.traffic=[];this.offset=0;this.renderer={setPixelRatio:()=>{}};
    window.addEventListener('resize',()=>this.resize());this.resize();
  }
  resize(){this.canvas.width=innerWidth;this.canvas.height=innerHeight;}
  setCar(color){this.player.color=color;}
  addTraffic(color){const car={visible:true,color,x:0,z:0,position:{set(x,y,z){car.x=x;car.z=z;}}};this.traffic.push(car);return car;}
  project(x,z){const d=Math.max(3,12-z),s=this.h/d;return{x:this.w/2+(x-this.camX*.3)*s,y:this.h*.37+7*s,s};}
  car(color,x,y,scale,steer=0){
    const c=this.ctx,w=1.84*scale,h=3.25*scale;c.save();c.translate(x,y);c.rotate(steer*.04);
    c.fillStyle='#02040a';c.fillRect(-w*.57,-h*.28,w*1.14,h*.65);
    c.shadowColor=color;c.shadowBlur=12;c.fillStyle=color;c.beginPath();c.moveTo(-w*.45,-h);c.lineTo(w*.45,-h);c.lineTo(w*.55,0);c.lineTo(-w*.55,0);c.closePath();c.fill();c.shadowBlur=0;
    c.fillStyle='#101d36';c.fillRect(-w*.34,-h*.67,w*.68,h*.36);
    c.fillStyle='#c9ffff';c.fillRect(-w*.4,-h*.93,w*.25,h*.045);c.fillRect(w*.15,-h*.93,w*.25,h*.045);
    c.fillStyle='#ff225d';c.fillRect(-w*.43,-h*.09,w*.3,h*.04);c.fillRect(w*.13,-h*.09,w*.3,h*.04);c.restore();
  }
  update(dt,{speed=0,x=0,steer=0,boost=false,menu=false,time=0}){
    const c=this.ctx,w=this.canvas.width,h=this.canvas.height;this.w=w;this.h=h;this.camX=menu?-2:x;this.offset+=speed*dt;
    const sky=c.createLinearGradient(0,0,0,h*.65);sky.addColorStop(0,'#030817');sky.addColorStop(.7,'#171535');sky.addColorStop(1,'#1a1840');c.fillStyle=sky;c.fillRect(0,0,w,h);
    const sunX=w*.56,sunY=h*.27,r=h*.14;c.fillStyle='#6a246d';c.beginPath();c.arc(sunX,sunY,r,0,Math.PI*2);c.fill();c.fillStyle='#100f29';for(let i=0;i<6;i++)c.fillRect(sunX-r,sunY+i*r*.15,r*2,r*.035+i*.3);
    for(let i=0;i<55;i++){const bx=(i*91.73)%w,bh=25+(Math.sin(i*71)+1)*h*.105,bw=14+(i*13)%37;c.fillStyle=i%3?'#0b1327':'#0e1831';c.fillRect(bx,h*.45-bh,bw,bh);c.fillStyle=i%4?'#253755':'#217575';for(let j=0;j<4;j++)c.fillRect(bx+3+j*5,h*.45-bh+9,1,Math.max(3,bh*.55));}
    c.fillStyle='#080f20';c.fillRect(0,h*.45,w,h);const nearL=this.project(-7,3),nearR=this.project(7,3),farL=this.project(-7,-450),farR=this.project(7,-450);
    c.fillStyle='#182234';c.beginPath();c.moveTo(farL.x,farL.y);c.lineTo(farR.x,farR.y);c.lineTo(nearR.x,nearR.y);c.lineTo(nearL.x,nearL.y);c.fill();
    for(const side of [-7,7]){const a=this.project(side,-450),b=this.project(side,3);c.strokeStyle=side<0?'#16dacc':'#ee347b';c.lineWidth=3;c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke();}
    for(let z=-420;z<7;z+=16){const zz=z+(this.offset%16);for(const lane of [-3.5,0,3.5]){const a=this.project(lane,zz),b=this.project(lane,zz+5);c.strokeStyle='#65718a';c.lineWidth=Math.max(1,a.s*.07);c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke();}}
    for(const t of [...this.traffic].filter(t=>t.visible&&t.z<5).sort((a,b)=>a.z-b.z)){const p=this.project(t.x,t.z);this.car(t.color,p.x,p.y,p.s);}
    const p=this.project(menu?2.7:x,0);this.car(this.player.color,p.x,p.y,p.s,steer);
    if(boost){c.fillStyle='#c3afff';c.shadowColor='#6744ff';c.shadowBlur=25;c.fillRect(p.x-p.s*.5,p.y,p.s*.22,p.s*.9);c.fillRect(p.x+p.s*.28,p.y,p.s*.22,p.s*.9);c.shadowBlur=0;}
  }
}
