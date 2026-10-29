import {createClient,type AuthChangeEvent,type Session,type SupabaseClient} from '@supabase/supabase-js';
export type FamilyMember={household_id:string;role:'owner'|'member';active:boolean};
export type SharedAppliance={id:string;name:string;duration_minutes:number;energy_kwh:number};
export type SharedPlan={id:string;created_by:string;snapshot:Record<string,unknown>;created_at:string};
export class FamilyRepository {
 readonly client:SupabaseClient;
 constructor(url:string,publishableKey:string){if(!url||!publishableKey)throw new Error('Supabase no configurado');this.client=createClient(url,publishableKey);}
 async signIn(email:string,password:string){return this.client.auth.signInWithPassword({email,password});}
 async signUp(email:string,password:string){return this.client.auth.signUp({email,password});}
 async signInGoogle(){return this.client.auth.signInWithOAuth({provider:'google',options:{redirectTo:window.location.href.split('#')[0]}});}
 async signOut(){return this.client.auth.signOut();}
 async requestPasswordReset(email:string){return this.client.auth.resetPasswordForEmail(email,{redirectTo:window.location.origin+window.location.pathname});}
 async updatePassword(password:string){return this.client.auth.updateUser({password});}
 async session(){return this.client.auth.getSession();}
 onSession(callback:(session:Session|null,event:AuthChangeEvent)=>void){return this.client.auth.onAuthStateChange((event,session)=>callback(session,event)).data.subscription;}
 async memberships(userId:string){return this.client.from('household_memberships').select('household_id,role,active').eq('user_id',userId).eq('active',true).returns<FamilyMember[]>();}
 async householdMembers(householdId:string){return this.client.from('household_memberships').select('user_id,role,active').eq('household_id',householdId).eq('active',true).returns<{user_id:string;role:string;active:boolean}[]>();}
 async revokeMember(householdId:string,userId:string){return this.client.rpc('revoke_household_member',{target:householdId,member_id:userId});}
 async createHousehold(name:string){return this.client.rpc('create_household',{household_name:name});}
 async invite(householdId:string){return this.client.rpc('create_invite_code',{target:householdId});}
 async accept(token:string){return this.client.rpc('accept_invite_code',{token});}
 async appliances(householdId:string){return this.client.from('appliances').select('id,name,duration_minutes,energy_kwh').eq('household_id',householdId).returns<SharedAppliance[]>();}
 async addAppliance(householdId:string,name:string,minutes:number,energy:number){return this.client.from('appliances').insert({household_id:householdId,name,duration_minutes:minutes,energy_kwh:energy});}
 async registerPush(householdId:string,subscription:PushSubscriptionJSON){return this.client.rpc('register_push_subscription',{target:householdId,subscription_data:subscription});}
 async removePush(endpoint:string){return this.client.rpc('remove_push_subscription',{endpoint_value:endpoint});}
 async issueTelegram(householdId:string){return this.client.rpc('issue_telegram_nonce',{target:householdId});}
 async unlinkTelegram(householdId:string){return this.client.rpc('unlink_telegram',{target:householdId});}
 async requestNotificationTest(householdId:string,channel:'push'|'telegram'){return this.client.rpc('request_notification_test',{target:householdId,channel_name:channel});}
 async preferences(householdId:string,userId:string){return this.client.from('notification_preferences').select('preferences').eq('household_id',householdId).eq('user_id',userId).maybeSingle();}
 async savePreferences(householdId:string,userId:string,preferences:Record<string,unknown>){return this.client.from('notification_preferences').upsert({household_id:householdId,user_id:userId,preferences},{onConflict:'household_id,user_id'});}
 async updateAppliance(id:string,minutes:number,energy:number){return this.client.from('appliances').update({duration_minutes:minutes,energy_kwh:energy}).eq('id',id);}
 async plans(householdId:string){return this.client.from('plans').select('id,created_by,snapshot,created_at').eq('household_id',householdId).order('created_at',{ascending:false}).returns<SharedPlan[]>();}
 async addPlan(householdId:string,_userId:string,snapshot:Record<string,unknown>){return this.client.rpc('create_official_plan',{target:householdId,appliance:snapshot.applianceId,start_at:snapshot.start,requested_id:snapshot.id});}
 async importRealPlan(householdId:string,applianceId:string,planId:string,plannedStart:string,actualStart:string|null){return this.client.rpc('import_official_plan',{target:householdId,appliance:applianceId,requested_id:planId,planned_start:plannedStart,actual_start:actualStart});}
 async updatePlan(id:string,snapshot:Record<string,unknown>){if(snapshot.status==='completed')return this.client.rpc('confirm_official_plan',{plan_uuid:id,actual_start:snapshot.actualStart});if(snapshot.status==='cancelled')return this.client.rpc('cancel_official_plan',{plan_uuid:id});throw new Error('Transición de plan no permitida');}
 subscribe(householdId:string,refresh:()=>void){return this.client.channel(`household:${householdId}`).on('postgres_changes',{event:'*',schema:'public',table:'appliances',filter:`household_id=eq.${householdId}`},refresh).on('postgres_changes',{event:'*',schema:'public',table:'plans',filter:`household_id=eq.${householdId}`},refresh).subscribe();}
 async unsubscribe(channel:ReturnType<SupabaseClient['channel']>){await this.client.removeChannel(channel);}
}
