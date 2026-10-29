/** Server-side adapters: no configuration, polling or delivery is activated automatically. */
export type SendResult='accepted'|'transient'|'expired';
export interface ServerDelivery {recipient:string;message:string}
export type HttpPost=(url:string,body:unknown)=>Promise<{status:number}>;
export function telegramTransport(token:string,post:HttpPost){if(!token)throw new Error('Telegram no configurado');return async (d:ServerDelivery):Promise<SendResult>=>{try{const r=await post(`https://api.telegram.org/bot${token}/sendMessage`,{chat_id:d.recipient,text:d.message});return r.status>=200&&r.status<300?'accepted':r.status===403||r.status===400?'expired':'transient';}catch{return 'transient'}};}
export interface PushSender {send(subscription:unknown,payload:string):Promise<{status:number}>}
export function webPushTransport(sender:PushSender){return async (subscription:unknown,message:string):Promise<SendResult>=>{try{const r=await sender.send(subscription,JSON.stringify({title:'LuzRadar',body:message}));return r.status>=200&&r.status<300?'accepted':r.status===404||r.status===410?'expired':'transient';}catch{return 'transient'}};}
