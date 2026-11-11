const { TikTokLiveConnection } = require('tiktok-live-connector');
const WebSocket = require('ws');
const tiktok = new TikTokLiveConnection('aktarul3243200727', {});
const wss = new WebSocket.Server({ port: 8081 });
let clients = [];
wss.on('connection', (ws) => { clients.push(ws); });
function send(o){ clients.forEach(ws=>{ if(ws.readyState===1) ws.send(JSON.stringify(o)); }); }
tiktok.connect().then(s=>console.log('Connected:',s)).catch(e=>console.log('LIVE chalu ache?',e));
tiktok.on('chat', d=>{ if(d.comment.trim().toLowerCase()==='me') send({type:'viewer_action',action:'me',name:d.nickname,photo:d.profilePictureUrl,isVIP:false}); });
tiktok.on('follow', d=>send({type:'viewer_action',action:'follow',name:d.nickname,photo:d.profilePictureUrl,isVIP:false}));
tiktok.on('share', d=>send({type:'viewer_action',action:'share',name:d.nickname,photo:d.profilePictureUrl,isVIP:false}));
tiktok.on('gift', d=>{ if(d.giftType===1 && !d.repeatEnd) return; send({type:'viewer_action',action:'gift',name:d.nickname,photo:d.profilePictureUrl,isVIP:true,giftName:d.giftName}); });
tiktok.on('like', d=>{});
console.log('Bridge ready on 8081');
