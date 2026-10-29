self.addEventListener('push', event => {
  let data={title:'LuzRadar',body:'Tienes una actualización.'};
  try { if(event.data) data={...data,...event.data.json()}; } catch { data={title:'LuzRadar',body:'Tienes una actualización.'}; }
  event.waitUntil(self.registration.showNotification(data.title,{body:data.body,icon:'./icon-192.png',data:{url:'./'}}));
});
self.addEventListener('notificationclick',event=>{event.notification.close();event.waitUntil(clients.openWindow(new URL('./',self.registration.scope).href));});
