const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const html = fs.readFileSync(__dirname + '/浏览器原型.html', 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, '找不到游戏脚本');
for(const [,id] of script.matchAll(/\$\('([^']+)'\)/g))
  assert.ok(html.includes(`id="${id}"`),`页面缺少元素 ${id}`);

function boot(saved) {
  const elements = new Map();
  const get = id => {
    if (!elements.has(id)) elements.set(id, {
      innerHTML:'',textContent:'',style:{},classList:{add(){},remove(){},toggle(){}},
      addEventListener(type,fn){this[type]=fn;}
    });
    return elements.get(id);
  };
  const tabs = ['spread','culture','adapt'].map(tab=>({dataset:{tab},classList:{toggle(){}},addEventListener(type,fn){this[type]=fn;}}));
  const storage = new Map(saved ? [['niuma-cartoon-v2',JSON.stringify(saved)]] : []);
  let pulse;
  vm.runInNewContext(script,{
    document:{getElementById:get,querySelectorAll:()=>tabs,addEventListener(){},hidden:false},
    localStorage:{getItem:key=>storage.get(key)||null,setItem:(key,value)=>storage.set(key,value)},
    setInterval:fn=>{pulse=fn;},confirm:()=>true,Date,Math,console
  });
  const state=()=>storage.has('niuma-cartoon-v2')?JSON.parse(storage.get('niuma-cartoon-v2')):null;
  const start=id=>get('startOverlay').click({target:{closest:()=>({dataset:{start:id}})}});
  const select=id=>get('nodes').click({target:{closest:()=>({dataset:{region:id}})}});
  const bubble=()=>get('bubbleHost').click({target:{closest:()=>({id:'bubbleBtn'})}});
  const buy=id=>get('upgradeGrid').click({target:{closest:()=>({dataset:{buy:id}})}});
  const choose=index=>get('eventChoices').click({target:{closest:()=>({dataset:{choice:String(index)}})}});
  return {get,tabs,state,pulse,start,select,bubble,buy,choose};
}

const game=boot();
game.start('eastAsia');
assert.equal(game.state().area.eastAsia.count,1,'应从玩家选择的地区起步');
game.select('westNA');
assert.equal(game.get('regionBox').innerHTML.includes('北美西岸'),true,'地图点击应显示地区信息');
game.get('evolveBtn').click();
game.buy('referral');
assert.equal(game.state().upgrades.referral,true,'应能消费招聘点升级');
game.get('closeUpgrade').click();
for(let i=0;i<600;i++){game.pulse();if(game.state()?.eventOpen)game.choose(0);}
assert.ok(Object.values(game.state().area).some((a,i)=>i!==9&&a.count>0),'招聘应自动传播到其他地区');

const nearWin=game.state();
const pops={westNA:90,eastNA:105,latam:105,westEU:100,eastEU:85,northAF:80,africa:95,northAsia:75,southAsia:140,eastAsia:150,southeastAsia:110,oceania:75};
for(const [id,pop] of Object.entries(pops))nearWin.area[id].count=pop-.1;
nearWin.outcome=null;nearWin.eventOpen=false;nearWin.resistance=10;nearWin.started=true;nearWin.paused=false;
const winner=boot(nearWin);winner.pulse();
assert.equal(winner.state().outcome?.win,true,'全球人人入职应触发胜利');
winner.get('againBtn').click();
assert.equal(winner.state().started,false,'结算后应能重新开局');

const nearFail=game.state();nearFail.resistance=100;nearFail.outcome=null;nearFail.eventOpen=false;nearFail.paused=false;
const loser=boot(nearFail);loser.pulse();
assert.equal(loser.state().outcome?.win,false,'全球反制满值应触发失败');

const run=boot();run.start('eastAsia');
const route=[['spread','referral'],['spread','headhunt'],['spread','remote'],['culture','coffee'],['culture','flex'],['adapt','local'],['adapt','legal'],['adapt','roundtable'],['spread','campus'],['culture','shares'],['adapt','globalHR']];
for(let i=0;i<2400;i++){
  run.pulse();let s=run.state();
  if(s.outcome)break;
  if(s.eventOpen){run.choose(s.resistance>45?0:1);s=run.state();}
  if(s.bubble){run.bubble();s=run.state();}
  if(i%10!==0)continue;
  const next=route.find(([,id])=>!s.upgrades[id]);
  if(next){const [tab,id]=next;run.get('evolveBtn').click();run.tabs.find(x=>x.dataset.tab===tab).click();run.buy(id);run.get('closeUpgrade').click();}
}
const result=run.state();
assert.equal(result.outcome?.win,true,'合理升级路线应完成一局');
assert.ok(result.day>=1200&&result.day<=1500,'自动策略完成时间应约为 20–25 分钟');
const reckless=boot();reckless.start('eastAsia');
const rushRoute=[['culture','coffee'],['culture','slogan'],['spread','referral'],['spread','headhunt'],['spread','remote'],['spread','campus']];
for(let i=0;i<1800;i++){
  reckless.pulse();let s=reckless.state();
  if(s.outcome)break;
  if(s.eventOpen){reckless.choose(1);s=reckless.state();}
  if(s.bubble){reckless.bubble();s=reckless.state();}
  if(i%10!==0)continue;
  const next=rushRoute.find(([,id])=>!s.upgrades[id]);
  if(next){reckless.get('evolveBtn').click();reckless.tabs.find(x=>x.dataset.tab===next[0]).click();reckless.buy(next[1]);reckless.get('closeUpgrade').click();}
}
assert.equal(reckless.state().outcome?.win,false,'一味高压扩张应能触发世界反制失败');
console.log('机制检查通过：起点、地图输入、自动传播、升级、胜负结算、重开。');
console.log(`自动策略演练：第 ${result.day} 天，${result.outcome?.win?'胜利':result.outcome?'失败':'未结束'}；覆盖 ${Object.values(result.area).filter(a=>a.count>0).length}/12 地区，反制 ${Math.round(result.resistance)}%。`);
console.log(`高压扩张演练：第 ${reckless.state().day} 天，反制 ${Math.round(reckless.state().resistance)}%，失败。`);
